import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  if (req.headers.get("Authorization") !== `Bearer ${serviceRoleKey}`) {
    return json({ error: "Forbidden" }, 403);
  }

  const body = await req.json().catch(() => null);
  const { user_id, all_users, title, body: msgBody, type = "announcement", reward_coins = 0, reward_gems = 0, expires_in_days } = body ?? {};

  if (!title) return json({ error: "title is required" }, 400);
  if (!user_id && !all_users) return json({ error: "user_id or all_users required" }, 400);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceRoleKey);
  const expiresAt = expires_in_days
    ? new Date(Date.now() + expires_in_days * 86400000).toISOString()
    : null;

  let userIds: string[] = [];
  if (all_users) {
    const { data: users } = await admin.from("profiles").select("id");
    userIds = (users ?? []).map((u: { id: string }) => u.id);
  } else {
    userIds = [user_id];
  }

  const rows = userIds.map((uid) => ({
    user_id: uid, type, title, body: msgBody ?? null,
    reward_coins, reward_gems,
    ...(expiresAt ? { expires_at: expiresAt } : {}),
  }));

  const { error } = await admin.from("inbox_items").insert(rows);
  if (error) return json({ error: error.message }, 500);

  return json({ sent: rows.length });
});
