/* ============================================================================
   AETHER HUB | counter worker (Cloudflare Workers + KV)
   Powers the "Live network" panel: total executions + players online.

   SETUP (5 minutes, dashboard only):
     1. Cloudflare dashboard -> Workers & Pages -> Create Worker -> Deploy.
     2. Replace the worker code with this file -> Deploy again.
     3. Workers & Pages -> KV -> Create namespace called STATS.
     4. Back in the Worker -> Settings -> Bindings -> Add binding ->
        Variable name: STATS, KV namespace: STATS -> Deploy.
     5. Copy the worker URL, e.g. https://aether-counter.<you>.workers.dev

   WIRE UP:
     - Loader.luau: set HIT_URL to <worker-url>/hit
     - Website app.js: set STATS_URL to <worker-url>/stats

   ENDPOINTS:
     GET /hit   -> +1 execution, records heartbeat (called by the Loader)
     GET /stats -> {"total":123,"online":4} (called by the website)
   ========================================================================== */

const ONLINE_TTL = 300; // seconds a heartbeat counts as "online"

export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Content-Type": "application/json",
    };
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: cors });
    }
    const url = new URL(request.url);

    if (url.pathname === "/hit") {
      const total = parseInt((await env.STATS.get("total")) || "0", 10) + 1;
      await env.STATS.put("total", String(total));
      const ip =
        request.headers.get("CF-Connecting-IP") ||
        Math.random().toString(36).slice(2);
      await env.STATS.put("seen:" + ip, "1", { expirationTtl: ONLINE_TTL });
      return new Response(JSON.stringify({ ok: true, total }), { headers: cors });
    }

    if (url.pathname === "/stats") {
      const total = parseInt((await env.STATS.get("total")) || "0", 10);
      let online = 0;
      let cursor = undefined;
      do {
        const page = await env.STATS.list({ prefix: "seen:", limit: 1000, cursor });
        online += page.keys.length;
        cursor = page.list_complete ? undefined : page.cursor;
      } while (cursor);
      return new Response(JSON.stringify({ total, online }), { headers: cors });
    }

    return new Response(JSON.stringify({ error: "use /hit or /stats" }), {
      status: 404,
      headers: cors,
    });
  },
};
