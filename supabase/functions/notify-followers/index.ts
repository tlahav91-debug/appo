import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const adminSecret = req.headers.get("x-admin-secret");
  if (!adminSecret || adminSecret !== Deno.env.get("ADMIN_SECRET")) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: { creator_id?: string; episode_title?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { creator_id, episode_title } = body;
  if (!creator_id || !episode_title) return json({ error: "creator_id and episode_title required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Fetch followers
  const { data: follows } = await supabase
    .from("creator_follows")
    .select("follower_id")
    .eq("creator_id", creator_id);

  if (!follows || follows.length === 0) return json({ ok: true, notified: 0 });

  // Fetch creator display_name
  const { data: creatorProfile } = await supabase
    .from("creator_profiles")
    .select("display_name")
    .eq("id", creator_id)
    .single();

  const creatorName = creatorProfile?.display_name ?? "A creator";

  const notifications = follows.map((f: { follower_id: string }) => ({
    user_id: f.follower_id,
    type: "new_episode_from_followed",
    title: "New episode available",
    body: `${creatorName} just released: ${episode_title}`,
    metadata: { creator_id },
  }));

  const { error } = await supabase.from("creator_notifications").insert(notifications);
  if (error) return json({ error: error.message }, 500);

  // Fire-and-forget FCM push to each follower
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  Promise.allSettled(
    follows.map((f: { follower_id: string }) =>
      fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          user_id: f.follower_id,
          title: "New episode 🎬",
          body: `${creatorName} just released: ${episode_title}`,
          notification_type: "new_episodes",
          data: { creator_id, type: "new_episode" },
        }),
      })
    ),
  );

  return json({ ok: true, notified: notifications.length });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
