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
  if (!authHeader) return json({ error: "Unauthorized" }, 401);

  // Validate JWT with anon client
  const anonClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await anonClient.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { comment_id } = body ?? {};

  if (!comment_id || typeof comment_id !== "string") {
    return json({ error: "comment_id is required" }, 400);
  }

  // Use service_role client for DB operations
  const serviceClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Fetch the comment to verify ownership
  const { data: comment, error: fetchError } = await serviceClient
    .from("episode_comments")
    .select("id, user_id, deleted_at")
    .eq("id", comment_id)
    .single();

  if (fetchError || !comment) {
    return json({ error: "Comment not found" }, 404);
  }

  if (comment.user_id !== user.id) {
    return json({ error: "Forbidden" }, 403);
  }

  // Soft-delete: set deleted_at
  const { error: updateError } = await serviceClient
    .from("episode_comments")
    .update({ deleted_at: new Date().toISOString() })
    .eq("id", comment_id);

  if (updateError) {
    return json({ error: updateError.message }, 500);
  }

  return json({ ok: true });
});
