import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const authHeader = req.headers.get("Authorization") ?? "";

  if (!serviceKey || authHeader !== `Bearer ${serviceKey}`) {
    return json({ error: "Service role required" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceClient = createClient(supabaseUrl, serviceKey);

  const now = new Date();
  const todayStr = now.toISOString().substring(0, 10);
  const yesterday = new Date(now);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().substring(0, 10);

  // Users who checked in yesterday
  const { data: checkedYesterday } = await serviceClient
    .from("daily_check_ins")
    .select("user_id")
    .gte("checked_in_at", `${yesterdayStr}T00:00:00Z`)
    .lt("checked_in_at", `${todayStr}T00:00:00Z`);

  if (!checkedYesterday?.length) return json({ reminded: 0 });

  // Users who already checked in today — exclude them
  const { data: checkedToday } = await serviceClient
    .from("daily_check_ins")
    .select("user_id")
    .gte("checked_in_at", `${todayStr}T00:00:00Z`);

  const todayIds = new Set(
    (checkedToday ?? []).map((r: { user_id: string }) => r.user_id),
  );

  const uniqueAtRisk = [
    ...new Set(
      checkedYesterday
        .filter((r: { user_id: string }) => !todayIds.has(r.user_id))
        .map((r: { user_id: string }) => r.user_id),
    ),
  ];

  if (!uniqueAtRisk.length) return json({ reminded: 0 });

  // Send push in batches of 20 to stay within timeout
  const BATCH = 20;
  for (let i = 0; i < uniqueAtRisk.length; i += BATCH) {
    await Promise.allSettled(
      uniqueAtRisk.slice(i, i + BATCH).map((userId: string) =>
        fetch(`${supabaseUrl}/functions/v1/send-push-notification`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${serviceKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            user_id: userId,
            title: "🔥 Keep your streak alive!",
            body: "You haven't checked in today. Don't break your streak!",
            notification_type: "streak_reminder",
            data: { type: "streak_reminder" },
          }),
        })
      ),
    );
  }

  return json({ reminded: uniqueAtRisk.length });
});
