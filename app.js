/* Aether Hub Website — Win95 behaviour: tabs, drag, resize, tooltips,
   message-box notifications, trackbars, combos, keybind, paint canvas,
   persistent config, clock. Every control on screen does something. */
(function () {
  "use strict";
  var win = document.getElementById("win"),
      titlebar = document.getElementById("titlebar"),
      hintpanel = document.getElementById("hintpanel"),
      sizepanel = document.getElementById("sizepanel"),
      tip = document.getElementById("tip"),
      zoom = document.getElementById("zoomrect"),
      msghost = document.getElementById("msghost"),
      comboList = document.getElementById("comboList"),
      DEFAULT_HINT = "For Help, press F1",
      tipsOn = true, notifOn = true, clockSeconds = false;

  /* ---------- opening zoom-rectangle (like UILIB zoomRect) ---------- */
  function zoomOpen() {
    var r = win.getBoundingClientRect();
    var cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    var steps = 4, i = 0;
    win.style.visibility = "hidden";
    zoom.style.display = "block";
    (function tick() {
      var t = i / steps;
      var w = r.width * (0.2 + 0.8 * t), h = r.height * (0.2 + 0.8 * t);
      zoom.style.left = (cx - w / 2) + "px";
      zoom.style.top = (cy - h / 2) + "px";
      zoom.style.width = w + "px"; zoom.style.height = h + "px";
      if (++i <= steps) setTimeout(tick, 16);
      else { zoom.style.display = "none"; win.style.visibility = "visible"; refreshSize(); }
    })();
  }
  window.addEventListener("load", zoomOpen);

  /* ---------- tabs ---------- */
  var tabs = Array.prototype.slice.call(document.querySelectorAll(".tab"));
  var pages = Array.prototype.slice.call(document.querySelectorAll(".page"));
  function goto(id) {
    tabs.forEach(function (t) { t.classList.toggle("on", t.dataset.tab === id); });
    pages.forEach(function (p) { p.classList.toggle("on", p.id === id); });
    if (win.style.display === "none") reopen();
    // hidden pages have zero width — repaint their trackbars now visible
    requestAnimationFrame(function () { repaintTracks(document.getElementById(id)); });
  }
  tabs.forEach(function (t) {
    t.addEventListener("click", function () { goto(t.dataset.tab); });
  });
  var startmenu = document.getElementById("startmenu");
  function hideStart() { startmenu.style.display = "none"; }
  document.querySelectorAll("[data-goto]").forEach(function (el) {
    el.addEventListener("click", function () {
      var id = el.getAttribute("data-goto");
      if (id === "Main" || id === "Get Script") {
        goto(id === "Main" ? "p-main" : "p-get");
        if (win.style.display === "none") reopen();
      } else goto(id);
      hideStart();
    });
  });

  /* ---------- window z-order: last clicked window is on top ---------- */
  var topZ = 8000;
  function bringToFront(el) { topZ += 1; el.style.zIndex = topZ; }
  var winPairs = [
    [document.getElementById("win"), document.getElementById("titlebar")],
    [document.getElementById("paintWin"), document.getElementById("paintTitle")],
    [document.getElementById("gamesWin"), document.getElementById("gamesTitle")],
    [document.getElementById("noteWin"), document.getElementById("noteTitle")],
    [document.getElementById("memoWin"), document.getElementById("memoTitle")],
    [document.getElementById("mineWin"), document.getElementById("mineTitle")],
    [document.getElementById("wallWin"), document.getElementById("wallTitle")]
  ];
  function focusWin(root) {
    bringToFront(root);
    winPairs.forEach(function (p) {
      p[1].classList.toggle("inactive", p[0] !== root);
    });
  }
  winPairs.forEach(function (p) {
    p[0].addEventListener("pointerdown", function () { focusWin(p[0]); }, true);
  });
  msghost.addEventListener("pointerdown", function (e) {
    var b = e.target.closest ? e.target.closest(".msgbox") : null;
    if (b) bringToFront(b);
  }, true);

  /* ---------- caption buttons: min / max / close ---------- */
  var rolled = false, maximized = false, preRect = null;
  document.getElementById("btnMin").addEventListener("click", function () {
    rolled = !rolled; win.classList.toggle("rolled", rolled);
  });
  // double-click title toggles maximize, like Win95
  titlebar.addEventListener("dblclick", toggleMax);
  document.getElementById("btnMax").addEventListener("click", toggleMax);
  function toggleMax() {
    maximized = !maximized;
    if (maximized) {
      preRect = { left: win.style.left, top: win.style.top, width: win.style.width, height: win.style.height, transform: win.style.transform };
      win.style.left = "0"; win.style.top = "0"; win.style.transform = "none";
      win.style.width = "100vw"; win.style.height = "calc(100vh - 30px)";
    } else if (preRect) {
      win.style.left = preRect.left; win.style.top = preRect.top;
      win.style.transform = preRect.transform;
      win.style.width = preRect.width; win.style.height = preRect.height;
    }
    refreshSize();
  }
  document.getElementById("btnClose").addEventListener("click", function () {
    // zoom shut, then a message box offering to reopen
    var r = win.getBoundingClientRect();
    var cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    var steps = 3, i = steps;
    zoom.style.display = "block";
    (function tick() {
      var t = i / steps;
      var w = Math.max(r.width * (0.2 + 0.8 * t), 4), h = Math.max(r.height * (0.2 + 0.8 * t), 4);
      zoom.style.left = (cx - w / 2) + "px"; zoom.style.top = (cy - h / 2) + "px";
      zoom.style.width = w + "px"; zoom.style.height = h + "px";
      if (--i >= 0) setTimeout(tick, 16);
      else {
        zoom.style.display = "none"; win.style.display = "none";
        notify("Aether Hub", "Window closed. Click the desktop icon to re-open.", "info", 6);
      }
    })();
  });
  function reopen() {
    win.style.display = "flex"; zoomOpen();
  }
  document.getElementById("icons").addEventListener("click", function (e) {
    var d = e.target.closest ? e.target.closest(".dicon") : null;
    if (!d) return;
    iconAction(d.getAttribute("data-act"));
  });
  function iconAction(act) {
    if (act === "main") {
      if (win.style.display === "none") reopen(); else goto("p-main");
    } else if (act === "get") goto("p-get");
    else if (act === "discord") copyText(INVITE, "Discord invite copied.");
    else if (act === "paint") openPaint();
    else if (act === "games") openGames();
    else if (act === "notepad") openNote();
    else if (act === "mines") openMine();
    else if (act === "memo") openMemo();
    else if (act === "display") { hideStart(); wallWin.style.display = "block"; focusWin(wallWin); }
  }
  document.getElementById("taskwin").addEventListener("click", function () {
    if (win.style.display === "none") reopen();
    else if (rolled) { rolled = false; win.classList.remove("rolled"); }
  });

  /* ---------- drag by title bar ---------- */
  (function () {
    var sx, sy, ox, oy, drag = false;
    titlebar.addEventListener("mousedown", function (e) {
      if (maximized || e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = win.getBoundingClientRect();
      win.style.transform = "none"; win.style.left = r.left + "px"; win.style.top = r.top + "px";
      ox = r.left; oy = r.top; e.preventDefault();
    });
    window.addEventListener("mousemove", function (e) {
      if (!drag) return;
      win.style.left = (ox + e.clientX - sx) + "px";
      win.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    window.addEventListener("mouseup", function () { drag = false; });
  })();

  /* ---------- resize grip ---------- */
  (function () {
    var grip = document.getElementById("grip"), sx, sy, sw, sh, rs = false;
    grip.addEventListener("mousedown", function (e) {
      if (maximized) return;
      rs = true; sx = e.clientX; sy = e.clientY;
      var r = win.getBoundingClientRect(); sw = r.width; sh = r.height;
      win.style.transform = "none"; win.style.left = r.left + "px"; win.style.top = r.top + "px";
      e.preventDefault();
    });
    window.addEventListener("mousemove", function (e) {
      if (!rs) return;
      win.style.width = Math.max(sw + e.clientX - sx, 420) + "px";
      win.style.height = Math.max(sh + e.clientY - sy, 300) + "px";
      refreshSize();
    });
    window.addEventListener("mouseup", function () { rs = false; });
  })();
  function refreshSize() {
    var r = win.getBoundingClientRect();
    sizepanel.textContent = Math.round(r.width) + " x " + Math.round(r.height);
    repaintTracks(document.querySelector(".page.on") || document);
  }
  window.addEventListener("resize", refreshSize);

  /* ---------- yellow tooltips + status-bar hints ---------- */
  var tipTimer = null;
  document.addEventListener("mouseover", function (e) {
    var el = e.target.closest ? e.target.closest("[data-hint]") : null;
    if (!el) return;
    hintpanel.textContent = el.getAttribute("data-hint");
    clearTimeout(tipTimer);
    if (!tipsOn) { tip.style.display = "none"; return; }
    var x = e.clientX, y = e.clientY, txt = el.getAttribute("data-hint");
    tipTimer = setTimeout(function () {
      tip.textContent = txt;
      tip.style.display = "block";
      tip.style.left = Math.min(x + 12, window.innerWidth - 270) + "px";
      tip.style.top = (y + 18) + "px";
    }, 700);
  });
  document.addEventListener("mouseout", function (e) {
    var el = e.target.closest ? e.target.closest("[data-hint]") : null;
    if (!el) return;
    clearTimeout(tipTimer); tip.style.display = "none";
    if (!document.querySelector("[data-hint]:hover")) hintpanel.textContent = DEFAULT_HINT;
  });
  document.addEventListener("mousedown", function () { clearTimeout(tipTimer); tip.style.display = "none"; });

  /* ---------- message-box notifications (cascading) ---------- */
  var notifN = 0;
  function notify(title, text, kind, dur) {
    if (!notifOn) return;
    kind = kind || "info"; dur = dur == null ? 4 : dur;
    var off = (notifN++ % 5) * 24;
    var box = document.createElement("div");
    box.className = "msgbox";
    var col = kind === "error" ? "#c80000" : kind === "warn" ? "#b89b00" : "#000080";
    var glyph = kind === "error" ? "\u2715" : kind === "warn" ? "!" : "i";
    box.style.left = "calc(50% - 150px + " + off + "px)";
    box.style.top = "calc(46% + " + off + "px)";
    box.innerHTML = '<div class="mbar"></div><div class="mrow"><div class="mic"></div><p></p></div>';
    box.querySelector(".mbar").textContent = title || "Paint";
    var mic = box.querySelector(".mic"); mic.style.background = col; mic.textContent = glyph;
    box.querySelector("p").textContent = text || "";
    var ok = document.createElement("button");
    ok.className = "btn mok"; ok.textContent = "OK";
    ok.style.minWidth = "76px";
    box.appendChild(ok);
    msghost.appendChild(box);
    bringToFront(box);
    (function () {
      var mbar = box.querySelector(".mbar");
      mbar.style.cursor = "move";
      mbar.addEventListener("pointerdown", function (e) {
        var r = box.getBoundingClientRect(),
            ox = e.clientX - r.left, oy = e.clientY - r.top;
        box.style.left = r.left + "px"; box.style.top = r.top + "px";
        function mv(ev) { box.style.left = (ev.clientX - ox) + "px"; box.style.top = (ev.clientY - oy) + "px"; }
        function up() { window.removeEventListener("pointermove", mv); window.removeEventListener("pointerup", up); }
        window.addEventListener("pointermove", mv);
        window.addEventListener("pointerup", up);
        e.preventDefault();
      });
    })();
    var done = false;
    function close() { if (done) return; done = true; box.remove(); }
    ok.addEventListener("click", close);
    setTimeout(close, dur * 1000);
  }

  /* ---------- checkboxes ---------- */
  document.querySelectorAll(".check").forEach(function (c) {
    c.addEventListener("click", function () {
      c.classList.toggle("on");
      if (typeof c._onFlip === "function") c._onFlip(c.classList.contains("on"));
    });
  });

  /* ---------- radios (scoped to their group/page) ---------- */
  document.querySelectorAll(".radio").forEach(function (r) {
    r.addEventListener("click", function () {
      var scope = r.closest(".group") || r.closest(".page") || document;
      scope.querySelectorAll(".radio").forEach(function (x) { x.classList.remove("on"); });
      r.classList.add("on");
    });
  });
  function radioVal(scope) {
    var on = scope.querySelector(".radio.on");
    return on ? on.textContent.trim() : "";
  }

  /* ---------- trackbars (pointer events; repaint when shown) ---------- */
  function paintTrack(t) {
    var rail = t.querySelector(".rail");
    if (!rail || rail.clientWidth < 40) return; // hidden tab: skip, goto() repaints
    var min = +t.dataset.min, max = +t.dataset.max, val = t._val;
    var rel = (val - min) / Math.max(max - min, 1e-9);
    var w = rail.clientWidth - 14;
    t.querySelector(".thumb").style.left = (2 + rel * w) + "px";
    t.querySelector(".val").textContent = Math.round(val);
  }
  function setupTrack(t) {
    if (t._setup) return; t._setup = true;
    t._val = +t.dataset.val;
    t._get = function () { return t._val; };
    t._set = function (v) {
      t._val = Math.min(Math.max(Math.round(v), +t.dataset.min), +t.dataset.max);
      paintTrack(t);
    };
    var rail = t.querySelector(".rail"), drag = false;
    function fromEvent(e) {
      var r = rail.getBoundingClientRect();
      var rel = Math.min(Math.max((e.clientX - r.left - 2) / Math.max(r.width - 14, 1), 0), 1);
      t._val = Math.round(+t.dataset.min + rel * (+t.dataset.max - +t.dataset.min));
      paintTrack(t);
    }
    rail.addEventListener("pointerdown", function (e) {
      drag = true;
      try { rail.setPointerCapture(e.pointerId); } catch (_) {}
      fromEvent(e); e.preventDefault();
    });
    rail.addEventListener("pointermove", function (e) { if (drag) fromEvent(e); });
    rail.addEventListener("pointerup", function () { drag = false; });
    rail.addEventListener("pointercancel", function () { drag = false; });
  }
  document.querySelectorAll(".track").forEach(setupTrack);
  function repaintTracks(root) {
    (root || document).querySelectorAll(".track").forEach(paintTrack);
  }

  /* ---------- comboboxes (list opens under the field) ---------- */
  function setupCombo(btn, label, opts, onChange) {
    function set(o) {
      label.textContent = o; label._value = o;
      if (typeof onChange === "function") onChange(o);
    }
    function open() {
      if (comboList.style.display === "block") { comboList.style.display = "none"; return; }
      var field = btn.closest(".cfield") || btn;
      var r = field.getBoundingClientRect();
      comboList.innerHTML = "";
      opts.forEach(function (o) {
        var d = document.createElement("div");
        d.textContent = o;
        d.addEventListener("click", function (ev) {
          ev.stopPropagation(); set(o); comboList.style.display = "none";
        });
        comboList.appendChild(d);
      });
      comboList.style.display = "block";
      comboList.style.left = Math.max(Math.min(r.left, window.innerWidth - r.width - 4), 4) + "px";
      comboList.style.top = (r.bottom + 2) + "px";
      comboList.style.minWidth = r.width + "px";
    }
    btn.addEventListener("click", function (e) { e.stopPropagation(); open(); });
    var field = btn.closest(".cfield");
    if (field) field.addEventListener("click", function (e) { e.stopPropagation(); open(); });
    label._combo = {
      get: function () { return label._value == null ? label.textContent.trim() : label._value; },
      set: set
    };
    label._value = label.textContent.trim();
  }
  document.addEventListener("click", function () { comboList.style.display = "none"; });

  var moveLabel = document.getElementById("moveVal"),
      modeLabel = document.getElementById("modeVal");
  setupCombo(document.getElementById("moveBtn"), moveLabel,
    ["Tween Glide", "Fly Glide", "Safe Walk", "Anti Guard"]);
  setupCombo(document.getElementById("modeBtn"), modeLabel,
    ["Pencil", "Brush", "Airbrush"], paintState);
  var glideTrack = document.getElementById("glideTrack"),
      brushTrack = document.getElementById("brushTrack"),
      paintStatus = document.getElementById("paintStatus");
  function paintState() {
    if (paintStatus) paintStatus.textContent =
      modeLabel._combo.get() + " " + Math.round(brushTrack._get()) + " — click and drag";
  }
  brushTrack._onChange = paintState;

  /* ---------- keybind ---------- */
  var keyEl = document.getElementById("demoKey"), listening = false;
  keyEl.addEventListener("click", function () { listening = true; keyEl.textContent = "Press a key…"; });
  document.addEventListener("keydown", function (e) {
    if (e.key === "F1") { e.preventDefault(); goto("p-faq"); return; }
    if (listening) {
      listening = false;
      keyEl.textContent = e.key.length === 1 ? e.key.toUpperCase() : e.key;
      notify("Aether Hub", "Keybind set to " + keyEl.textContent + ".", "info", 2);
      say("Keybind: " + keyEl.textContent + ".");
    }
  });

  /* ---------- PAINT CANVAS — every demo control drives this ---------- */
  var canvas = document.getElementById("paint"),
      ctx = canvas.getContext("2d"),
      BG = "#ffffff",
      paintColor = "#000000",
      shapeArmed = null; // 'rect' | 'oval' | null
  ctx.fillStyle = BG; ctx.fillRect(0, 0, canvas.width, canvas.height);
  ctx.lineCap = "round"; ctx.lineJoin = "round";

  var COLORS = ["#000000", "#808080", "#c0c0c0", "#ffffff",
                "#000080", "#0000ff", "#008000", "#00ff00",
                "#008080", "#00ffff", "#800000", "#ff0000",
                "#800080", "#ff00ff", "#808000", "#ffff00"];
  var pal = document.getElementById("pal");
  COLORS.forEach(function (c, i) {
    var s = document.createElement("button");
    s.className = "swatch" + (i === 0 ? " sel" : "");
    s.style.background = c;
    s.setAttribute("aria-label", c);
    s.addEventListener("click", function () {
      paintColor = c;
      pal.querySelectorAll(".swatch").forEach(function (x) { x.classList.remove("sel"); });
      s.classList.add("sel");
    });
    pal.appendChild(s);
  });

  function canvasPos(e) {
    var r = canvas.getBoundingClientRect();
    return {
      x: (e.clientX - r.left) * canvas.width / r.width,
      y: (e.clientY - r.top) * canvas.height / r.height
    };
  }
  function brushSize() { return brushTrack._get(); }

  var drawing = false, last = null, snap = null, sprayTimer = null, sprayAt = null;

  function stopSpray() { if (sprayTimer) { clearInterval(sprayTimer); sprayTimer = null; } }
  function spray() {
    var r = Math.max(brushSize() / 2, 2);
    ctx.fillStyle = paintColor;
    for (var i = 0; i < 10; i++) {
      var a = Math.random() * Math.PI * 2, d = Math.sqrt(Math.random()) * r;
      ctx.fillRect(sprayAt.x + Math.cos(a) * d, sprayAt.y + Math.sin(a) * d, 1.5, 1.5);
    }
  }

  canvas.addEventListener("pointerdown", function (e) {
    drawing = true;
    try { canvas.setPointerCapture(e.pointerId); } catch (_) {}
    var p = canvasPos(e);
    if (shapeArmed) {
      snap = ctx.getImageData(0, 0, canvas.width, canvas.height);
      last = p;
    } else if (modeLabel._combo.get() === "Airbrush") {
      sprayAt = p; spray(); stopSpray();
      sprayTimer = setInterval(spray, 40);
    } else {
      ctx.strokeStyle = paintColor; ctx.fillStyle = paintColor;
      ctx.lineWidth = modeLabel._combo.get() === "Pencil" ? 1 : brushSize();
      ctx.beginPath(); ctx.moveTo(p.x, p.y); ctx.lineTo(p.x + 0.1, p.y + 0.1); ctx.stroke();
      last = p;
    }
    e.preventDefault();
  });
  canvas.addEventListener("pointermove", function (e) {
    if (!drawing) return;
    var p = canvasPos(e);
    if (shapeArmed && snap) {
      ctx.putImageData(snap, 0, 0);
      drawShape(shapeArmed, last, p, true);
    } else if (modeLabel._combo.get() === "Airbrush") {
      sprayAt = p;
    } else if (last) {
      ctx.strokeStyle = paintColor;
      ctx.lineWidth = modeLabel._combo.get() === "Pencil" ? 1 : brushSize();
      ctx.beginPath(); ctx.moveTo(last.x, last.y); ctx.lineTo(p.x, p.y); ctx.stroke();
      last = p;
    }
  });
  function endDraw() {
    if (!drawing) return;
    drawing = false; last = null; snap = null; stopSpray();
    if (shapeArmed) disarmShapes();
  }
  canvas.addEventListener("pointerup", endDraw);
  canvas.addEventListener("pointercancel", endDraw);

  function drawShape(kind, a, b, preview) {
    var fill = radioVal(document.getElementById("paintWin"));
    var x = Math.min(a.x, b.x), y = Math.min(a.y, b.y),
        w = Math.abs(a.x - b.x), h = Math.abs(a.y - b.y);
    ctx.beginPath();
    if (kind === "rect") ctx.rect(x, y, Math.max(w, 1), Math.max(h, 1));
    else ctx.ellipse(x + w / 2, y + h / 2, Math.max(w / 2, 1), Math.max(h / 2, 1), 0, 0, Math.PI * 2);
    if (fill === "Solid") { ctx.fillStyle = paintColor; ctx.fill(); }
    else if (fill === "Outline") {
      ctx.strokeStyle = paintColor; ctx.lineWidth = Math.max(brushSize(), 1); ctx.stroke();
    } else { ctx.fillStyle = BG; ctx.fill(); } // None = knock out to background
    if (preview) return;
  }

  var toolRect = document.getElementById("toolRect"),
      toolOval = document.getElementById("toolOval");
  function disarmShapes() {
    shapeArmed = null;
    toolRect.classList.remove("armed"); toolOval.classList.remove("armed");
  }
  function armShape(kind, btn) {
    if (shapeArmed === kind) { disarmShapes(); return; }
    disarmShapes(); shapeArmed = kind; btn.classList.add("armed");
    hintpanel.textContent = "Drag on the canvas to draw the " + kind + ".";
  }
  toolRect.addEventListener("click", function () { armShape("rect", toolRect); });
  toolOval.addEventListener("click", function () { armShape("oval", toolOval); });

  document.getElementById("btnClear").addEventListener("click", function () {
    ctx.fillStyle = BG; ctx.fillRect(0, 0, canvas.width, canvas.height);
    notify("Paint", "Canvas cleared.", "info", 2);
  });
  document.getElementById("btnSave").addEventListener("click", function () {
    var name = (document.getElementById("demoName").value || "untitled")
      .replace(/[^\w\- ]+/g, "").trim() || "untitled";
    canvas.toBlob(function (blob) {
      var a = document.createElement("a");
      a.href = URL.createObjectURL(blob);
      a.download = name + ".png";
      document.body.appendChild(a); a.click(); a.remove();
      setTimeout(function () { URL.revokeObjectURL(a.href); }, 4000);
    });
    notify("Paint", "Saved to Desktop.", "info", 4);
  });
  document.getElementById("demoName").addEventListener("keydown", function (e) {
    if (e.key === "Enter") document.getElementById("btnSave").click();
  });

  document.getElementById("demoBtn").addEventListener("click", function () {
    // stamp a smiley in the current colour
    var x = 60 + Math.random() * (canvas.width - 120),
        y = 60 + Math.random() * (canvas.height - 120),
        r = 12 + Math.min(brushSize(), 32);
    ctx.strokeStyle = paintColor; ctx.fillStyle = paintColor; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
    ctx.beginPath(); ctx.arc(x - r * 0.35, y - r * 0.2, r * 0.12, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(x + r * 0.35, y - r * 0.2, r * 0.12, 0, Math.PI * 2); ctx.fill();
    ctx.beginPath(); ctx.arc(x, y + r * 0.1, r * 0.55, 0.2 * Math.PI, 0.8 * Math.PI); ctx.stroke();
    notify("Aether Hub", "Button pressed: stamped a smiley.", "info", 2);
  });
  document.getElementById("demoNotify").addEventListener("click", function () {
    notify("Paint", "Saved to Desktop.", "info", 4);
  });
  document.getElementById("aaToggle")._onFlip = function (on) {
    ctx.imageSmoothingEnabled = on;
  };
  ctx.imageSmoothingEnabled = true;

  /* ---------- SCRIPTS TAB: persistent config (like SaveConfig/LoadConfig) ---------- */
  var CFG_KEY = "aetherhub_cfg",
      cfgStatus = document.getElementById("cfgStatus");
  function readCfg() {
    var o = {};
    document.querySelectorAll("#p-scripts .check[data-flag]").forEach(function (c) {
      o[c.getAttribute("data-flag")] = c.classList.contains("on");
    });
    o.glide = glideTrack._get();
    o.move = moveLabel._combo.get();
    return o;
  }
  function applyCfg(o) {
    if (!o || typeof o !== "object") return false;
    document.querySelectorAll("#p-scripts .check[data-flag]").forEach(function (c) {
      c.classList.toggle("on", o[c.getAttribute("data-flag")] !== false);
    });
    if (typeof o.glide === "number") glideTrack._set(o.glide);
    if (typeof o.move === "string") moveLabel._combo.set(o.move);
    return true;
  }
  document.getElementById("cfgSave").addEventListener("click", function () {
    try {
      localStorage.setItem(CFG_KEY, JSON.stringify(readCfg()));
      var t = new Date();
      cfgStatus.textContent = "Config: saved " + t.toLocaleTimeString() + " in this browser.";
      notify("Aether Hub", "Config saved.", "info", 2);
    } catch (e) {
      notify("Aether Hub", "Could not save config: " + e.message, "error", 4);
    }
  });
  document.getElementById("cfgLoad").addEventListener("click", function () {
    var raw = null;
    try { raw = localStorage.getItem(CFG_KEY); } catch (e) {}
    if (raw && applyCfg(JSON.parse(raw))) {
      cfgStatus.textContent = "Config: loaded from this browser.";
      notify("Aether Hub", "Config loaded.", "info", 2);
    } else {
      notify("Aether Hub", "No saved config found — press Save Config first.", "warn", 4);
    }
  });
  // silent auto-load so refreshes keep your setup
  try {
    var saved = localStorage.getItem(CFG_KEY);
    if (saved) {
      applyCfg(JSON.parse(saved));
      cfgStatus.textContent = "Config: restored from this browser.";
    }
  } catch (e) {}

  /* ---------- UI DEMO tab: every control reports to Output ---------- */
  var demoOut = document.getElementById("demoOut");
  function say(s) { demoOut.textContent = s; }
  document.getElementById("demoBtnTab").addEventListener("click", function () { say("Button: callback fired."); });
  document.getElementById("demoToggle")._onFlip = function (on) { say("Toggle: " + (on ? "ON" : "OFF")); };
  document.getElementById("aaToggleTab")._onFlip = function (on) { say("Group toggle: " + (on ? "ON" : "OFF")); };
  document.getElementById("demoSlider")._onChange = function (v) { say("Slider: " + Math.round(v)); };
  setupCombo(document.getElementById("demoModeBtn"), document.getElementById("demoModeVal"),
    ["Pencil", "Brush", "Airbrush"], function (o) { say("Dropdown: " + o); });
  document.querySelectorAll("#p-demo .radio").forEach(function (r) {
    r.addEventListener("click", function () { say("Radio: " + r.textContent.trim()); });
  });
  document.getElementById("demoNameTab").addEventListener("keydown", function (e) {
    if (e.key === "Enter") say("TextInput: \"" + this.value + "\"");
  });

  /* ---------- copy buttons ---------- */
  function copyText(s, okMsg) {
    function done() { notify("Aether Hub", okMsg || "Copied to clipboard.", "info", 3); }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(s).then(done, function () { fallback(); });
    } else fallback();
    function fallback() {
      var ta = document.createElement("textarea");
      ta.value = s; document.body.appendChild(ta); ta.select();
      try { document.execCommand("copy"); done(); } catch (e) { notify("Aether Hub", "Copy failed — select the text manually.", "error", 4); }
      ta.remove();
    }
  }
  var LOADSTRING = document.getElementById("loadstring").textContent.trim();
  document.getElementById("ctaCopy").addEventListener("click", function () { copyText(LOADSTRING, "Loadstring copied. Paste it into your executor."); });
  document.getElementById("ctaCopy2").addEventListener("click", function () { copyText(LOADSTRING, "Loadstring copied. Paste it into your executor."); });
  var INVITE = "https://discord.gg/SK7mHYVW2P";
  document.getElementById("ctaDiscord").addEventListener("click", function () { copyText(INVITE, "Discord invite copied."); });
  // any button with data-copy copies its URL (Loader / UILib / per-game file)
  document.querySelectorAll("[data-copy]").forEach(function (b) {
    b.addEventListener("click", function () { copyText(b.getAttribute("data-copy"), "File URL copied."); });
  });

  /* ---------- Paint app window ---------- */
  var paintWin = document.getElementById("paintWin"),
      taskPaint = document.getElementById("taskPaint");
  function openPaint() {
    paintWin.style.display = "flex";
    taskPaint.style.display = "block";
    focusWin(paintWin);
    requestAnimationFrame(function () { repaintTracks(paintWin); });
  }
  function hidePaint() { paintWin.style.display = "none"; taskPaint.style.display = "none"; }
  document.getElementById("paintClose").addEventListener("click", hidePaint);
  document.getElementById("paintMin").addEventListener("click", function () {
    paintWin.style.display = "none";
  });
  taskPaint.addEventListener("click", function () {
    paintWin.style.display = paintWin.style.display === "none" ? "flex" : "none";
  });
  document.getElementById("openPaint").addEventListener("click", openPaint);
  (function () {
    var bar = document.getElementById("paintTitle"), sx, sy, ox, oy, drag = false;
    bar.addEventListener("pointerdown", function (e) {
      if (e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = paintWin.getBoundingClientRect();
      paintWin.style.transform = "none";
      paintWin.style.left = r.left + "px"; paintWin.style.top = r.top + "px";
      ox = r.left; oy = r.top;
      try { bar.setPointerCapture(e.pointerId); } catch (_) {}
      e.preventDefault();
    });
    bar.addEventListener("pointermove", function (e) {
      if (!drag) return;
      paintWin.style.left = (ox + e.clientX - sx) + "px";
      paintWin.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    bar.addEventListener("pointerup", function () { drag = false; });
    bar.addEventListener("pointercancel", function () { drag = false; });
  })();

  /* ---------- Games app window + live network stats ---------- */  var gamesWin = document.getElementById("gamesWin"),
      taskGames = document.getElementById("taskGames"),
      netState = document.getElementById("netState"),
      statTotal = document.getElementById("statTotal"),
      STATS_URL = ""; // paste your counter worker URL + "/stats", e.g. https://aether-counter.<you>.workers.dev/stats
  function openGames() {
    gamesWin.style.display = "flex";
    taskGames.style.display = "block";
    focusWin(gamesWin);
    fetchStats();
  }
  function hideGames() { gamesWin.style.display = "none"; taskGames.style.display = "none"; }
  document.getElementById("gamesClose").addEventListener("click", hideGames);
  document.getElementById("gamesMin").addEventListener("click", function () {
    gamesWin.style.display = "none";
  });
  taskGames.addEventListener("click", function () {
    gamesWin.style.display = gamesWin.style.display === "none" ? "flex" : "none";
  });
  document.getElementById("openGames").addEventListener("click", openGames);
  // game cards open their Roblox page (discover search — no hardcoded IDs)
  var GAME_LINKS = {
    steal: "https://www.roblox.com/de/games/107778070777162/Steal-An-Egg"
  };
  document.querySelectorAll("[data-game]").forEach(function (card) {
    card.addEventListener("click", function () {
      var url = GAME_LINKS[card.getAttribute("data-game")];
      if (url) window.open(url, "_blank");
      else notify("Aether Hub", "This slot is not out yet.", "warn", 3);
    });
  });
  (function () {
    var bar = document.getElementById("gamesTitle"), sx, sy, ox, oy, drag = false;
    bar.addEventListener("pointerdown", function (e) {
      if (e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = gamesWin.getBoundingClientRect();
      gamesWin.style.transform = "none";
      gamesWin.style.left = r.left + "px"; gamesWin.style.top = r.top + "px";
      ox = r.left; oy = r.top;
      try { bar.setPointerCapture(e.pointerId); } catch (_) {}
      e.preventDefault();
    });
    bar.addEventListener("pointermove", function (e) {
      if (!drag) return;
      gamesWin.style.left = (ox + e.clientX - sx) + "px";
      gamesWin.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    bar.addEventListener("pointerup", function () { drag = false; });
    bar.addEventListener("pointercancel", function () { drag = false; });
  })();
  function fmt(n) { return (+n || 0).toLocaleString("en-US"); }
  var TOTAL_URL = "https://abacus.jasoncameron.dev/get/aetherhub/executions";
  function fetchStats() {
    fetch(TOTAL_URL, { cache: "no-store" }).then(function (r) { return r.json(); }).then(function (d) {
      statTotal.textContent = fmt(d.value);
    }).catch(function () {
      statTotal.textContent = "···";
    });
    if (!STATS_URL) {
      netState.textContent = "Total executions live — deploy counter-worker.js for the online count.";
      return;
    }
    fetch(STATS_URL, { cache: "no-store" }).then(function (r) { return r.json(); }).then(function (d) {
      netState.textContent = "Updating now — refreshed " + new Date().toLocaleTimeString() + ".";
    }).catch(function () {
      netState.textContent = "Online counter unreachable — check the worker URL.";
    });
  }
  setInterval(function () {
    if (gamesWin.style.display !== "none") fetchStats();
  }, 30000);

  /* ---------- Display Settings tab: name + desktop options ---------- */
  var SET_KEY = "aether_settings",
      HERO_TEXT = "MS Paint edition — Windows 95 styled Roblox script hub. Instant everything, just like 1995.",
      setNameEl = document.getElementById("setName"),
      heroSub = document.getElementById("heroSub"),
      smUser = document.getElementById("smUser");
  function applyName() {
    var n = (setNameEl.value || "").trim();
    heroSub.textContent = HERO_TEXT + (n ? " Registered to " + n + "." : "");
    smUser.textContent = "Aether — " + (n || "guest");
  }
  function currentSettings() {
    function isOn(id) { return document.getElementById(id).classList.contains("on"); }
    return {
      name: setNameEl.value || "",
      tips: isOn("setTips"), notif: isOn("setNotif"),
      dither: isOn("setDither"), seconds: isOn("setSeconds")
    };
  }
  function saveSettings() {
    try { localStorage.setItem(SET_KEY, JSON.stringify(currentSettings())); } catch (e) {}
  }
  function applySettings(s) {
    tipsOn = s.tips !== false;
    notifOn = s.notif !== false;
    clockSeconds = s.seconds === true;
    document.body.classList.toggle("nodither", s.dither === false);
    setNameEl.value = s.name || "";
    applyName();
    [["setTips", tipsOn], ["setNotif", notifOn],
     ["setDither", s.dither !== false], ["setSeconds", clockSeconds]].forEach(function (p) {
      document.getElementById(p[0]).classList.toggle("on", p[1]);
    });
  }
  document.getElementById("setTips")._onFlip = function (on) { tipsOn = on; saveSettings(); };
  document.getElementById("setNotif")._onFlip = function (on) { notifOn = on; saveSettings(); };
  document.getElementById("setDither")._onFlip = function (on) {
    document.body.classList.toggle("nodither", !on); saveSettings();
  };
  document.getElementById("setSeconds")._onFlip = function (on) { clockSeconds = on; saveSettings(); clock(); };
  setNameEl.addEventListener("input", function () { applyName(); saveSettings(); });
  var wallTabBg = document.getElementById("wallTabBg"),
      wallTabSet = document.getElementById("wallTabSet"),
      wallPaneBg = document.getElementById("wallPaneBg"),
      wallPaneSet = document.getElementById("wallPaneSet");
  wallTabBg.addEventListener("click", function () {
    wallTabBg.classList.add("on"); wallTabSet.classList.remove("on");
    wallPaneBg.style.display = "block"; wallPaneSet.style.display = "none";
  });
  wallTabSet.addEventListener("click", function () {
    wallTabSet.classList.add("on"); wallTabBg.classList.remove("on");
    wallPaneSet.style.display = "block"; wallPaneBg.style.display = "none";
  });
  try {
    var savedSet = localStorage.getItem(SET_KEY);
    if (savedSet) applySettings(JSON.parse(savedSet));
    else applySettings({});
  } catch (e) { applySettings({}); }

  /* ---------- Notepad app (Changelogs.txt, downloads on Save) ---------- */
  var noteWin = document.getElementById("noteWin"),
      taskNote = document.getElementById("taskNote"),
      noteArea = document.getElementById("noteArea"),
      noteStatus = document.getElementById("noteStatus"),
      NOTE_KEY = "aether_note",
      NOTE_DEFAULT = "Changelogs.txt — Aether Hub\r\n---------------------------\r\n[2.0] Win95 Paint edition\r\n- Multi-game Loader (auto-detect)\r\n- Live network stats\r\n- Paint, Games, Display, Notepad apps\r\n\r\n[1.0] Violet private build\r\n- Steal an Egg auto-steal\r\n";
  function openNote() {
    noteWin.style.display = "flex";
    taskNote.style.display = "block";
    focusWin(noteWin);
  }
  function hideNote() { noteWin.style.display = "none"; taskNote.style.display = "none"; }
  document.getElementById("noteClose").addEventListener("click", hideNote);
  document.getElementById("noteMin").addEventListener("click", function () {
    noteWin.style.display = "none";
  });
  taskNote.addEventListener("click", function () {
    noteWin.style.display = noteWin.style.display === "none" ? "flex" : "none";
    if (noteWin.style.display !== "none") focusWin(noteWin);
  });
  function noteStat() {
    var v = noteArea.value,
        ln = v === "" ? 1 : v.split("\n").length;
    noteStatus.textContent = "Ln " + ln + ", Ch " + v.length;
  }
  noteArea.value = NOTE_DEFAULT;
  noteStat();
  // drag by title bar
  (function () {
    var bar = document.getElementById("noteTitle"), sx, sy, ox, oy, drag = false;
    bar.addEventListener("pointerdown", function (e) {
      if (e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = noteWin.getBoundingClientRect();
      noteWin.style.transform = "none";
      noteWin.style.left = r.left + "px"; noteWin.style.top = r.top + "px";
      ox = r.left; oy = r.top;
      try { bar.setPointerCapture(e.pointerId); } catch (_) {}
      e.preventDefault();
    });
    bar.addEventListener("pointermove", function (e) {
      if (!drag) return;
      noteWin.style.left = (ox + e.clientX - sx) + "px";
      noteWin.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    bar.addEventListener("pointerup", function () { drag = false; });
    bar.addEventListener("pointercancel", function () { drag = false; });
  })();
  /* ---------- Notepad scratch app (Notes.txt, downloads on Save) ---------- */
  var memoWin = document.getElementById("memoWin"),
      taskMemo = document.getElementById("taskMemo"),
      memoArea = document.getElementById("memoArea"),
      memoStatus = document.getElementById("memoStatus"),
      MEMO_KEY = "aether_memo";
  function openMemo() {
    memoWin.style.display = "flex";
    taskMemo.style.display = "block";
    focusWin(memoWin);
  }
  function hideMemo() { memoWin.style.display = "none"; taskMemo.style.display = "none"; }
  document.getElementById("memoClose").addEventListener("click", hideMemo);
  document.getElementById("memoMin").addEventListener("click", function () {
    memoWin.style.display = "none";
  });
  taskMemo.addEventListener("click", function () {
    memoWin.style.display = memoWin.style.display === "none" ? "flex" : "none";
    if (memoWin.style.display !== "none") focusWin(memoWin);
  });
  function memoStat() {
    var v = memoArea.value,
        ln = v === "" ? 1 : v.split("\n").length;
    memoStatus.textContent = "Ln " + ln + ", Ch " + v.length;
  }
  try {
    var savedMemo = localStorage.getItem(MEMO_KEY);
    memoArea.value = savedMemo == null ? "" : savedMemo;
  } catch (e) { memoArea.value = ""; }
  memoStat();
  memoArea.addEventListener("input", function () {
    memoStat();
    try { localStorage.setItem(MEMO_KEY, memoArea.value); } catch (e) {}
  });
  (function () {
    var bar = document.getElementById("memoTitle"), sx, sy, ox, oy, drag = false;
    bar.addEventListener("pointerdown", function (e) {
      if (e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = memoWin.getBoundingClientRect();
      memoWin.style.transform = "none";
      memoWin.style.left = r.left + "px"; memoWin.style.top = r.top + "px";
      ox = r.left; oy = r.top;
      try { bar.setPointerCapture(e.pointerId); } catch (_) {}
      e.preventDefault();
    });
    bar.addEventListener("pointermove", function (e) {
      if (!drag) return;
      memoWin.style.left = (ox + e.clientX - sx) + "px";
      memoWin.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    bar.addEventListener("pointerup", function () { drag = false; });
    bar.addEventListener("pointercancel", function () { drag = false; });
  })();
  document.getElementById("memoSave").addEventListener("click", function () {
    var blob = new Blob([memoArea.value], { type: "text/plain" });
    var a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "Notes.txt";
    document.body.appendChild(a); a.click(); a.remove();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 4000);
    notify("Notepad", "Saved to Downloads.", "info", 3);
  });
  document.getElementById("memoClear").addEventListener("click", function () {
    memoArea.value = "";
    memoStat();
    try { localStorage.setItem(MEMO_KEY, ""); } catch (e) {}
  });

  /* ---------- Minesweeper app ---------- */
  var mineWin = document.getElementById("mineWin"),
      taskMine = document.getElementById("taskMine"),
      mineGrid = document.getElementById("mineGrid"),
      mineCount = document.getElementById("mineCount"),
      mineTime = document.getElementById("mineTime"),
      mineFace = document.getElementById("mineFace"),
      mineBest = document.getElementById("mineBest"),
      mineFlagBtn = document.getElementById("mineFlagMode"),
      MS = 9, MINES = 10,
      cells = [], mines = {}, revealedN = 0, flagN = 0,
      mineOver = false, mineFirst = true, mineTimer = 0, mineTick = null,
      flagMode = false, MINE_BEST = "aether_mine_best";
  function openMine() {
    mineWin.style.display = "flex";
    taskMine.style.display = "block";
    focusWin(mineWin);
  }
  function hideMine() { mineWin.style.display = "none"; taskMine.style.display = "none"; }
  document.getElementById("mineClose").addEventListener("click", hideMine);
  document.getElementById("mineMin").addEventListener("click", function () {
    mineWin.style.display = "none";
  });
  taskMine.addEventListener("click", function () {
    mineWin.style.display = mineWin.style.display === "none" ? "flex" : "none";
    if (mineWin.style.display !== "none") focusWin(mineWin);
  });
  (function () {
    var bar = document.getElementById("mineTitle"), sx, sy, ox, oy, drag = false;
    bar.addEventListener("pointerdown", function (e) {
      if (e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = mineWin.getBoundingClientRect();
      mineWin.style.transform = "none";
      mineWin.style.left = r.left + "px"; mineWin.style.top = r.top + "px";
      ox = r.left; oy = r.top;
      try { bar.setPointerCapture(e.pointerId); } catch (_) {}
      e.preventDefault();
    });
    bar.addEventListener("pointermove", function (e) {
      if (!drag) return;
      mineWin.style.left = (ox + e.clientX - sx) + "px";
      mineWin.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    bar.addEventListener("pointerup", function () { drag = false; });
    bar.addEventListener("pointercancel", function () { drag = false; });
  })();
  function pad3(n) { n = Math.max(Math.min(n, 999), -99); return ("00" + Math.abs(n)).slice(-3); }
  function showBest() {
    var b = null;
    try { b = localStorage.getItem(MINE_BEST); } catch (e) {}
    mineBest.textContent = "Best: " + (b == null ? "—" : b + "s");
  }
  function adj(r, c) {
    var n = 0;
    for (var dr = -1; dr <= 1; dr++) for (var dc = -1; dc <= 1; dc++) {
      if (!dr && !dc) continue;
      if (mines[(r + dr) + "," + (c + dc)]) n++;
    }
    return n;
  }
  function newMine() {
    mines = {}; revealedN = 0; flagN = 0;
    mineOver = false; mineFirst = true; mineTimer = 0;
    if (mineTick) { clearInterval(mineTick); mineTick = null; }
    mineCount.textContent = pad3(MINES);
    mineTime.textContent = pad3(0);
    mineFace.textContent = ":-)";
    mineGrid.innerHTML = "";
    cells = [];
    for (var r = 0; r < MS; r++) {
      cells[r] = [];
      for (var c = 0; c < MS; c++) {
        (function (rr, cc) {
          var b = document.createElement("button");
          b.className = "cell";
          b.addEventListener("click", function () { dig(rr, cc); });
          b.addEventListener("contextmenu", function (e) { e.preventDefault(); flag(rr, cc); });
          mineGrid.appendChild(b);
          cells[rr][cc] = b;
        })(r, c);
      }
    }
    showBest();
  }
  function startTimer() {
    mineTick = setInterval(function () {
      mineTimer++;
      mineTime.textContent = pad3(mineTimer);
    }, 1000);
  }
  function stopTimer() { if (mineTick) { clearInterval(mineTick); mineTick = null; } }
  function placeMines(safeR, safeC) {
    var placed = 0;
    while (placed < MINES) {
      var r = Math.floor(Math.random() * MS), c = Math.floor(Math.random() * MS);
      if ((r === safeR && c === safeC) || mines[r + "," + c]) continue;
      mines[r + "," + c] = true;
      placed++;
    }
  }
  function dig(r, c) {
    if (mineOver) return;
    if (flagMode) { flag(r, c); return; }
    var b = cells[r][c];
    if (b.classList.contains("open") || b.textContent === "⚑") return;
    if (mineFirst) { placeMines(r, c); mineFirst = false; startTimer(); }
    if (mines[r + "," + c]) return boom(b);
    flood(r, c);
    if (revealedN === MS * MS - MINES) return win();
  }
  function flood(r, c) {
    if (r < 0 || c < 0 || r >= MS || c >= MS) return;
    var b = cells[r][c];
    if (b.classList.contains("open") || b.textContent === "⚑") return;
    if (b.textContent === "⚑") flagN--;
    b.textContent = "";
    b.classList.add("open");
    revealedN++;
    var n = adj(r, c);
    if (n) { b.textContent = n; b.classList.add("n" + n); return; }
    for (var dr = -1; dr <= 1; dr++) for (var dc = -1; dc <= 1; dc++) {
      if (!dr && !dc) continue;
      flood(r + dr, c + dc);
    }
    mineCount.textContent = pad3(MINES - flagN);
  }
  function flag(r, c) {
    if (mineOver) return;
    var b = cells[r][c];
    if (b.classList.contains("open")) return;
    if (b.textContent === "⚑") { b.textContent = ""; flagN--; }
    else { b.textContent = "⚑"; flagN++; }
    mineCount.textContent = pad3(MINES - flagN);
  }
  function boom(b) {
    mineOver = true; stopTimer();
    mineFace.textContent = "X_X";
    for (var k in mines) {
      var p = k.split(","), cell = cells[+p[0]][+p[1]];
      if (!cell.classList.contains("open")) cell.textContent = "●";
    }
    b.classList.add("dead");
    notify("Minesweeper", "Boom! Face for a new game.", "error", 3);
  }
  function win() {
    mineOver = true; stopTimer();
    mineFace.textContent = "B-)";
    try {
      var b = localStorage.getItem(MINE_BEST);
      if (b == null || mineTimer < +b) {
        localStorage.setItem(MINE_BEST, String(mineTimer));
        showBest();
      }
    } catch (e) {}
    notify("Minesweeper", "Cleared in " + mineTimer + "s!", "info", 4);
  }
  mineFace.addEventListener("click", newMine);
  mineFlagBtn.addEventListener("click", function () {
    flagMode = !flagMode;
    mineFlagBtn.textContent = "Flag: " + (flagMode ? "ON" : "OFF");
    mineFlagBtn.classList.toggle("armed", flagMode);
  });
  mineGrid.addEventListener("pointerdown", function () {
    if (!mineOver) mineFace.textContent = ":-O";
  });
  mineGrid.addEventListener("pointerup", function () {
    if (!mineOver) mineFace.textContent = ":-)";
  });
  newMine();

  /* ---------- Start menu + clock ---------- */
  document.getElementById("startbtn").addEventListener("click", function (e) {
    e.stopPropagation();
    startmenu.style.display = startmenu.style.display === "block" ? "none" : "block";
  });
  document.addEventListener("click", function (e) {
    if (!startmenu.contains(e.target)) hideStart();
  });
  document.getElementById("smNotify").addEventListener("click", function () {
    hideStart(); notify("Aether Hub", "This is a message-box notification.", "info", 4);
  });
  function clock() {
    var d = new Date(), h = d.getHours(), m = ("0" + d.getMinutes()).slice(-2);
    var ap = h >= 12 ? "PM" : "AM"; h = h % 12 || 12;
    var t = h + ":" + m;
    if (clockSeconds) t += ":" + ("0" + d.getSeconds()).slice(-2);
    document.getElementById("clock").textContent = t + " " + ap;
  }
  clock(); setInterval(clock, 1000);

  /* ---------- wallpaper picker (saves to this browser) ---------- */
  var WALL_KEY = "aether_wall",
      WALLS = ["#008080", "#000080", "#000000", "#808080",
               "#c0c0c0", "#800000", "#008000", "#800080"],
      wallWin = document.getElementById("wallWin"),
      wallsEl = document.getElementById("walls");
  function applyWall(c) {
    document.body.style.background = c;
    wallsEl.querySelectorAll(".wall").forEach(function (w) {
      w.classList.toggle("sel", w.getAttribute("data-c") === c.toLowerCase());
    });
  }
  WALLS.forEach(function (c) {
    var b = document.createElement("button");
    b.className = "wall"; b.style.background = c; b.setAttribute("data-c", c);
    b.setAttribute("aria-label", "Wallpaper " + c);
    b.addEventListener("click", function () { applyWall(c); });
    wallsEl.appendChild(b);
  });
  function validHex(s) {
    s = (s || "").trim();
    if (s.charAt(0) !== "#") s = "#" + s;
    return /^#[0-9a-fA-F]{6}$/.test(s) ? s.toLowerCase() : null;
  }
  document.getElementById("wallApply").addEventListener("click", function () {
    var c = validHex(document.getElementById("wallCustom").value);
    if (c) applyWall(c);
    else notify("Display", "That is not a hex colour. Try e.g. #008080.", "warn", 3);
  });
  document.getElementById("wallCustom").addEventListener("keydown", function (e) {
    if (e.key === "Enter") document.getElementById("wallApply").click();
  });
  document.getElementById("wallSave").addEventListener("click", function () {
    try {
      localStorage.setItem(WALL_KEY, document.body.style.background || "#008080");
      notify("Display", "Wallpaper saved.", "info", 2);
    } catch (e) {
      notify("Display", "Could not save: " + e.message, "error", 4);
    }
    wallWin.style.display = "none";
  });
  document.getElementById("wallDefault").addEventListener("click", function () {
    try { localStorage.removeItem(WALL_KEY); localStorage.removeItem(WALL_IMG_KEY); } catch (e) {}
    applyWallImg(null);
    applyWall("#008080");
    notify("Display", "Back to Win95 teal.", "info", 2);
  });
  /* ---------- picture wallpaper: image URL or upload ---------- */
  var WALL_IMG_KEY = "aether_wall_img";
  function applyWallImg(src) {
    document.body.style.backgroundImage = src ? 'url("' + src + '")' : "";
    document.body.style.backgroundSize = src ? "cover" : "";
    document.body.style.backgroundPosition = src ? "center" : "";
  }
  function saveWallImg(src) {
    applyWallImg(src);
    try {
      if (src) localStorage.setItem(WALL_IMG_KEY, src);
      else localStorage.removeItem(WALL_IMG_KEY);
    } catch (e) {
      notify("Display", "Image applied, but too big to save — it will reset on reload.", "warn", 4);
      return;
    }
    if (src) notify("Display", "Picture wallpaper set.", "info", 2);
  }
  document.getElementById("wallUrlApply").addEventListener("click", function () {
    var u = document.getElementById("wallUrl").value.trim();
    if (!u) return;
    saveWallImg(u);
  });
  document.getElementById("wallUrl").addEventListener("keydown", function (e) {
    if (e.key === "Enter") document.getElementById("wallUrlApply").click();
  });
  document.getElementById("wallUploadBtn").addEventListener("click", function () {
    document.getElementById("wallUpload").click();
  });
  document.getElementById("wallUpload").addEventListener("change", function () {
    var f = this.files && this.files[0];
    if (!f) return;
    var r = new FileReader();
    r.onload = function () { saveWallImg(r.result); };
    r.readAsDataURL(f);
    this.value = "";
  });
  document.getElementById("wallImgClear").addEventListener("click", function () {
    saveWallImg(null);
    notify("Display", "Picture removed.", "info", 2);
  });
  try {
    var savedImg = localStorage.getItem(WALL_IMG_KEY);
    if (savedImg) applyWallImg(savedImg);
  } catch (e) {}
  document.getElementById("wallClose").addEventListener("click", function () {
    wallWin.style.display = "none";
  });
  document.getElementById("smWall").addEventListener("click", function () {
    hideStart();
    wallWin.style.display = wallWin.style.display === "block" ? "none" : "block";
    if (wallWin.style.display === "block") focusWin(wallWin);
  });
  // drag the picker by its title bar
  (function () {
    var bar = document.getElementById("wallTitle"), sx, sy, ox, oy, drag = false;
    bar.addEventListener("pointerdown", function (e) {
      if (e.target.classList.contains("capbtn")) return;
      drag = true; sx = e.clientX; sy = e.clientY;
      var r = wallWin.getBoundingClientRect();
      wallWin.style.transform = "none";
      wallWin.style.left = r.left + "px"; wallWin.style.top = r.top + "px";
      ox = r.left; oy = r.top; e.preventDefault();
    });
    window.addEventListener("pointermove", function (e) {
      if (!drag) return;
      wallWin.style.left = (ox + e.clientX - sx) + "px";
      wallWin.style.top = Math.max(oy + e.clientY - sy, 0) + "px";
    });
    window.addEventListener("pointerup", function () { drag = false; });
  })();
  try {
    var savedWall = localStorage.getItem(WALL_KEY);
    if (savedWall) applyWall(savedWall);
    else applyWall("#008080");
  } catch (e) {}

  /* ---------- desktop icon selection ---------- */
  var dicons = Array.prototype.slice.call(document.querySelectorAll(".dicon"));
  dicons.forEach(function (d) {
    d.addEventListener("click", function () {
      dicons.forEach(function (x) { x.classList.remove("sel"); });
      d.classList.add("sel");
    });
  });

  refreshSize();
  setTimeout(function () { repaintTracks(document); }, 300);
})();
