/* ============================================================================
   AETHER HUB | key worker (Cloudflare Workers + KV).
   Keys: HWID-locked, 10-min rotating derivations, tiers, durations.
   Admin: hidden browser panel (?k=ADMIN_SECRET, unguessable, no links to
   it anywhere) — keys CRUD, ban, HWID reset, transfer, and remote KICK
   (troll kick with any custom message, e.g. fake anticheat text).
   The script polls /cmd every 60s and enforces kicks + bans itself.

   SETUP: Workers->Create->paste->Deploy. KV namespace KEYS. Bindings:
   KEYS (KV) + ADMIN_SECRET (text, long random). Never share the ?k= URL.
   Optional MASTER_HWID (text): your own gethwid() output. The /cmd poller
   never delivers kicks to it, and /admin/kick refuses to target it, so a
   stale test command or mistaken 'all' can never kick your own machine.
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

function adminSlot() {
  return Math.floor(Date.now() / 21600000);
}

async function adminPath(env, slot) {
  const msg = new TextEncoder().encode(env.ADMIN_SECRET + "|admin|" + slot);
  const hash = await crypto.subtle.digest("SHA-256", msg);
  const hex = [...new Uint8Array(hash)].map((b) => b.toString(16).padStart(2, "0")).join("");
  return "/ax-" + hex.slice(0, 12);
}

function getCookie(request, name) {
  const h = request.headers.get("Cookie") || "";
  const m = h.match(new RegExp("(?:^|;\\s*)" + name + "=([^;]*)"));
  return m ? decodeURIComponent(m[1]) : "";
}

async function authed(env, request) {
  const t = getCookie(request, "ax");
  if (!t) return false;
  const v = await env.KEYS.get("sess:" + t);
  return !!v;
}

async function logAccess(env, request) {
  try {
    const ip = request.headers.get("CF-Connecting-IP") || "?";
    const ua = (request.headers.get("User-Agent") || "?").slice(0, 80);
    const raw = await env.KEYS.get("axlog");
    const arr = raw ? JSON.parse(raw) : [];
    arr.unshift({ ip, ua, at: Date.now() });
    await env.KEYS.put("axlog", JSON.stringify(arr.slice(0, 50)));
  } catch {}
}

async function deriveGlobal(env, slot) {
  const msg = new TextEncoder().encode(env.ADMIN_SECRET + "|global|" + slot);
  const hash = await crypto.subtle.digest("SHA-256", msg);
  const hex = [...new Uint8Array(hash)].map((b) => b.toString(16).padStart(2, "0")).join("").toUpperCase();
  return "AETHER-" + hex.slice(0, 4) + "-" + hex.slice(4, 8) + "-" + hex.slice(8, 12);
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
    "<title>Aether Hub - Admin</title><style>" +
    "body{background:#008080;font-family:Tahoma,Geneva,sans-serif;font-size:12px;margin:0;padding:16px;color:#000}" +
    ".win{background:#c6c6c6;box-shadow:inset -1px -1px #0a0a0a,inset 1px 1px #fff,inset -2px -2px #808080,inset 2px 2px #dfdfdf;padding:3px;max-width:920px;margin:0 auto 14px}" +
    ".title{background:#000080;color:#fff;font-weight:bold;padding:2px 6px;margin-bottom:4px}" +
    ".btn{background:#c6c6c6;border:0;padding:3px 12px;font:inherit;cursor:pointer;margin:2px;box-shadow:inset -1px -1px #0a0a0a,inset 1px 1px #fff,inset -2px -2px #808080,inset 2px 2px #dfdfdf}" +
    ".btn:active{box-shadow:inset -1px -1px #fff,inset 1px 1px #0a0a0a,inset -2px -2px #dfdfdf,inset 2px 2px #808080}" +
    "input,select{background:#fff;border:0;padding:3px 5px;font:inherit;margin:2px;box-shadow:inset -1px -1px #fff,inset 1px 1px #808080,inset -2px -2px #dfdfdf,inset 2px 2px #0a0a0a}" +
    "table{border-collapse:collapse;width:100%;background:#fff}" +
    "td,th{border:1px solid #808080;padding:3px 5px;text-align:left;font-size:11px}" +
    ".row{padding:2px 4px}.err{color:#c80000;padding:2px 6px;min-height:14px}#lock{width:310px;margin:70px auto}" +
    "</style></head><body>" +
    "<div class=win id=lock><div class=title>Aether Hub - Admin</div>" +
    "<form onsubmit='return tryPw()' style=padding:6px>Password<br>" +
    "<input id=pw type=password autocomplete=off style=width:180px><button class=btn>OK</button>" +
    "<div class=err id=err></div></form></div>" +
    "<div id=app style=display:none>" +
    "<div class=win><div class=title>Aether Hub - Admin \u{1F6E1}</div>" +
    "<div class=row><b>keys</b> <button class=btn onclick=load()>reload</button> " +
    "<input id=cd placeholder='discord id' size=18><input id=ct placeholder='tier' size=7 value=normal>" +
    "<input id=ch placeholder='hours (0=life)' size=11 value=0><button class=btn onclick=mk()>create</button></div>" +
    "<table><thead><tr><th>key</th><th>discord</th><th>tier</th><th>bound</th><th>expires</th><th>ban</th><th></th></tr></thead><tbody id=tb></tbody></table></div>" +
    "<div class=win><div class=title>Troll kick</div>" +
    "<div class=row><input id=kh placeholder='hwid (or all)' size=26><select id=kp></select>" +
    "<input id=km placeholder='custom message' size=38><button class=btn onclick=kick()>kick</button></div></div>" +
    "<div class=win><div class=title>Pending commands</div><div id=cq class=row>—</div></div>" +
    "<div class=win><div class=title>Broadcast to all hubs</div>" +
    "<div class=row><input id=sm placeholder='message for every running hub' size=52><button class=btn onclick=say()>send</button></div></div>" +
    "<div class=win><div class=title>Access log</div><div class=row id=lg>—</div></div>" +
    "<div id=msg style='max-width:920px;margin:0 auto;color:#fff'></div></div>" +
    "<script>" +
    "const PRESETS=" + JSON.stringify(PRESETS) + ";" +
    "function tryPw(){const v=document.getElementById('pw').value;" +
    "if(v===String.fromCharCode(53,55,53,48)){document.getElementById('lock').style.display='none';document.getElementById('app').style.display='block';init();return false;}" +
    "document.getElementById('err').textContent='Minimum 5 letters or numbers.';return false;}" +
    "const kp=document.getElementById('kp');let inited=false;" +
    "function init(){if(inited)return;inited=true;" +
    "PRESETS.forEach(p=>{const o=document.createElement('option');o.textContent=p.slice(0,42);o.value=p;kp.appendChild(o);});load();loadLog();cmds();}" +
    "async function api(path,body){const r=await fetch(path,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body||{})});return r.json();}" +
    "async function load(){const r=await api('/admin/keys',{});if(!r.ok)return;" +
    "const tb=document.getElementById('tb');tb.innerHTML='';" +
    "r.keys.forEach(x=>{const tr=document.createElement('tr');" +
    "tr.innerHTML='<td>'+x.key+'</td><td>'+x.discordId+'</td><td>'+x.tier+'</td><td>'+(x.hwid?'yes':'no')+'</td><td>'+(x.expiresAt?new Date(x.expiresAt).toLocaleDateString():'life')+'</td><td>'+(x.banned?'YES':'no')+'</td>';" +
    "const td=document.createElement('td');" +
    "const b1=document.createElement('button');b1.className='btn';b1.textContent=x.banned?'unban':'ban';" +
    "b1.onclick=async()=>{await api('/admin/ban',{key:x.key,banned:!x.banned});load();};" +
    "const b2=document.createElement('button');b2.className='btn';b2.textContent='reset';" +
    "b2.onclick=async()=>{await api('/key/reset-hwid',{key:x.key});load();};" +
    "const b3=document.createElement('button');b3.className='btn';b3.textContent='del';" +
    "b3.onclick=async()=>{if(confirm('delete?')){await api('/admin/del',{key:x.key});load();}};" +
    "td.append(b1,b2,b3);tr.appendChild(td);tb.appendChild(tr);});}" +
    "async function mk(){const d=document.getElementById('cd').value;await api('/key/create',{discordId:d,tier:document.getElementById('ct').value,hours:Number(document.getElementById('ch').value||0)});load();}" +
    "async function kick(){const h=document.getElementById('kh').value.trim()||'all';const m=document.getElementById('km').value||document.getElementById('kp').value;" +
    "if(h==='all'&&!confirm('Kick EVERY running Aether Hub client? This hits every active user.'))return;" +
    "await api('/admin/kick',{hwid:h,message:m});cmds();}" +
    "async function cmds(){try{const r=await (await fetch('/admin/cmds',{method:'POST'})).json();" +
    "const el=document.getElementById('cq');const items=(r&&r.cmds)||[];el.innerHTML='';" +
    "if(!items.length){el.innerHTML='none pending';return;}" +
    "items.forEach(c=>{const d=document.createElement('div');d.className='row';" +
    "const s=document.createElement('span');s.textContent=(c.key==='cmd:all'?'[broadcast] ':c.key)+' — '+(c.message||'').slice(0,44);" +
    "const b=document.createElement('button');b.className='btn';b.textContent='clear';b.onclick=async()=>{await api('/admin/clear',{key:c.key});cmds();};" +
    "d.append(s,b);el.appendChild(d);});}catch(e){document.getElementById('cq').textContent='no access';}}" +
    "async function say(){const m=document.getElementById('sm').value;if(m)await api('/admin/say',{message:m});}" +
    "async function loadLog(){try{const r=await (await fetch('/admin/log')).json();" +
    "if(r.ok)document.getElementById('lg').innerHTML=r.rows.map(e=>new Date(e.at).toLocaleString()+' — '+e.ip).join('<br>')||'no visits yet';}catch(e){}}" +
    "</script></body></html>";
}
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const cors = { "Access-Control-Allow-Origin": "*", "Content-Type": "application/json" };
    if (request.method === "OPTIONS") return new Response(null, { headers: cors });
    const p = url.pathname;

    if (request.method === "GET" && p.startsWith("/ax-")) {
      const slot = adminSlot();
      const ok =
        p === (await adminPath(env, slot)) || p === (await adminPath(env, slot - 1));
      if (!ok || !env.ADMIN_SECRET) {
        return new Response("not found", { status: 404 });
      }
      const tok = [...crypto.getRandomValues(new Uint8Array(16))]
        .map((b) => b.toString(16).padStart(2, "0")).join("");
      await env.KEYS.put("sess:" + tok, "1", { expirationTtl: 21600 });
      logAccess(env, request).catch(() => {});
      return new Response(adminPage(), {
        headers: {
          "Content-Type": "text/html",
          "Set-Cookie": "ax=" + tok + "; HttpOnly; SameSite=Strict; Max-Age=21600; Path=/",
        },
      });
    }
    if (p === "/" && request.method === "GET") {
      return new Response("not found", { status: 404 });
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
      if (b.secret !== env.ADMIN_SECRET && !(await authed(env, request))) {
        return json({ ok: false, reason: "bad secret" }, 403);
      }
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
      const gslot = slotNow();
      if (key === (await deriveGlobal(env, gslot)) || key === (await deriveGlobal(env, gslot - 1))) {
        return done(true, { tier: "normal", global: true });
      }
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

    if (p === "/key/activate" && (request.method === "POST" || request.method === "GET")) {
      const b = request.method === "GET" ? Object.fromEntries(url.searchParams.entries()) : await readJson(request);
      if (!b.hwid) return json({ ok: false, reason: "no hwid" }, { headers: cors });
      const gslot = slotNow();
      if (b.key === (await deriveGlobal(env, gslot)) || b.key === (await deriveGlobal(env, gslot - 1))) {
        return json({ ok: true, tier: "normal", global: true }, { headers: cors });
      }
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
      if ((r.tier || "normal") !== "premium") {
        return json({ ok: false, reason: "premium only" }, { headers: cors });
      }
      const next = (r.lastReset || 0) + RESET_MS;
      if (Date.now() < next) return json({ ok: false, reason: "cooldown", nextReset: next }, { headers: cors });
      if (!b.newDiscordId) return json({ ok: false, reason: "newDiscordId required" }, 400);
      const old = r.discordId;
      r.discordId = String(b.newDiscordId);
      r.hwid = null;
      r.lastReset = Date.now();
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
      if (!hwid && !(secret && did)) {
        const slot = slotNow();
        return json({
          ok: true,
          key: await deriveGlobal(env, slot),
          tier: "normal",
          global: true,
          validUntil: (slot + 1) * SLOT_MS,
        }, { headers: cors });
      }
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
      const master = (env.MASTER_HWID || "").trim();
      const prot = !!master && hwid === master;
      const out = {};
      if (hwid && prot) {
        // Master machine: silently drop any pending per-hwid kick so a stale
        // test command can never boot the owner out of their own hub.
        await env.KEYS.delete("cmd:" + hwid);
      } else if (hwid) {
        const raw = await env.KEYS.get("cmd:" + hwid);
        if (raw) {
          try {
            const c = JSON.parse(raw);
            if (Date.now() - c.at < 600000) Object.assign(out, c);
            else await env.KEYS.delete("cmd:" + hwid);
          } catch {
            await env.KEYS.delete("cmd:" + hwid);
          }
        }
      }
      if (!prot) {
        const bc = await env.KEYS.get("cmd:all");
        if (bc) {
          try {
            const c = JSON.parse(bc);
            if (Date.now() - c.at < 300000) Object.assign(out, c);
            else await env.KEYS.delete("cmd:all");
          } catch {
            await env.KEYS.delete("cmd:all");
          }
        }
      }
      const sm = await env.KEYS.get("cmd:allmsg");
      if (sm) {
        try {
          const c = JSON.parse(sm);
          if (Date.now() - c.at < 300000) {
            out.msg = c.message;
            out.msgAt = c.at;
          } else await env.KEYS.delete("cmd:allmsg");
        } catch {
          await env.KEYS.delete("cmd:allmsg");
        }
      }
      return json(out, { headers: cors });
    }

    if (p === "/cmd/ack") {
      const hwid = url.searchParams.get("hwid") || "";
      if (hwid) await env.KEYS.delete("cmd:" + hwid);
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/admin/keys" && request.method === "POST") {
      const b = await readJson(request);
      if (!(await authed(env, request))) return json({ ok: false }, 403);
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
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      const r = await getRecord(env, b.key || "");
      if (!r) return json({ ok: false }, { headers: cors });
      r.banned = b.banned === true;
      await putRecord(env, r);
      return json({ ok: true, banned: r.banned }, { headers: cors });
    }

    if (p === "/admin/del" && request.method === "POST") {
      const b = await readJson(request);
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      await env.KEYS.delete("key:" + (b.key || ""));
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/admin/kick" && request.method === "POST") {
      const b = await readJson(request);
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      const target = (b.hwid || "all").trim() || "all";
      const master = (env.MASTER_HWID || "").trim();
      if (master && target === master) {
        return json({ ok: false, reason: "master protected" }, 403);
      }
      await env.KEYS.put("cmd:" + target, JSON.stringify({ action: "kick", message: String(b.message || "Kicked.").slice(0, 200), at: Date.now() }));
      return json({ ok: true, target }, { headers: cors });
    }

    if (p === "/admin/cmds" && request.method === "POST") {
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      const out = [];
      let cursor = undefined;
      do {
        const page = await env.KEYS.list({ prefix: "cmd:", limit: 100, cursor });
        for (const k of page.keys) {
          const raw = await env.KEYS.get(k.name);
          if (!raw) continue;
          try {
            const c = JSON.parse(raw);
            out.push({ key: k.name, at: c.at || 0, message: c.message || "" });
          } catch {}
        }
        cursor = page.list_complete ? undefined : page.cursor;
      } while (cursor);
      out.sort((a, b) => (b.at || 0) - (a.at || 0));
      return json({ ok: true, cmds: out }, { headers: cors });
    }

    if (p === "/admin/clear" && request.method === "POST") {
      const b = await readJson(request);
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      const k = String(b.key || "").trim();
      if (!k.startsWith("cmd:")) return json({ ok: false, reason: "bad key" }, 400);
      await env.KEYS.delete(k);
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/admin/say" && request.method === "POST") {
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      const b = await readJson(request);
      if (!b.message) return json({ ok: false }, 400);
      await env.KEYS.put("cmd:allmsg", JSON.stringify({ message: String(b.message).slice(0, 200), at: Date.now() }), { expirationTtl: 300 });
      return json({ ok: true }, { headers: cors });
    }

    if (p === "/admin/log" && request.method === "GET") {
      if (!(await authed(env, request))) return json({ ok: false }, 403);
      const raw = await env.KEYS.get("axlog");
      return json({ ok: true, rows: raw ? JSON.parse(raw) : [] }, { headers: cors });
    }

    if (!needSecret) return json({ error: "unknown endpoint" }, 404);
    if (!(await checkSecret())) return json({ ok: false }, 403);
    return json({ error: "unknown endpoint" }, 404);
  },
};
