// [EDGE-FN] claim-pass-bonus — grants +5 energy once per day to Drama Pass holders

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const { data, error } = await supabase.rpc("claim_pass_bonus", {
    p_user_id: user.id,
  });

  if (error) return json({ error: error.message }, 500);

  // RPC returns empty array if already claimed today or pass inactive
  if (!data || data.length === 0) {
    return json({ claimed: false }, 200);
  }

  return json({
    claimed: true,
    new_energy: data[0].new_energy,
  }, 200);
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
