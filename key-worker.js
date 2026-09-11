/* ============================================================================
   AETHER HUB | key worker (Cloudflare Workers + KV).
   Keys: HWID-locked, 10-min rotating derivations, tiers, durations.
   Admin: hidden browser panel (?k=ADMIN_SECRET, unguessable, no links to
   it anywhere) — keys CRUD, ban, HWID reset, transfer, and remote KICK
   (troll kick with any custom message, e.g. fake anticheat text).
   The script polls /cmd every 60s and enforces kicks + bans itself.

   SETUP: Workers->Create->paste->Deploy. KV namespace KEYS. Bindings:
   KEYS (KV) + ADMIN_SECRET (text, long random). Never share the ?k= URL.
   ========================================================================== */

const RESET_DAYS = 14;
const RESET_MS = RESET_DAYS * 86400000;
const SLOT_MS = 600000;

function rid(n) {
  const a = new Uint8Array(n);
  crypto.getRandomValues(a);
  return [...a].map((b) => "ABCDEFGHJKMNPQRSTUVWXYZ23456789"[b % 32]).join("");
}

function slotNow() {
  return Math.floor(Date.now() / SLOT_MS);
}

async function derive(env, discordId, slot) {
  const msg = new TextEncoder().encode(env.ADMIN_SECRET + "|" + discordId + "|" + slot);
  const hash = await crypto.subtle.digest("SHA-256", msg);
  const hex = [...new Uint8Array(hash)].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
  return "AETHER-" + hex.slice(0, 4) + "-" + hex.slice(4, 8) + "-" + hex.slice(8, 12);
}

function json(data, status, headers) {
  if (status && typeof status === "object") { headers = status; status = 200; }
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: Object.assign({ "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" }, headers || {}),
  });
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

async function getRecord(env, key) {
  const raw = await env.KEYS.get("key:" + key);
  return raw ? JSON.parse(raw) : null;
}

async function putRecord(env, r) {
  await env.KEYS.put("key:" + r.key, JSON.stringify(r));
}

function expired(r) {
  return r.expiresAt && r.expiresAt > 0 && Date.now() > r.expiresAt;
}

async function scanKeys(env, fn, cap) {
  let cursor = undefined;
  let checked = 0;
  const out = [];
  do {
    const page = await env.KEYS.list({ prefix: "key:", limit: 200, cursor });
    for (const k of page.keys) {
      if (++checked > (cap || 2000)) return out;
      const raw = await env.KEYS.get(k.name);
      if (!raw) continue;
      const r = JSON.parse(raw);
      const hit = await fn(r);
      if (hit === "stop") return out;
      if (hit) out.push(r);
    }
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor);
  return out;
}

const PRESETS = [
  "BAC violation #X-14 (0x80070005). Rejoin to continue.",
  "Client integrity check failed. Unexpected client behavior (Error 267).",
  "You have been kicked for exploiting. Appeal in the Discord.",
];

