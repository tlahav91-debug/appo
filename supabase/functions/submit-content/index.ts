import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { submission_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { submission_id } = body;
  if (!submission_id) return json({ error: "submission_id is required" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Verify ownership + draft status
  const { data: submission } = await supabase
    .from("content_submissions")
    .select("id, creator_id, status, title, cf_stream_id")
    .eq("id", submission_id)
    .maybeSingle();

  if (!submission) return json({ error: "Submission not found" }, 404);
  if (submission.creator_id !== user.id) return json({ error: "Unauthorized" }, 403);
  if (submission.status !== "draft") return json({ error: "Submission is not in draft status" }, 409);
  if (!submission.cf_stream_id) return json({ error: "Video not uploaded yet" }, 400);

  const { error: updateErr } = await supabase
    .from("content_submissions")
    .update({ status: "submitted", submitted_at: new Date().toISOString() })
    .eq("id", submission_id);

  if (updateErr) return json({ error: updateErr.message }, 500);

  return json({ ok: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
