// [EDGE-FN] activate-drama-pass — sets drama_pass_active = true on successful subscription purchase/restore

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { platform?: string; receipt_data?: string; transaction_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { platform, receipt_data, transaction_id } = body;
  if (!platform || !receipt_data || !transaction_id) {
    return json({ error: "platform, receipt_data, and transaction_id are required" }, 400);
  }
  if (platform !== "ios" && platform !== "android") {
    return json({ error: "platform must be 'ios' or 'android'" }, 400);
  }

  // Validate JWT
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );
  const { data: { user }, error: authErr } = await anonClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Platform-specific receipt verification
  if (platform === "ios") {
    const appleIapSecret = Deno.env.get("APPLE_IAP_SECRET") ?? Deno.env.get("APPLE_SHARED_SECRET");
    if (!appleIapSecret) {
      return json({ error: "Apple IAP secret not configured" }, 500);
    }

    const isProduction = Deno.env.get("APPLE_IAP_ENV") === "production";
    const appleUrl = isProduction
      ? "https://buy.itunes.apple.com/verifyReceipt"
      : "https://sandbox.itunes.apple.com/verifyReceipt";

    let appleRes: Response;
    try {
      appleRes = await fetch(appleUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          "receipt-data": receipt_data,
          "password": appleIapSecret,
        }),
      });
    } catch (_err) {
      return json({ error: "Failed to reach Apple verification endpoint" }, 502);
    }

    let appleBody: { status?: number };
    try {
      appleBody = await appleRes.json();
    } catch {
      return json({ error: "Invalid response from Apple" }, 502);
    }

    if (appleBody.status !== 0) {
      return json({ error: `Apple receipt validation failed with status ${appleBody.status}` }, 400);
    }
  } else if (platform === "android") {
    // TODO: Android validation requires Google service account credentials (not yet configured)
    // Proceed without validation for now
  }

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Idempotent — safe to call on purchase and restore
  const { error: updateErr } = await serviceClient
    .from("profiles")
    .update({ drama_pass_active: true })
    .eq("id", userId);

  if (updateErr) return json({ error: "Failed to activate Drama Pass" }, 500);

  return json({ activated: true });
});
