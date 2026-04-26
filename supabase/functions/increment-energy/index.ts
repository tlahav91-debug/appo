// [EDGE-FN] increment-energy — credits energy from a rewarded ad grant (max +5, capped at 10)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_ENERGY = 10;
const MAX_AD_GRANT = 5;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { amount?: number };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const rawAmount = body.amount;
  if (
    typeof rawAmount !== "number" ||
    !Number.isInteger(rawAmount) ||
    rawAmount <= 0
  ) {
    return json({ error: "amount must be a positive integer" }, 400);
  }

  // Cap the ad grant at MAX_AD_GRANT (5) so callers cannot abuse this endpoint
  const amount = Math.min(rawAmount, MAX_AD_GRANT);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // Read current energy from profiles
  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select("current_energy")
    .eq("id", userId)
    .single();

  if (profileErr || !profile) return json({ error: "Profile not found" }, 404);

  const currentEnergy: number = profile.current_energy ?? 0;
  const newEnergy = Math.min(currentEnergy + amount, MAX_ENERGY);

  const { error: updateErr } = await supabase
    .from("profiles")
    .update({
      current_energy: newEnergy,
      last_refill_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (updateErr) return json({ error: updateErr.message }, 500);

  return json({ new_energy: newEnergy }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
