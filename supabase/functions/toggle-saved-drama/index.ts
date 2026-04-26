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

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return json({ error: "Unauthorized" }, 401);

  const body = await req.json().catch(() => null);
  const { series_id } = body ?? {};
  if (!series_id) return json({ error: "series_id is required" }, 400);

  // Check if already saved
  const { data: existing } = await supabase
    .from("saved_dramas")
    .select("id")
    .eq("user_id", user.id)
    .eq("series_id", series_id)
    .maybeSingle();

  if (existing) {
    const { error: deleteError } = await supabase.from("saved_dramas").delete().eq("id", existing.id);
    if (deleteError) return json({ error: deleteError.message }, 500);
    return json({ saved: false });
  } else {
    const { error: insertError } = await supabase.from("saved_dramas").insert({ user_id: user.id, series_id });
    if (insertError) return json({ error: insertError.message }, 500);
    return json({ saved: true });
  }
});
