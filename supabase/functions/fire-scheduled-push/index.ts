// [EDGE-FN] fire-scheduled-push — fires pending scheduled push notifications (cron, every 5 min)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  const cronSecret = Deno.env.get("CRON_SECRET");
  const authHeader = req.headers.get("Authorization");
  if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
    return json({ error: "Unauthorized" }, 401);
  }

  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    serviceRoleKey,
  );

  const { data: due, error } = await supabase
    .from("scheduled_push_notifications")
    .select("id, user_id, payload")
    .lte("scheduled_for", new Date().toISOString())
    .is("sent_at", null)
    .limit(100);

  if (error) return json({ error: "Failed to fetch notifications" }, 500);
  if (!due || due.length === 0) return json({ fired: 0 });

  let fired = 0;
  for (const row of due) {
    // send-push-notification is service-role-only; the supabase client uses service_role_key
    // so functions.invoke will send Authorization: Bearer <service_role_key> automatically
    await supabase.functions.invoke("send-push-notification", {
      body: {
        user_id: row.user_id,
        title: row.payload.title,
        body: row.payload.body,
        data: row.payload.data ?? {},
        notification_type: "energy_refilled",
      },
    });

    await supabase
      .from("scheduled_push_notifications")
      .update({ sent_at: new Date().toISOString() })
      .eq("id", row.id);

    fired++;
  }

  return json({ fired });
});
