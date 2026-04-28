import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { display_name?: string; bio?: string; payout_email?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON" }, 400); }

  const { display_name, bio, payout_email } = body;

  // Validate
  if (display_name !== undefined && (display_name.trim().length < 2 || display_name.trim().length > 50)) {
    return json({ error: "display_name must be 2–50 characters" }, 400);
  }
  if (bio !== undefined && bio.length > 300) {
    return json({ error: "bio must be 300 characters or fewer" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: { user }, error: authErr } = await supabase.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);

  // Verify the user is an approved creator
  const { data: profile } = await supabase
    .from("creator_profiles")
    .select("id, status")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile) return json({ error: "Creator profile not found" }, 404);
  if (profile.status !== "approved") return json({ error: "Only approved creators can update their profile" }, 403);

  // Build update payload — only include provided fields
  const updates: Record<string, string> = {};
  if (display_name !== undefined) updates.display_name = display_name.trim();
  if (bio !== undefined) updates.bio = bio;
  if (payout_email !== undefined) updates.payout_email = payout_email.trim();

  if (Object.keys(updates).length === 0) return json({ error: "No fields to update" }, 400);

  const { error: updateErr } = await supabase
    .from("creator_profiles")
    .update(updates)
    .eq("id", user.id);

  if (updateErr) return json({ error: updateErr.message }, 500);

  return json({ ok: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
