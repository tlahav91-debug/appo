// [EDGE-FN] ad-reward — delegates to atomic Postgres RPC to prevent race conditions

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { reward_type?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { reward_type } = body;
  if (reward_type !== "energy" && reward_type !== "coins") {
    return json({ error: "reward_type must be 'energy' or 'coins'" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Delegate to atomic Postgres function — FOR UPDATE lock prevents cap bypass
  const { data: result, error: rpcErr } = await supabase.rpc("claim_ad_reward", {
    p_user_id: user.id,
    p_reward_type: reward_type,
  });

  if (rpcErr) return json({ error: rpcErr.message }, 500);

  if (result?.error === "AD_CAP_REACHED") {
    return json({ code: "AD_CAP_REACHED", views_today: result.views_today }, 403);
  }
  if (result?.error === "PROFILE_NOT_FOUND") {
    return json({ error: "Profile not found" }, 404);
  }

  return json(result, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
