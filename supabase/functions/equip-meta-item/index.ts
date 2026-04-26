// [EDGE-FN] equip-meta-item — sets the active room, outfit, and/or mood for a user

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CATALOG: Record<string, Record<string, number>> = {
  room:   { apartment: 0, penthouse: 50, mansion: 120, yacht: 200, chalet: 150, island: 350 },
  outfit: { casual: 0, glam: 30, streetwear: 45, formal: 80, fantasy: 120 },
  mood:   { chill: 0, excited: 20, dramatic: 20, mysterious: 35, boss: 50 },
};

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const jwt = authHeader.slice(7);

  let body: { room_id?: string; outfit_id?: string; mood_id?: string };
  try { body = await req.json(); } catch { return json({ error: "Invalid JSON body" }, 400); }

  const { room_id, outfit_id, mood_id } = body;

  // At least one field must be provided
  if (!room_id && !outfit_id && !mood_id) {
    return json({ error: "At least one of room_id, outfit_id, or mood_id must be provided" }, 400);
  }

  // Validate provided item IDs against catalog
  if (room_id && CATALOG["room"][room_id] === undefined) {
    return json({ error: `Invalid room_id: ${room_id}` }, 400);
  }
  if (outfit_id && CATALOG["outfit"][outfit_id] === undefined) {
    return json({ error: `Invalid outfit_id: ${outfit_id}` }, 400);
  }
  if (mood_id && CATALOG["mood"][mood_id] === undefined) {
    return json({ error: `Invalid mood_id: ${mood_id}` }, 400);
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Validate JWT and get user
  const { data: { user }, error: authErr } = await supabaseAdmin.auth.getUser(jwt);
  if (authErr || !user) return json({ error: "Unauthorized" }, 401);
  const userId = user.id;

  // For each provided field, verify the item is free OR user has unlocked it
  const checks: Array<{ itemType: string; itemId: string; cost: number }> = [];
  if (room_id)   checks.push({ itemType: "room",   itemId: room_id,   cost: CATALOG["room"][room_id] });
  if (outfit_id) checks.push({ itemType: "outfit", itemId: outfit_id, cost: CATALOG["outfit"][outfit_id] });
  if (mood_id)   checks.push({ itemType: "mood",   itemId: mood_id,   cost: CATALOG["mood"][mood_id] });

  for (const { itemType, itemId, cost } of checks) {
    if (cost === 0) continue; // free item — no unlock needed

    const { data: unlock } = await supabaseAdmin
      .from("meta_unlocks")
      .select("id")
      .eq("user_id", userId)
      .eq("item_type", itemType)
      .eq("item_id", itemId)
      .maybeSingle();

    if (!unlock) {
      return json({ error: `Item not unlocked: ${itemType}/${itemId}` }, 403);
    }
  }

  // Upsert user_meta_profile
  const { error: upsertErr } = await supabaseAdmin
    .from("user_meta_profile")
    .upsert({
      user_id: userId,
      ...(room_id   ? { room_id }   : {}),
      ...(outfit_id ? { outfit_id } : {}),
      ...(mood_id   ? { mood_id }   : {}),
      updated_at: new Date().toISOString(),
    }, { onConflict: "user_id" });

  if (upsertErr) return json({ error: upsertErr.message }, 500);

  return json({ equipped: true });
});

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
