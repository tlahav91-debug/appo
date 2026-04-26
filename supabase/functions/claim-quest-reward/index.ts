// [EDGE-FN] claim-quest-reward — atomic quest reward via Postgres RPC (idempotent)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { quest_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { quest_id } = body;
  if (!quest_id || !UUID_RE.test(quest_id)) {
    return json({ error: "quest_id must be a valid UUID" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const { data, error } = await supabase.rpc("claim_quest_reward", {
    p_user_id: user.id,
    p_quest_id: quest_id,
  });

  if (error) return json({ error: "Internal error" }, 500);

  const result = data as {
    error?: string;
    code?: number;
    idempotent?: boolean;
    gems_earned?: number;
    coins_earned?: number;
    xp_gained?: number;
    leveled_up?: boolean;
    new_fan_level?: number;
  };

  if (result.error) {
    return json({ error: result.error }, result.code ?? 400);
  }

  return json({
    gems_earned:   result.gems_earned,
    coins_earned:  result.coins_earned,
    xp_gained:     result.xp_gained ?? 0,
    leveled_up:    result.leveled_up ?? false,
    new_fan_level: result.new_fan_level ?? null,
    ...(result.idempotent ? { idempotent: true } : {}),
  });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
