// [EDGE-FN] send-push-notification — sends FCM push to all tokens for a user (service_role only)
// Env vars required: FCM_PROJECT_ID, FCM_SERVICE_ACCOUNT_JSON

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

function pemToUint8Array(pem: string): Uint8Array {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----\n?/, "")
    .replace(/\n?-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function base64url(data: string | ArrayBuffer): string {
  const bytes = typeof data === "string" ? new TextEncoder().encode(data) : new Uint8Array(data);
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  }));
  const signingInput = `${header}.${payload}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToUint8Array(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signingInput),
  );
  const assertion = `${signingInput}.${base64url(sig)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const data = await res.json();
  return data.access_token as string;
}

async function sendFcmMessage(
  token: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
  accessToken: string,
  projectId: string,
): Promise<{ success: boolean; stale: boolean; fcmError?: string }> {
  // FCM HTTP v1 requires all data values to be strings
  const safeData = Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, String(v)]),
  );
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: { token, notification: { title, body }, data: safeData },
      }),
    },
  );
  if (res.ok) return { success: true, stale: false };
  const err = await res.json();
  const stale = err?.error?.details?.some(
    (d: { errorCode?: string }) => d.errorCode === "UNREGISTERED",
  ) ?? false;
  return { success: false, stale, fcmError: err?.error?.message };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // Service-role-only — reject user JWTs
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (authHeader !== `Bearer ${serviceRoleKey}`) return json({ error: "Forbidden" }, 403);

  const body = await req.json().catch(() => null);
  const { user_id, title, body: msgBody, data = {}, notification_type } = body ?? {};
  if (!user_id || !title || !msgBody) {
    return json({ error: "user_id, title, body are required" }, 400);
  }

  const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  if (!saJson || !projectId) return json({ error: "FCM not configured" }, 500);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );

  // Check notification preference opt-out before any FCM work
  if (notification_type) {
    const { data: profile } = await supabase
      .from("profiles")
      .select("notification_prefs")
      .eq("id", user_id)
      .maybeSingle();

    if (profile?.notification_prefs?.[notification_type] === false) {
      return json({ sent: 0, reason: "opted_out" });
    }
  }

  const sa: ServiceAccount = JSON.parse(saJson);
  const accessToken = await getAccessToken(sa);

  const { data: tokens, error } = await supabase
    .from("push_tokens")
    .select("id, token")
    .eq("user_id", user_id);

  if (error) return json({ error: error.message }, 500);
  if (!tokens?.length) return json({ sent: 0 });

  const staleIds: string[] = [];
  const fcmErrors: string[] = [];
  let sent = 0;

  await Promise.all(
    tokens.map(async (row: { id: string; token: string }) => {
      const result = await sendFcmMessage(row.token, title, msgBody, data, accessToken, projectId);
      if (result.success) {
        sent++;
      } else if (result.stale) {
        staleIds.push(row.id);
      } else if (result.fcmError) {
        fcmErrors.push(result.fcmError);
      }
    }),
  );

  // Remove stale tokens
  if (staleIds.length) {
    await supabase.from("push_tokens").delete().in("id", staleIds);
  }

  return json({ sent, ...(fcmErrors.length ? { errors: fcmErrors } : {}) });
});
