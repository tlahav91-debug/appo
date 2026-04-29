// [EDGE-FN] start-qa-session — flips session status to live, returns messages, notifies followers

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const anonClient = createClient(supabaseUrl, anonKey);
  const { data: { user }, error: authErr } = await anonClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { session_id } = body ?? {};
  if (!session_id) return json({ error: "session_id required" }, 400);

  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: session, error: fetchErr } = await serviceClient
    .from("creator_qa_sessions")
    .select("id, creator_id, status, scheduled_at")
    .eq("id", session_id)
    .eq("creator_id", user.id)
    .maybeSingle();

  if (fetchErr || !session) return json({ error: "Session not found" }, 404);
  if (session.status !== "scheduled") return json({ error: "Session already started or ended" }, 409);

  // Enforce 10-minute early start window
  const scheduledMs = new Date(session.scheduled_at).getTime();
  const nowMs = Date.now();
  if (nowMs < scheduledMs - 10 * 60 * 1000) {
    return json({ error: "Too early — can only start within 10 minutes of scheduled time" }, 422);
  }

  const { error: updateErr } = await serviceClient
    .from("creator_qa_sessions")
    .update({ status: "live" })
    .eq("id", session_id);
  if (updateErr) return json({ error: "Failed to start session" }, 500);

  const { data: messages, error: msgErr } = await serviceClient
    .from("creator_qa_messages")
    .select("id, body, delay_seconds, position")
    .eq("session_id", session_id)
    .order("position", { ascending: true });
  if (msgErr) return json({ error: "Failed to fetch messages" }, 500);

  // Fire-and-forget push to followers
  const { data: followers } = await serviceClient
    .from("creator_follows")
    .select("follower_id")
    .eq("creator_id", user.id);

  if (followers?.length) {
    Promise.allSettled(
      followers.map((f: { follower_id: string }) =>
        fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${serviceRoleKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            user_id: f.follower_id,
            title: "Live Q&A 🎤",
            body: "A creator you follow just started a Live Q&A!",
            notification_type: "creator_updates",
          }),
        }),
      ),
    );
  }

  return json({ messages: messages ?? [], started_at: new Date().toISOString() });
});
