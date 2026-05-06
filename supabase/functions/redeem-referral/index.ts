// [EDGE-FN] redeem-referral — validates and redeems a referral code, awarding coins to both parties

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { code?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { code } = body;
  if (!code || typeof code !== "string") {
    return json({ error: "code is required" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // 1. Validate JWT, get caller user_id
  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const callerId = user.id;

  // 2. Look up profiles WHERE referral_code = code
  const { data: referrerProfile } = await supabase
    .from("profiles")
    .select("id")
    .eq("referral_code", code.trim().toUpperCase())
    .maybeSingle();

  if (!referrerProfile) return json({ error: "CODE_NOT_FOUND" }, 404);

  const referrerId = referrerProfile.id;

  // 3. Self-referral check
  if (referrerId === callerId) return json({ error: "SELF_REFERRAL" }, 400);

  // 4. Check if caller already redeemed a referral code
  const { data: existingReferral } = await supabase
    .from("referrals")
    .select("id")
    .eq("referee_id", callerId)
    .maybeSingle();

  if (existingReferral) return json({ error: "ALREADY_REDEEMED" }, 409);

  // 5. INSERT into referrals
  const { error: insertErr } = await supabase.from("referrals").insert({
    referrer_id: referrerId,
    referee_id: callerId,
    rewarded_at: new Date().toISOString(),
  });

  if (insertErr) {
    // Handle race condition — unique constraint on referee_id
    if (insertErr.code === "23505") return json({ error: "ALREADY_REDEEMED" }, 409);
    return json({ error: "Failed to record referral" }, 500);
  }

  // 6 & 7. Award 100 coins to referrer and referee — rollback referral row on partial failure
  try {
    // Award 100 coins to referrer
    const { error: rpcErr1 } = await supabase.rpc("increment_currency", {
      uid: referrerId,
      d_coins: 100,
      d_gems: 0,
    });
    if (rpcErr1) throw rpcErr1;

    // Award 100 coins to referee (caller)
    const { error: rpcErr2 } = await supabase.rpc("increment_currency", {
      uid: callerId,
      d_coins: 100,
      d_gems: 0,
    });
    if (rpcErr2) throw rpcErr2;
  } catch (creditErr) {
    console.error("Failed to credit referral rewards:", creditErr);
    // Rollback — delete the referral row so a retry is possible
    await supabase.from("referrals").delete().eq("referee_id", callerId).eq("referrer_id", referrerId);
    return json({ error: "Reward grant failed, please retry" }, 500);
  }

  // 8. Return success
  return json({ rewarded: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
