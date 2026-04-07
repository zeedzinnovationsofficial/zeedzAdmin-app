import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req: Request) => {
  try {
    const { playerId, title, body } = await req.json();

    console.log("🔥 Sending notification:", playerId, title);

    const response = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Key os_v2_app_jhhrhgkwtfeoxlbzpnehu3ga4vd5rnd6ifbu7r4ddsi5rbxqfysrza6rrkunafxwtvxdgmkekoi5cjm264yi5ruhiaswp55lrivb7hi", // ✅ NEW KEY HERE
      },
      body: JSON.stringify({
        app_id: "49cf1399-5699-48eb-ac39-7b487a6cc0e5",

        include_player_ids: [playerId],

        headings: { en: title },
        contents: { en: body },

        android_priority: 10,
        priority: 10,

        content_available: true,
        mutable_content: true,

        ttl: 86400,
      }),
    });

    const data = await response.json();

    console.log("✅ OneSignal response:", data);

    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (e) {
    console.log("❌ ERROR:", e);
    return new Response(JSON.stringify({ error: e }), { status: 500 });
  }
  const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
});