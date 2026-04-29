// [EDGE-FN] end-qa-session — flips session status to ended

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
  const anonClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!);
  const { data: { user }, error: authErr } = await anonClient.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { session_id } = body ?? {};
  if (!session_id) return json({ error: "session_id required" }, 400);

  const serviceClient = createClient(supabaseUrl, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: session, error: fetchErr } = await serviceClient
    .from("creator_qa_sessions")
    .select("id, status")
    .eq("id", session_id)
    .eq("creator_id", user.id)
    .maybeSingle();

  if (fetchErr || !session) return json({ error: "Session not found" }, 404);
  if (session.status !== "live") return json({ error: "Session is not live" }, 409);

  const { error: updateErr } = await serviceClient
    .from("creator_qa_sessions")
    .update({ status: "ended" })
    .eq("id", session_id);
  if (updateErr) return json({ error: "Failed to end session" }, 500);

  return json({ ended: true });
});
