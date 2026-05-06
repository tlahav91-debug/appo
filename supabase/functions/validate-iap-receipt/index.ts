// [EDGE-FN] validate-iap-receipt — validates IAP receipts and credits gems to the user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PRODUCT_GEM_MAP: Record<string, number> = {
  drama_gems_100:  100,
  drama_gems_500:  500,
  drama_gems_1500: 1500,
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // Verify JWT
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: {
    platform?: string;
    product_id?: string;
    receipt_data?: string;
    transaction_id?: string;
  };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { platform, product_id, receipt_data, transaction_id } = body;

  if (!platform || !product_id || !receipt_data || !transaction_id) {
    return json({ error: "platform, product_id, receipt_data, and transaction_id are required" }, 400);
  }

  if (platform !== "ios" && platform !== "android") {
    return json({ error: "platform must be 'ios' or 'android'" }, 400);
  }

  // Map product_id to gem amount
  const gemsAmount = PRODUCT_GEM_MAP[product_id];
  if (gemsAmount === undefined) {
    return json({ error: `Unknown product_id: ${product_id}` }, 400);
  }

  // Service role client (bypasses RLS)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Verify JWT and extract user_id
  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Check for existing transaction_id (idempotency)
  const { data: existing } = await supabase
    .from("iap_receipts")
    .select("gems_credited")
    .eq("transaction_id", transaction_id)
    .maybeSingle();

  if (existing) {
    return json({ gems_credited: existing.gems_credited, already_processed: true }, 200);
  }

  // Platform-specific receipt validation
  if (platform === "ios") {
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
          "password": Deno.env.get("APPLE_SHARED_SECRET"),
        }),
      });
    } catch (err) {
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
    // Android validation not yet implemented
    return json({ error: "Android receipt validation not yet implemented" }, 501);
  }

  // Insert receipt record
  const { error: insertErr } = await supabase
    .from("iap_receipts")
    .insert({
      user_id: userId,
      transaction_id,
      product_id,
      gems_credited: gemsAmount,
      platform,
    });

  if (insertErr) {
    // Could be a race condition — check if already processed
    if (insertErr.code === "23505") {
      const { data: raceExisting } = await supabase
        .from("iap_receipts")
        .select("gems_credited")
        .eq("transaction_id", transaction_id)
        .maybeSingle();
      return json({
        gems_credited: raceExisting?.gems_credited ?? gemsAmount,
        already_processed: true,
      }, 200);
    }
    return json({ error: "Failed to record receipt" }, 500);
  }

  // Credit gems via increment_currency RPC
  const { error: rpcErr } = await supabase.rpc("increment_currency", {
    uid: userId,
    d_coins: 0,
    d_gems: gemsAmount,
  });

  if (rpcErr) {
    return json({ error: "Failed to credit gems" }, 500);
  }

  return json({ gems_credited: gemsAmount });
});
