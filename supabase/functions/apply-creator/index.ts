import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { display_name?: string; bio?: string; why_create?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { display_name, bio, why_create } = body;
  if (!display_name || !bio || !why_create) {
    return json({ error: "display_name, bio, and why_create are required" }, 400);
  }
  if (bio.length > 300) return json({ error: "bio must be 300 chars or less" }, 400);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Check for existing application
  const { data: existing } = await supabase
    .from("creator_profiles")
    .select("id, status")
    .eq("id", user.id)
    .maybeSingle();

  if (existing) {
    return json({ error: "ALREADY_APPLIED", status: existing.status }, 409);
  }

  const { error: insertErr } = await supabase.from("creator_profiles").insert({
    id: user.id,
    display_name: display_name.trim(),
    bio: bio.trim(),
    why_create: why_create.trim(),
    status: "pending",
  });

  if (insertErr) return json({ error: insertErr.message }, 500);
  return json({ ok: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