function adminPage() {
  return "<!DOCTYPE html><html><head><meta charset=utf8><meta name=viewport content='width=device-width,initial-scale=1'>" +
    "<title>ax</title><style>" +
    "body{background:#0d0b18;color:#e8e6f5;font-family:Consolas,monospace;margin:0;padding:16px;font-size:13px}" +
    "h2{color:#8b5cf6;margin:18px 0 8px;font-size:14px}input,select,button{background:#1a1630;color:#e8e6f5;border:1px solid #8b5cf6;padding:5px 8px;font:inherit;margin:2px}" +
    "button{cursor:pointer}button:hover{background:#8b5cf6;color:#000}table{border-collapse:collapse;width:100%}" +
    "td,th{border:1px solid #333;padding:4px 6px;text-align:left;font-size:12px}.row{display:flex;flex-wrap:wrap;gap:4px;align-items:center}" +
    ".ban{color:#f87171}.ok{color:#34d399}" +
    "</style></head><body>" +
    "<h2>keys</h2><div class=row><button onclick=load()>reload</button>" +
    "<input id=cd placeholder='discord id' size=20><input id=ct placeholder='tier' size=8 value=normal>" +
    "<input id=ch placeholder='hours (0=life)' size=12 value=0><button onclick=mk()>create</button></div>" +
    "<table><thead><tr><th>key</th><th>discord</th><th>tier</th><th>bound</th><th>expires</th><th>ban</th><th></th></tr></thead><tbody id=tb></tbody></table>" +
    "<h2>troll kick</h2><div class=row><input id=kh placeholder='hwid (or all)' size=28>" +
    "<select id=kp></select><input id=km placeholder='custom message' size=42><button onclick=kick()>kick</button></div>" +
    "<div id=msg></div>" +
    "<script>" +
    "const K=new URLSearchParams(location.search).get('k')||'';" +
    "const PRESETS=" + JSON.stringify(PRESETS) + ";" +
    "const kp=document.getElementById('kp');" +
    "PRESETS.forEach(p=>{const o=document.createElement('option');o.textContent=p.slice(0,42);o.value=p;kp.appendChild(o);});" +
    "async function api(path,body){const r=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(Object.assign({secret:K},body))});return r.json();}" +
    "function say(t,ok){document.getElementById('msg').innerHTML='<span class='+(ok?'ok':'ban')+'>'+t+'</span>';}" +
    "async function load(){const r=await api('/admin/keys',{});if(!r.ok){say('nope',0);return;}" +
    "const tb=document.getElementById('tb');tb.innerHTML='';" +
    "r.keys.forEach(x=>{const tr=document.createElement('tr');" +
    "tr.innerHTML='<td>'+x.key+'</td><td>'+x.discordId+'</td><td>'+x.tier+'</td><td>'+(x.hwid?'yes':'no')+'</td><td>'+(x.expiresAt?new Date(x.expiresAt).toLocaleDateString():'life')+'</td><td>'+(x.banned?'YES':'no')+'</td>';" +
    "const td=document.createElement('td');" +
    "const b1=document.createElement('button');b1.textContent=x.banned?'unban':'ban';" +
    "b1.onclick=async()=>{await api('/admin/ban',{key:x.key,banned:!x.banned});load();};" +
    "const b2=document.createElement('button');b2.textContent='reset';" +
    "b2.onclick=async()=>{const d=await api('/key/reset-hwid',{key:x.key});say(d.ok?'reset ok':JSON.stringify(d),d.ok?1:0);load();};" +
    "const b3=document.createElement('button');b3.textContent='del';" +
    "b3.onclick=async()=>{if(confirm('delete?')){await api('/admin/del',{key:x.key});load();}};" +
    "td.append(b1,b2,b3);tr.appendChild(td);tb.appendChild(tr);});say(r.keys.length+' keys',1);}" +
    "async function mk(){const d=document.getElementById('cd').value;const r=await api('/key/create',{discordId:d,tier:document.getElementById('ct').value,hours:Number(document.getElementById('ch').value||0)});say(r.ok?r.key:JSON.stringify(r),r.ok?1:0);load();}" +
    "async function kick(){const h=document.getElementById('kh').value.trim()||'all';const m=document.getElementById('km').value||document.getElementById('kp').value;const r=await api('/admin/kick',{hwid:h,message:m});say(JSON.stringify(r),r.ok?1:0);}" +
    "load();</script></body></html>";
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cors = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    const p = url.pathname;

    if (p === "/" && request.method === "GET") {
      if (url.searchParams.get("k") !== env.ADMIN_SECRET) {
        return new Response("not found", { status: 404 });
      }
      return new Response(adminPage(), { headers: { "Content-Type": "text/html" } });
    }

    const needSecret = p.startsWith("/admin/");
    const checkSecret = async () => {
      if (needSecret) {
        const b = p === "/admin/keys" ? {} : await readJson(request);
        const s = b.secret || "";
        if (s !== env.ADMIN_SECRET) return false;
      }
      return true;
    };

    if (p === "/key/create" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false, reason: "bad secret" }, 403);
      if (!b.discordId) return json({ ok: false, reason: "discordId required" }, 400);
      const tier = b.tier === "premium" ? "premium" : "normal";
      const hours = Number(b.hours) || 0;
      const key = "AETHER-" + rid(4) + "-" + rid(4) + "-" + rid(4);
      await putRecord(env, {
        key, discordId: String(b.discordId), tier, hwid: null, banned: false,
        created: Date.now(), lastReset: 0,
        expiresAt: hours > 0 ? Date.now() + hours * 3600000 : 0,
      });
      return json({ ok: true, key, tier }, { headers: cors });
    }

    if (p === "/key/check") {
      const key = url.searchParams.get("key") || "";
      const hwid = url.searchParams.get("hwid") || "";
      const done = (valid, extra) => json(Object.assign({ valid }, extra || {}), { headers: cors });
      const hits = await scanKeys(env, (r) => {
        if (!r.hwid || r.hwid !== hwid) return false;
        return true;
      }, 2000);
      for (const r of hits) {
        if (r.banned) return done(false, { reason: "banned" });
        if (expired(r)) return done(false, { reason: "expired", tier: r.tier });
        if (r.key === key) return done(true, { tier: r.tier });
        const slot = slotNow();
        if (key === (await derive(env, r.discordId, slot)) || key === (await derive(env, r.discordId, slot - 1))) {
          return done(true, { tier: r.tier });
        }
      }
      return done(false, { reason: "no key" });
    }

    if (p === "/key/activate" && request.method === "POST") {
      const b = await readJson(request);
      if (!b.hwid) return json({ ok: false, reason: "no hwid" }, { headers: cors });
      let r = null;
      const direct = b.key ? await getRecord(env, b.key) : null;
      if (direct && !expired(direct)) r = direct;
      if (!r) {
        const cands = await scanKeys(env, (x) => !expired(x) && !!x.discordId, 2000);
        const slot = slotNow();
        for (const x of cands) {
          if (b.key === (await derive(env, x.discordId, slot)) || b.key === (await derive(env, x.discordId, slot - 1))) {
            r = x;
            break;
          }
        }
      }
      if (!r) return json({ ok: false, reason: "no key" }, { headers: cors });
      if (r.banned) return json({ ok: false, reason: "banned" }, { headers: cors });
      if (r.discordId && b.discordId && r.discordId !== String(b.discordId)) {
        return json({ ok: false, reason: "belongs to someone else" }, { headers: cors });
      }
      r.hwid = String(b.hwid);
      if (b.discordId && !r.discordId) r.discordId = String(b.discordId);
      await putRecord(env, r);
      return json({ ok: true, tier: r.tier || "normal" }, { headers: cors });
    }

    if (p === "/key/reset-hwid" && request.method === "POST") {
      const b = await readJson(request);
      const r = await getRecord(env, b.key || "");
      if (!r) return json({ ok: false, reason: "no key" }, { headers: cors });
      const next = (r.lastReset || 0) + RESET_MS;
      if (Date.now() < next) return json({ ok: false, reason: "cooldown", nextReset: next }, { headers: cors });
      r.hwid = null;
      r.lastReset = Date.now();
      await putRecord(env, r);
      return json({ ok: true, nextReset: Date.now() + RESET_MS }, { headers: cors });
    }

    if (p === "/key/transfer" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false, reason: "bad secret" }, 403);
      const r = await getRecord(env, b.key || "");
      if (!r) return json({ ok: false, reason: "no key" }, { headers: cors });
      if (!b.newDiscordId) return json({ ok: false, reason: "newDiscordId required" }, 400);
      const old = r.discordId;
      r.discordId = String(b.newDiscordId);
      r.hwid = null;
      await putRecord(env, r);
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
        const page = await env.KEYS.list({ prefix: "key:", limit: 500, cursor });
        for (const k of page.keys) {
          const raw = await env.KEYS.get(k.name);
          if (!raw) continue;
          const r = JSON.parse(raw);
          if (r.discordId === did) {
            out.push({ key: r.key, tier: r.tier || "normal", bound: !!r.hwid, banned: !!r.banned, expiresAt: r.expiresAt || 0, created: r.created });
          }
        }
        cursor = page.list_complete ? undefined : page.cursor;
      } while (cursor);
      return json({ ok: true, keys: out }, { headers: cors });
    }

    if (p === "/key/current") {
      const hwid = url.searchParams.get("hwid") || "";
      const did = url.searchParams.get("discordId") || "";
      const secret = url.searchParams.get("secret") || "";
      let r = null;
      if (hwid) {
        const hits = await scanKeys(env, (x) => x.hwid === hwid && !expired(x) && !x.banned, 2000);
        r = hits[0] || null;
        if (!r) return json({ ok: false, reason: "unknown hwid" }, { headers: cors });
      } else {
        if (secret !== env.ADMIN_SECRET || !did) {
          return json({ ok: false, reason: "need hwid or secret+discordId" }, 403);
        }
        const hits = await scanKeys(env, (x) => x.discordId === did && !expired(x), 2000);
        r = hits[0] || null;
        if (!r) return json({ ok: false, reason: "no key" }, { headers: cors });
      }
      const slot = slotNow();
      return json({
        ok: true,
        key: await derive(env, r.discordId, slot),
        tier: r.tier || "normal",
        validUntil: (slot + 1) * SLOT_MS,
      }, { headers: cors });
    }

    if (p === "/cmd" && request.method === "GET") {
      const hwid = url.searchParams.get("hwid") || "";
      if (hwid) {
        const raw = await env.KEYS.get("cmd:" + hwid);
        if (raw) {
          const c = JSON.parse(raw);
          if (Date.now() - c.at < 600000) return json(c, { headers: cors });
          await env.KEYS.delete("cmd:" + hwid);
        }
      }
      const bc = await env.KEYS.get("cmd:all");
      if (bc) {
        const c = JSON.parse(bc);
        if (Date.now() - c.at < 300000) return json(c, { headers: cors });
        await env.KEYS.delete("cmd:all");
      }
      return json({}, { headers: cors });
    }

    if (p === "/cmd/ack") {
      const hwid = url.searchParams.get("hwid") || "";
      if (hwid) await env.KEYS.delete("cmd:" + hwid);
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/admin/keys" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false }, 403);
      const out = [];
      let cursor = undefined;
      do {
        const page = await env.KEYS.list({ prefix: "key:", limit: 500, cursor });
        for (const k of page.keys) {
          const raw = await env.KEYS.get(k.name);
          if (!raw) continue;
          const r = JSON.parse(raw);
          out.push({ key: r.key, discordId: r.discordId, tier: r.tier || "normal", hwid: r.hwid ? r.hwid.slice(0, 10) + "…" : null, banned: !!r.banned, expiresAt: r.expiresAt || 0, created: r.created });
        }
        cursor = page.list_complete ? undefined : page.cursor;
      } while (cursor);
      out.sort((a, b2) => (b2.created || 0) - (a.created || 0));
      return json({ ok: true, keys: out }, { headers: cors });
    }

    if (p === "/admin/ban" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false }, 403);
      const r = await getRecord(env, b.key || "");
      if (!r) return json({ ok: false }, { headers: cors });
      r.banned = b.banned === true;
      await putRecord(env, r);
      return json({ ok: true, banned: r.banned }, { headers: cors });
    }

    if (p === "/admin/del" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false }, 403);
      await env.KEYS.delete("key:" + (b.key || ""));
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/admin/kick" && request.method === "POST") {
      const b = await readJson(request);
      if (b.secret !== env.ADMIN_SECRET) return json({ ok: false }, 403);
      const target = (b.hwid || "all").trim() || "all";
      await env.KEYS.put("cmd:" + target, JSON.stringify({ action: "kick", message: String(b.message || "Kicked.").slice(0, 200), at: Date.now() }));
      return json({ ok: true, target }, { headers: cors });
    }

    if (!needSecret) return json({ error: "unknown endpoint" }, 404);
    if (!(await checkSecret())) return json({ ok: false }, 403);
    return json({ error: "unknown endpoint" }, 404);
  },
};
