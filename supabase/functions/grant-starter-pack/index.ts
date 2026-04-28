// [EDGE-FN] grant-starter-pack — validates drama_starter_pack IAP receipt, grants 500 gems + 1000 coins

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GEMS_REWARD = 500;
const COINS_REWARD = 1000;

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

  // Idempotency: already purchased returns 409
  const { data: profile, error: profileErr } = await serviceClient
    .from("profiles")
    .select("starter_pack_purchased_at")
    .eq("id", userId)
    .single();

  if (profileErr || !profile) return json({ error: "Profile not found" }, 404);
  if (profile.starter_pack_purchased_at !== null) {
    return json({ error: "already_purchased" }, 409);
  }

  // Grant gems + coins in one RPC call
  const { error: rpcErr } = await serviceClient.rpc("increment_currency", {
    uid: userId,
    d_coins: COINS_REWARD,
    d_gems: GEMS_REWARD,
  });
  if (rpcErr) return json({ error: "Failed to grant currency" }, 500);

  // Stamp starter_pack_purchased_at
  const { error: updateErr } = await serviceClient
    .from("profiles")
    .update({ starter_pack_purchased_at: new Date().toISOString() })
    .eq("id", userId);

  if (updateErr) return json({ error: "Failed to update profile" }, 500);

  return json({ gems_granted: GEMS_REWARD, coins_granted: COINS_REWARD });
});
