/* ============================================================================
   AETHER HUB | key worker (Cloudflare Workers + KV) — premium key system.
   Keys are HWID-locked. HWID reset allowed every RESET_DAYS (14).

   SETUP:
     1. Workers & Pages -> Create Worker -> paste this file -> Deploy.
     2. KV -> Create namespace KEYS.
     3. Worker Settings -> Bindings: KEYS (KV), ADMIN_SECRET (text, long random).
     4. URL + ADMIN_SECRET go into the bot .env (KEYWORKER_URL, KEY_ADMIN)
        and KEYWORKER_URL (+ "/key/activate" path) into the script HUB.keyUrl.

   NOTE on LootLabs: LootLabs monetizes links, it does not host keys, so
   there is nothing to call server-side. Flow: buyer goes through your
   LootLabs link (LOOTLABS_URL in bot .env, shown on Get Key), then staff
   runs /premium-grant, or the panel issues the key. The worker below is
   the source of truth for key/hwid/discord bindings.

   ENDPOINTS (JSON):
     POST /key/create      {secret, discordId}            -> {key}
     GET  /key/check?key=&hwid=                           -> {valid, reason}
     POST /key/activate    {key, hwid, discordId}         -> {ok, reason}
     POST /key/reset-hwid  {key}                          -> {ok, nextReset}
     POST /key/transfer    {secret, key, newDiscordId}    -> {ok}
     GET  /key/mine?discordId=&secret=                    -> {keys:[{key,bound,created}]}
   ========================================================================== */

const RESET_DAYS = 14;
const RESET_MS = RESET_DAYS * 86400000;

function rid(n) {
  const a = new Uint8Array(n);
  crypto.getRandomValues(a);
  return [...a].map((b) => "ABCDEFGHJKMNPQRSTUVWXYZ23456789"[b % 32]).join("");
}

function json(data, status) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cors = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    const p = url.pathname;

    if (p === "/key/create" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false, reason: "bad secret" }, 403);
      if (!b.discordId) return json({ ok: false, reason: "discordId required" }, 400);
      const key = "AETHER-" + rid(4) + "-" + rid(4) + "-" + rid(4);
      await env.KEYS.put("key:" + key, JSON.stringify({
        key, discordId: String(b.discordId), hwid: null,
        created: Date.now(), lastReset: 0,
      }));
      return json({ ok: true, key }, { headers: cors });
    }

    if (p === "/key/check") {
      const key = url.searchParams.get("key") || "";
      const hwid = url.searchParams.get("hwid") || "";
      const raw = await env.KEYS.get("key:" + key);
      if (!raw) return json({ valid: false, reason: "no key" }, { headers: cors });
      const r = JSON.parse(raw);
      if (!r.hwid) return json({ valid: false, reason: "not activated" }, { headers: cors });
      if (r.hwid !== hwid) return json({ valid: false, reason: "hwid mismatch" }, { headers: cors });
      return json({ valid: true }, { headers: cors });
    }

    if (p === "/key/activate" && request.method === "POST") {
      const b = await readJson(request);
      const raw = await env.KEYS.get("key:" + (b.key || ""));
      if (!raw) return json({ ok: false, reason: "no key" }, { headers: cors });
      if (!b.hwid) return json({ ok: false, reason: "no hwid" }, { headers: cors });
      const r = JSON.parse(raw);
      if (r.discordId && b.discordId && r.discordId !== String(b.discordId)) {
        return json({ ok: false, reason: "belongs to someone else" }, { headers: cors });
      }
      r.hwid = String(b.hwid);
      if (b.discordId && !r.discordId) r.discordId = String(b.discordId);
      await env.KEYS.put("key:" + r.key, JSON.stringify(r));
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/key/reset-hwid" && request.method === "POST") {
      const b = await readJson(request);
      const raw = await env.KEYS.get("key:" + (b.key || ""));
      if (!raw) return json({ ok: false, reason: "no key" }, { headers: cors });
      const r = JSON.parse(raw);
      const next = (r.lastReset || 0) + RESET_MS;
      if (Date.now() < next) return json({ ok: false, reason: "cooldown", nextReset: next }, { headers: cors });
      r.hwid = null;
      r.lastReset = Date.now();
      await env.KEYS.put("key:" + r.key, JSON.stringify(r));
      return json({ ok: true, nextReset: Date.now() + RESET_MS }, { headers: cors });
    }

    if (p === "/key/transfer" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false, reason: "bad secret" }, 403);
      const raw = await env.KEYS.get("key:" + (b.key || ""));
      if (!raw) return json({ ok: false, reason: "no key" }, { headers: cors });
      if (!b.newDiscordId) return json({ ok: false, reason: "newDiscordId required" }, 400);
      const r = JSON.parse(raw);
      const old = r.discordId;
      r.discordId = String(b.newDiscordId);
      r.hwid = null;
      await env.KEYS.put("key:" + r.key, JSON.stringify(r));
      return json({ ok: true, old }, { headers: cors });
    }

    if (p === "/key/mine") {
      if (url.searchParams.get("secret") !== env.ADMIN_SECRET) {
        return json({ ok: false, reason: "bad secret" }, 403);
      }
      const did = String(url.searchParams.get("discordId") || "");
      const out = [];
      let cursor = undefined;
      do {
        const page = await env.KEYS.list({ prefix: "key:", limit: 1000, cursor });
        for (const k of page.keys) {
          const raw = await env.KEYS.get(k.name);
          if (!raw) continue;
          const r = JSON.parse(raw);
          if (r.discordId === did) out.push({ key: r.key, bound: !!r.hwid, created: r.created });
        }
        cursor = page.list_complete ? undefined : page.cursor;
      } while (cursor);
      return json({ ok: true, keys: out }, { headers: cors });
    }

    return json({ error: "unknown endpoint" }, 404);
  },
};
