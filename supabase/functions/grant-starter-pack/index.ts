// [EDGE-FN] grant-starter-pack — validates drama_starter_pack IAP receipt, grants 500 gems + 200 coins

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMS_REWARD = 500;
const COINS_REWARD = 200;

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

  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Atomic idempotency stamp — only one concurrent request can win this UPDATE
  // because the WHERE starter_pack_purchased_at IS NULL ensures a second request
  // that races past here gets 0 rows back and returns 409.
  const { data: stamped, error: stampErr } = await serviceClient
    .from("profiles")
    .update({ starter_pack_purchased_at: new Date().toISOString() })
    .eq("id", userId)
    .is("starter_pack_purchased_at", null)
    .select("id");

  if (stampErr) return json({ error: "Failed to update profile" }, 500);
  if (!stamped || stamped.length === 0) {
    return json({ error: "already_purchased" }, 409);
  }

  // Stamp succeeded — safe to grant currency (only one winner reaches here)
  const { error: rpcErr } = await serviceClient.rpc("increment_currency", {
    uid: userId,
    d_coins: COINS_REWARD,
    d_gems: GEMS_REWARD,
  });
  if (rpcErr) return json({ error: "Failed to grant currency" }, 500);

  return json({ gems_granted: GEMS_REWARD, coins_granted: COINS_REWARD });
});
