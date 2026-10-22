/* =========================================================================
   pincards.js: tap-to-pin cards and save-with-pins for My Little Inverts.
   Provenance: copied from NEON-Mosquito-Pulse@a2d0f80 (2026-06-22), then adapted for My Little Inverts.

   Four plotly charts are pinnable: the primary-status ledger, opportunities
   through time, collection density by event, and EPT composition by event.
   Selecting a mark reads the card HTML that the server put in that point's
   `customdata` (escaped server-side, with a data-tag for de-duplication) and
   pins a draggable, resizable card with a leader line to the mark.

   The pins, the leader-line SVG layer, and the anchor dots all live INSIDE the
   chart's `.smt-pinnable` box (not the plot div), so they travel with the box
   and are captured when html-to-image (vendored in www/vendor) snapshots it.

   Anchors are stored as DATA coordinates (not frozen pixels), so they reposition
   correctly on resize, fullscreen, and relayout. The plotly_click handler is
   re-attached on every (re)render: a Shiny+plotly re-render runs purge+newPlot
   on the same div, which wipes gd.on() listeners.
   ========================================================================= */
(function () {
  "use strict";
  var NS = "http://www.w3.org/2000/svg";

  function boxOf(node) { return node ? node.closest(".smt-pinnable") : null; }
  function bgColor() {
    var dark = document.documentElement.getAttribute("data-bs-theme") === "dark" ||
               document.body.getAttribute("data-bs-theme") === "dark";
    return dark ? "#0a1c20" : "#f8fdfd";
  }

  /* map a data point (dx, dy) to box-relative pixels via plotly's live axes, so
     a pin's leader line follows the dot through any resize/relayout. */
  function anchorPx(gd, box, dx, dy) {
    var fl = gd && gd._fullLayout;
    if (!fl || !fl.xaxis || !fl.yaxis) return null;
    // d2p() (data -> pixel) runs d2c then c2l then l2p, so it maps a RAW clicked
    // value to pixels correctly on EVERY axis type: linear, log (log10), date
    // (parses the date string), and category (label -> index). That lets one pin
    // system anchor across the numeric Taxa Board, the log density axis, the
    // date time-series (EPT pulse / density / richness) AND the categorical bout
    // axis (composition). c2p/l2p are last-resort fallbacks. (Earlier l2p() on a
    // raw value was the off-point bug on the log axis.)
    var px = function (axis, v) {
      if (typeof axis.d2p === "function") return axis.d2p(v);
      if (typeof axis.c2p === "function") return axis.c2p(v);
      return axis.l2p(v);
    };
    if (typeof fl.xaxis.d2p !== "function" && typeof fl.xaxis.c2p !== "function" && typeof fl.xaxis.l2p !== "function") return null;
    var gdR = gd.getBoundingClientRect(), boxR = box.getBoundingClientRect();
    var ax = px(fl.xaxis, dx) + fl.xaxis._offset + (gdR.left - boxR.left);
    var ay = px(fl.yaxis, dy) + fl.yaxis._offset + (gdR.top - boxR.top);
    if (!isFinite(ax) || !isFinite(ay)) return null;   // degenerate layout -> caller falls back to box center
    return { ax: ax, ay: ay };
  }

  function linesLayer(box) {
    var s = box.querySelector(":scope > svg.smt-pin-lines");
    if (!s) {
      s = document.createElementNS(NS, "svg");
      s.setAttribute("class", "smt-pin-lines");
      box.appendChild(s);
    }
    return s;
  }
  /* x2/y2 chase the card centre (honours its scale() transform via getBoundingClientRect) */
  function updateLine(pin) {
    if (!pin.__line) return;
    var r = pin.getBoundingClientRect(), b = pin.__box.getBoundingClientRect();
    pin.__line.setAttribute("x2", r.left - b.left + r.width / 2);
    pin.__line.setAttribute("y2", r.top - b.top + r.height / 2);
  }

  window.smtClearPins = function () {
    document.querySelectorAll(".smt-pin").forEach(function (p) { p.remove(); });
    document.querySelectorAll("svg.smt-pin-lines").forEach(function (s) { s.innerHTML = ""; });
  };

  /* re-anchor every pin's leader line + dot from its stored DATA coords */
  function repositionAll(gd, box) {
    box.querySelectorAll(".smt-pin").forEach(function (pin) {
      if (pin.__dx == null || !pin.__line) return;
      var a = anchorPx(gd, box, pin.__dx, pin.__dy);
      if (!a) return;
      pin.__line.setAttribute("x1", a.ax); pin.__line.setAttribute("y1", a.ay);
      if (pin.__dot) { pin.__dot.setAttribute("cx", a.ax); pin.__dot.setAttribute("cy", a.ay); }
      updateLine(pin);
    });
  }

  function makePin(gd, box, html, dx, dy, key) {
    var bR = box.getBoundingClientRect();
    var a = anchorPx(gd, box, dx, dy) || { ax: bR.width / 2, ay: bR.height / 2 };
    var pin = document.createElement("div");
    pin.className = "smt-pin";
    pin.__box = box; pin.__key = key; pin.__dx = dx; pin.__dy = dy;
    pin.innerHTML = "<button class='smt-pin-close' type='button' title='Close card' aria-label='Close card'>&times;</button>" + html;
    pin.querySelectorAll("em.smt-pin-hint").forEach(function (em) {
      var br = em.previousElementSibling;
      if (br && br.tagName === "BR") br.remove();
      em.remove();
    });
    var grip = document.createElement("div");
    grip.className = "smt-pin-resize";
    grip.title = "Drag to resize · double-tap to reset";
    pin.appendChild(grip);

    /* position the card near the dot, clamped on BOTH axes so the close button
       and resize grip always stay inside the box (and inside an exported PNG) */
    pin.style.left = Math.max(4, Math.min(a.ax + 24, bR.width - 250)) + "px";
    pin.style.top = Math.max(4, Math.min(a.ay + 14, bR.height - 150)) + "px";
    box.appendChild(pin);

    var layer = linesLayer(box);
    var ln = document.createElementNS(NS, "line");
    ln.setAttribute("x1", a.ax); ln.setAttribute("y1", a.ay);
    ln.setAttribute("stroke", "#2bb7c4"); ln.setAttribute("stroke-width", "2.5");   // riffle aqua (was lime #b8f24a)
    ln.setAttribute("stroke-linecap", "round");
    layer.appendChild(ln);
    var dot = document.createElementNS(NS, "circle");
    dot.setAttribute("cx", a.ax); dot.setAttribute("cy", a.ay); dot.setAttribute("r", "4.5");
    dot.setAttribute("fill", "#0a6f7a"); dot.setAttribute("stroke", "#ffffff");      // matches the "viewing" diamond + #fff marker edge
    dot.setAttribute("stroke-width", "1.5");
    layer.appendChild(dot);
    pin.__line = ln; pin.__dot = dot;
    updateLine(pin);

    pin.querySelector(".smt-pin-close").addEventListener("click", function () {
      ln.remove(); dot.remove(); pin.remove();
    });

    /* drag-to-move (clamped so a fat-thumb drag can't fling the card off-box) */
    pin.addEventListener("pointerdown", function (ev) {
      if (ev.target.closest("a, .smt-pin-close, .smt-open, .smt-pin-resize")) return;
      ev.preventDefault();
      try { pin.setPointerCapture(ev.pointerId); } catch (e) {}
      var sx = ev.clientX - pin.offsetLeft, sy = ev.clientY - pin.offsetTop;
      function mv(em) {
        var nb = pin.__box.getBoundingClientRect();
        pin.style.left = Math.max(4, Math.min(em.clientX - sx, nb.width - 40)) + "px";
        pin.style.top = Math.max(4, Math.min(em.clientY - sy, nb.height - 28)) + "px";
        updateLine(pin);
      }
      function up() {
        pin.removeEventListener("pointermove", mv);
        pin.removeEventListener("pointerup", up); pin.removeEventListener("pointercancel", up);
      }
      pin.addEventListener("pointermove", mv);
      pin.addEventListener("pointerup", up); pin.addEventListener("pointercancel", up);
    });

    /* grip-to-resize via scale() (clientX throughout, matching drag, so a
       scrolling mobile viewport can't make the scale jump) */
    grip.addEventListener("pointerdown", function (ev) {
      ev.preventDefault(); ev.stopPropagation();
      try { grip.setPointerCapture(ev.pointerId); } catch (e) {}
      var startX = ev.clientX, startScale = pin.__scale || 1;
      var baseW = pin.getBoundingClientRect().width / startScale;
      function mv(em) {
        var s = Math.min(2.4, Math.max(0.5, startScale + (em.clientX - startX) / baseW));
        pin.__scale = s; pin.style.transform = "scale(" + s + ")"; updateLine(pin);
      }
      function up() {
        grip.removeEventListener("pointermove", mv);
        grip.removeEventListener("pointerup", up); grip.removeEventListener("pointercancel", up);
      }
      grip.addEventListener("pointermove", mv);
      grip.addEventListener("pointerup", up); grip.addEventListener("pointercancel", up);
    });
    grip.addEventListener("dblclick", function () {
      pin.__scale = 1; pin.style.transform = ""; updateLine(pin);
    });
    return pin;
  }

  function handleClick(gd, box, d) {
    if (!d || !d.points || !d.points.length) return;
    var pt = d.points[0];
    var html = pt.customdata;
    if (!html) return;                 // only points carrying a card (skip the fit line)
    var key = (html.match(/data-tag='([^']+)'/) || [])[1] || html.slice(0, 48);
    var dup = Array.prototype.find.call(box.querySelectorAll(".smt-pin"),
      function (p) { return p.__key === key; });
    if (dup) { dup.classList.remove("smt-pulse"); void dup.offsetWidth; dup.classList.add("smt-pulse"); return; }
    /* anchor from the DATA point (not the finger): exact, and touch-safe - on
       touch devices plotly's synthesized event has no usable clientX/Y */
    makePin(gd, box, html, pt.x, pt.y, key);
  }

  /* identity-based signature: the sorted set of pinnable point tags. Stable when
     the chart is merely recoloured or a point is selected (same plot set), so
     pinned cards survive those re-renders; changes only when the plotted
     entities actually change (e.g. a new site) -> then pins clear. NOT trace
     count / x-ordering, which recolour and select would falsely trip. */
  function dataSig(gd) {
    if (!gd.data || !gd.data.length) return "";
    // dedupe: the "★ viewing" highlight trace re-emits a tag already in the base
    // set, so a push-list would gain a duplicate token and falsely flip the
    // signature - clearing pins every time the user selects a taxon/site. A set
    // keeps the signature stable on select, and still changes when the plotted
    // entities genuinely change (new site / new metric filter -> new tags).
    var seen = {};
    gd.data.forEach(function (t) {
      if (!t.customdata) return;
      // a single-point trace (e.g. each per-bout marker on the EPT pulse) can
      // arrive as a scalar string, not an array - coerce so .forEach is safe.
      var cd = Array.isArray(t.customdata) ? t.customdata : [t.customdata];
      cd.forEach(function (h) {
        var m = String(h).match(/data-tag='([^']+)'/); if (m) seen[m[1]] = 1;
      });
    });
    return Object.keys(seen).sort().join(",");
  }

  /* (re)bind a plotly graph div. Safe to call repeatedly - it removes any prior
     handler first. Clears pins when the underlying DATA changed (filter / select). */
  function bindPlot(gd) {
    if (!gd || typeof gd.on !== "function") return;
    var box = boxOf(gd); if (!box) return;

    var sig = dataSig(gd);
    if (gd.__smtSig !== undefined && gd.__smtSig !== sig) {
      box.querySelectorAll(".smt-pin").forEach(function (p) { p.remove(); });
      var ll = box.querySelector("svg.smt-pin-lines"); if (ll) ll.innerHTML = "";
    }
    gd.__smtSig = sig;

    if (gd.__smtClick && gd.removeListener) { try { gd.removeListener("plotly_click", gd.__smtClick); } catch (e) {} }
    gd.__smtClick = function (d) { handleClick(gd, box, d); };
    gd.on("plotly_click", gd.__smtClick);

    if (gd.__smtRelayout && gd.removeListener) { try { gd.removeListener("plotly_relayout", gd.__smtRelayout); } catch (e) {} }
    gd.__smtRelayout = function () { repositionAll(gd, box); };
    gd.on("plotly_relayout", gd.__smtRelayout);

    if (!box.__smtRO && window.ResizeObserver) {
      box.__smtRO = new ResizeObserver(function () {
        var g = box.querySelector(".js-plotly-plot"); if (g) repositionAll(g, box);
      });
      box.__smtRO.observe(box);
    }
  }

  function scan() {
    document.querySelectorAll(".smt-pinnable .js-plotly-plot").forEach(bindPlot);
  }
  /* rAF-coalesced scan so the document-wide observer doesn't run scan() on every
     count-up / DT / plotly mutation (it fires in bursts during animations) */
  var scanPending = false;
  function scanSoon() {
    if (scanPending) return;
    scanPending = true;
    requestAnimationFrame(function () { scanPending = false; scan(); });
  }

  /* ---- exports (with a toast + double-fire guard) ------------------------- */
  function toastStart(msg) {
    if (typeof Swal === "undefined") return;
    Swal.fire({ toast: true, position: "top-end", title: msg, showConfirmButton: false,
      allowOutsideClick: false, didOpen: function () { if (Swal.showLoading) Swal.showLoading(); } });
  }
  function toastDone(msg, isErr) {
    if (typeof Swal === "undefined") {
      // This app does not load SweetAlert: errors still need to reach the reader.
      if (isErr) window.alert(msg);
      return;
    }
    Swal.fire({ toast: true, position: "top-end", icon: isErr ? "error" : "success",
      title: msg, showConfirmButton: false, timer: 2200 });
  }
  function downloadUrl(url, name) {
    var a = document.createElement("a"); a.download = name; a.href = url; a.click();
  }
  var saving = false;
  function snap(node, name, beforeEl) {
    if (!node || saving) return;
    if (typeof htmlToImage === "undefined") {
      toastDone("The image tool did not load. Reload the page and try again.", true);
      return;
    }
    saving = true;
    // force the plotly chart to its current size first (a tab that rendered while
    // hidden, or a just-toggled fullscreen, can leave a 0-sized / stale SVG)
    var gd = node.querySelector ? node.querySelector(".js-plotly-plot") : null;
    if (gd && window.Plotly && Plotly.Plots) { try { Plotly.Plots.resize(gd); } catch (e) {} }
    node.querySelectorAll(".smt-pin.smt-pulse").forEach(function (p) { p.classList.remove("smt-pulse"); });
    toastStart("Rendering image…");
    setTimeout(function () {
      htmlToImage.toPng(node, { pixelRatio: 2, backgroundColor: bgColor(), cacheBust: true, skipFonts: true,
        filter: function (n) { return !(n.classList && (n.classList.contains("smt-pin-close") ||
          n.classList.contains("smt-pin-resize") || n.classList.contains("smt-snap-btn") ||
          n.classList.contains("smt-clear-btn"))); } })   // keep cards + leader lines; drop chrome buttons
        .then(function (url) { downloadUrl(url, name); toastDone("Saved ✓"); })
        .catch(function () { toastDone("Render failed. Try again.", true); })
        .then(function () { saving = false; });
    }, 90);
  }
  // any .smt-pinnable box by id (the four pinnable charts use this)
  window.smtSaveBox = function (id, name) { var n = document.getElementById(id); if (n) snap(n, name); };

  document.addEventListener("DOMContentLoaded", function () {
    var mo = new MutationObserver(scanSoon);
    mo.observe(document.body, { childList: true, subtree: true });
    scan();
  });
  /* re-bind/re-fit when a tab becomes visible (plotly in a hidden tab can
     render late, and a tab-show dispatches a resize that relayouts the plot) */
  document.addEventListener("shown.bs.tab", function () { setTimeout(scan, 80); });
})();
