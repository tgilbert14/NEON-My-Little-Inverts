#!/usr/bin/env node

// A real browser/session gate for both public production surfaces. The
// companion curl probe waits for the exact release receipt and initial Connect
// identity. This probe additionally requires byte-exact Pages assets, rendered
// responsive Pages covers, and a browser -> Shiny server -> browser round trip.

import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { chromium } from "playwright";

const pages = process.env.INV_PAGES_URL
  || "https://tgilbert14.github.io/NEON-My-Little-Inverts/";
const app = process.env.INV_CONNECT_URL
  || "https://019ef4fb-c6c4-7ddf-2667-7e1021b2ef10.share.connect.posit.cloud/";
const identityPath = process.env.INV_PRODUCTION_IDENTITY_PATH
  || "release/production-identity.json";
const appMarker = "my-little-inverts-release-2026-v1";
const expectedSites = [
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU",
];
const pagesFiles = [
  ["docs/index.html", "index.html"],
  ["docs/og-image-v2.png", "og-image-v2.png"],
  [
    "docs/assets/inverts-living-poster-v2-840.webp",
    "assets/inverts-living-poster-v2-840.webp",
  ],
  [
    "docs/assets/inverts-living-poster-v2.png",
    "assets/inverts-living-poster-v2.png",
  ],
  [
    "docs/assets/inverts-living-poster-v2.webp",
    "assets/inverts-living-poster-v2.webp",
  ],
];
const pagesViewports = [
  { label: "desktop", width: 1280, height: 900 },
  { label: "390px phone", width: 390, height: 844 },
  { label: "320px phone", width: 320, height: 568 },
];
const connectViewports = [
  { label: "desktop", width: 1280, height: 900 },
  { label: "390px phone", width: 390, height: 844 },
  { label: "320px phone", width: 320, height: 568 },
];
const expectedTitle = "NEON My Little Inverts";
const phoneViewport = { label: "375px phone", width: 375, height: 812 };
const mainTabs = ["overview", "strata", "taxa", "network", "qa", "about"];
const cartoTileHost = "basemaps.cartocdn.com";
const requireCartoTiles = process.env.INV_REQUIRE_CARTO_TILES === "1";
const expectedSycaStats = [
  { label: "field opportunities", value: "193" },
  { label: "count-eligible", value: "121" },
  { label: "density-eligible", value: "121" },
  { label: "mixed-rank taxa recorded", value: "245" },
  { label: "collection events", value: "17" },
];

function fail(message) {
  throw new Error(`Production browser probe failed: ${message}`);
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function sameOrigin(value, expectedOrigin) {
  try {
    return new URL(value).origin === expectedOrigin;
  } catch {
    return false;
  }
}

// Records only whether a CARTO basemap tile was requested. The tile URL carries
// the suite key, so the URL itself is never stored or printed.
function watchCartoTiles(page, state) {
  page.on("request", (request) => {
    try {
      const host = new URL(request.url()).hostname;
      if (host === cartoTileHost || host.endsWith(`.${cartoTileHost}`)) {
        state.cartoRequests += 1;
      }
    } catch {
      // Non-URL requests (data:, blob:) are not tiles.
    }
  });
}

async function waitForSycaHero(page) {
  await page.waitForFunction((expectedStats) => {
    const stats = [...document.querySelectorAll("#heroStats .hero-stat")];
    const exactStats = expectedStats.every(({ label, value }) => {
      const stat = stats.find((candidate) => (
        candidate.querySelector(".hs-l")?.textContent.trim() === label
      ));
      const counter = stat?.querySelector(".hs-v");
      return counter?.dataset.target === value
        && counter.textContent.trim() === value;
    });
    const overlay = document.querySelector("#loadOverlay");
    return new URL(window.location.href).searchParams.get("site") === "SYCA"
      && stats.length === expectedStats.length
      && exactStats
      && (!overlay || getComputedStyle(overlay).display === "none");
  }, expectedSycaStats);
  await page.waitForFunction(
    () => !document.documentElement.classList.contains("shiny-busy"),
  );
}

async function requireDocumentShell(page, label) {
  const shell = await page.evaluate(() => ({
    title: document.title,
    lang: document.documentElement.lang,
  }));
  if (shell.title !== expectedTitle) {
    fail(`${label} document.title is "${shell.title}"; expected "${expectedTitle}"`);
  }
  if (shell.lang !== "en") {
    fail(`${label} <html lang> is "${shell.lang}"; expected "en"`);
  }
}

// Every rendered status bar must carry a real fill; rgb(0, 0, 0) means the
// trace lost its colour mapping and plotly fell back to black.
async function requireStatusBarFills(page) {
  await page.waitForFunction(() => (
    document.querySelectorAll("#overviewStatusPlot .trace.bars .point path").length > 0
  ));
  const fills = await page.evaluate(() => (
    [...document.querySelectorAll("#overviewStatusPlot .trace.bars .point path")]
      .map((path) => getComputedStyle(path).fill || path.style.fill || "")
  ));
  const black = fills.filter((fill) => fill.replace(/\s+/g, "") === "rgb(0,0,0)");
  if (!fills.length || black.length) {
    fail(
      `#overviewStatusPlot has ${black.length} of ${fills.length} bars `
      + "filled rgb(0, 0, 0)",
    );
  }
}

// Inactive card-header tab text must reach WCAG AA 4.5:1 against the colour
// actually painted behind it (first non-transparent ancestor background,
// composited over any translucent layers and finally white).
async function requireInactiveTabContrast(page, label) {
  const results = await page.evaluate(() => {
    const parse = (value) => {
      const match = String(value || "").match(/rgba?\(([^)]+)\)/);
      if (!match) return null;
      const parts = match[1].split(/[\s,/]+/).filter(Boolean).map(Number);
      return {
        r: parts[0], g: parts[1], b: parts[2],
        a: parts.length > 3 && Number.isFinite(parts[3]) ? parts[3] : 1,
      };
    };
    const over = (top, bottom) => ({
      r: top.r * top.a + bottom.r * (1 - top.a),
      g: top.g * top.a + bottom.g * (1 - top.a),
      b: top.b * top.a + bottom.b * (1 - top.a),
      a: 1,
    });
    const luminance = ({ r, g, b }) => {
      const channel = (value) => {
        const v = value / 255;
        return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4;
      };
      return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
    };
    const effectiveBackground = (element) => {
      const layers = [];
      for (let node = element; node && node.nodeType === 1; node = node.parentElement) {
        const color = parse(getComputedStyle(node).backgroundColor);
        if (color && color.a > 0) {
          layers.push(color);
          if (color.a >= 1) break;
        }
      }
      return layers.reverse().reduce(
        (bottom, top) => over(top, bottom),
        { r: 255, g: 255, b: 255, a: 1 },
      );
    };
    return [...document.querySelectorAll(".card-header .nav-tabs .nav-link:not(.active)")]
      .filter((link) => link.getClientRects().length > 0
        && getComputedStyle(link).visibility !== "hidden")
      .map((link) => {
        const background = effectiveBackground(link);
        const text = parse(getComputedStyle(link).color) || { r: 0, g: 0, b: 0, a: 1 };
        const foreground = text.a < 1 ? over(text, background) : text;
        const [light, dark] = [luminance(foreground), luminance(background)]
          .sort((a, b) => b - a);
        return {
          text: link.textContent.replace(/\s+/g, " ").trim(),
          ratio: (light + 0.05) / (dark + 0.05),
        };
      });
  });
  if (!results.length) fail(`${label} has no visible inactive card-header tab to contrast-check`);
  const low = results.filter(({ ratio }) => !(ratio >= 4.5));
  if (low.length) {
    fail(
      `${label} inactive tab text is below 4.5:1 contrast: `
      + low.map(({ text, ratio }) => `"${text}" ${ratio.toFixed(2)}:1`).join(" | "),
    );
  }
}

function cacheBusted(base, relative, revision, suffix = "") {
  const url = new URL(relative, base);
  url.searchParams.set("verify", `${revision}-${suffix}`);
  return url.href;
}

function watchPage(page, expectedOrigin) {
  const diagnostics = {
    pageErrors: [],
    consoleErrors: [],
    requestFailures: [],
    httpErrors: [],
  };
  page.on("pageerror", (error) => diagnostics.pageErrors.push(error.message));
  page.on("console", (message) => {
    if (message.type() === "error") diagnostics.consoleErrors.push(message.text());
  });
  page.on("requestfailed", (request) => {
    if (sameOrigin(request.url(), expectedOrigin)) {
      diagnostics.requestFailures.push(
        `${request.method()} ${request.url()} (${request.failure()?.errorText || "failed"})`,
      );
    }
  });
  page.on("response", (response) => {
    if (sameOrigin(response.url(), expectedOrigin) && response.status() >= 400) {
      diagnostics.httpErrors.push(`${response.status()} ${response.url()}`);
    }
  });
  return diagnostics;
}

function requireCleanPage(diagnostics, label) {
  const failures = [
    ...diagnostics.pageErrors.map((value) => `pageerror: ${value}`),
    ...diagnostics.consoleErrors.map((value) => `console.error: ${value}`),
    ...diagnostics.requestFailures.map((value) => `requestfailed: ${value}`),
    ...diagnostics.httpErrors.map((value) => `HTTP error: ${value}`),
  ];
  if (failures.length) fail(`${label} emitted ${failures.join(" | ")}`);
}

async function verifyExactPagesBytes(browser, revision) {
  const context = await browser.newContext();
  const expectedOrigin = new URL(pages).origin;
  try {
    for (const [localPath, remotePath] of pagesFiles) {
      const expected = await readFile(localPath);
      const response = await context.request.get(
        cacheBusted(pages, remotePath, revision, "bytes"),
        {
          failOnStatusCode: false,
          headers: { "Cache-Control": "no-cache" },
          timeout: 30_000,
        },
      );
      try {
        if (!response.ok()) {
          fail(`Pages ${remotePath} returned HTTP ${response.status()}`);
        }
        if (!sameOrigin(response.url(), expectedOrigin)) {
          fail(`Pages ${remotePath} redirected outside ${expectedOrigin}`);
        }
        const observed = await response.body();
        const expectedHash = sha256(expected);
        const observedHash = sha256(observed);
        if (observed.length !== expected.length || observedHash !== expectedHash) {
          fail(
            `Pages ${remotePath} differs from ${localPath} `
            + `(expected ${expected.length} bytes/${expectedHash}; `
            + `observed ${observed.length} bytes/${observedHash})`,
          );
        }
      } finally {
        await response.dispose();
      }
    }
  } finally {
    await context.close();
  }
}

async function requireKeyboardFocus(page, selector, label) {
  const state = await page.evaluate((expectedSelector) => {
    const active = document.activeElement;
    if (!active?.matches(expectedSelector)) {
      return { ok: false, detail: `active element is ${active?.outerHTML || "none"}` };
    }
    const style = getComputedStyle(active);
    const rect = active.getBoundingClientRect();
    const visible = style.display !== "none"
      && style.visibility !== "hidden"
      && Number(style.opacity) > 0
      && rect.width > 0
      && rect.height > 0
      && rect.top >= 0
      && rect.left >= 0
      && rect.right <= window.innerWidth + 1
      && rect.bottom <= window.innerHeight + 1;
    const outlined = active.matches(":focus-visible")
      && style.outlineStyle !== "none"
      && Number.parseFloat(style.outlineWidth) >= 2;
    return {
      ok: visible && outlined,
      detail: `visible=${visible} focusVisible=${active.matches(":focus-visible")} `
        + `outline=${style.outlineStyle}/${style.outlineWidth} `
        + `rect=${[rect.left, rect.top, rect.right, rect.bottom].join(",")}`,
    };
  }, selector);
  if (!state.ok) fail(`${label} lacks visible keyboard focus (${state.detail})`);
}

async function verifyPagesViewport(browser, viewport, revision) {
  const expectedOrigin = new URL(pages).origin;
  const page = await browser.newPage({
    reducedMotion: "reduce",
    viewport: { width: viewport.width, height: viewport.height },
  });
  page.setDefaultTimeout(60_000);
  const diagnostics = watchPage(page, expectedOrigin);
  try {
    const response = await page.goto(
      cacheBusted(pages, "", revision, `${viewport.width}x${viewport.height}`),
      { waitUntil: "load", timeout: 60_000 },
    );
    if (!response || !response.ok()) {
      fail(
        `Pages ${viewport.label} navigation returned `
        + `${response ? response.status() : "no response"}`,
      );
    }
    if (!sameOrigin(page.url(), expectedOrigin)) {
      fail(`Pages ${viewport.label} navigation left ${expectedOrigin}`);
    }

    await page.locator(".poster-art img").waitFor({ state: "visible" });
    await page.waitForFunction(() => {
      const image = document.querySelector(".poster-art img");
      return image?.complete && image.naturalWidth > 0 && image.naturalHeight > 0;
    });

    const rendered = await page.evaluate(({ width }) => {
      const selectors = [
        ".topline", ".brand", ".suite-jump", ".poster-copy", "h1",
        ".promise", ".button", ".footer-inner", ".footer-links",
      ];
      const clipped = selectors.flatMap((selector) => {
        const element = document.querySelector(selector);
        if (!element) return [`${selector}:missing`];
        const rect = element.getBoundingClientRect();
        const style = getComputedStyle(element);
        const bad = style.display === "none" || style.visibility === "hidden"
          || rect.width <= 0 || rect.height <= 0
          || rect.left < -1 || rect.right > window.innerWidth + 1;
        return bad
          ? [`${selector}:${[rect.left, rect.right, rect.width, rect.height].join(",")}`]
          : [];
      });
      const image = document.querySelector(".poster-art img");
      const imageUrl = image?.currentSrc ? new URL(image.currentSrc) : null;
      const brand = document.querySelector(".brand")?.getBoundingClientRect();
      const suite = document.querySelector(".suite-jump")?.getBoundingClientRect();
      const art = document.querySelector(".poster-art")?.getBoundingClientRect();
      const copy = document.querySelector(".poster-copy")?.getBoundingClientRect();
      const button = document.querySelector(".button")?.getBoundingClientRect();
      const driver = document.querySelector(".suite-jump")?.getBoundingClientRect();
      return {
        viewportWidth: window.innerWidth,
        requestedWidth: width,
        horizontalOverflow:
          document.documentElement.scrollWidth - document.documentElement.clientWidth,
        clipped,
        headerOverlap: Boolean(brand && suite && brand.right > suite.left + 1),
        mobileOrderBad: width <= 700
          && Boolean(art && copy && art.bottom > copy.top + 1),
        buttonHeight: button?.height || 0,
        driverHeight: driver?.height || 0,
        artLoaded: Boolean(image?.complete && image.naturalWidth > 0
          && image.naturalHeight > 0),
        artOrigin: imageUrl?.origin || "",
        artPath: imageUrl?.pathname || "",
        badgeAbsent: !document.querySelector(".art-note, .poster-art figcaption"),
        animations: document.getAnimations({ subtree: true })
          .filter((animation) => animation.playState !== "finished").length,
      };
    }, { width: viewport.width });
    if (rendered.viewportWidth !== rendered.requestedWidth) {
      fail(`${viewport.label} rendered at ${rendered.viewportWidth}px`);
    }
    if (rendered.horizontalOverflow > 1 || rendered.clipped.length) {
      fail(
        `Pages ${viewport.label} clips or overflows `
        + `(overflow=${rendered.horizontalOverflow}; ${rendered.clipped.join(" | ")})`,
      );
    }
    if (rendered.headerOverlap) fail(`Pages ${viewport.label} header items overlap`);
    if (rendered.mobileOrderBad) {
      fail(`Pages ${viewport.label} does not keep artwork before poster copy`);
    }
    if (rendered.buttonHeight < 51 || rendered.driverHeight < 43) {
      fail(
        `Pages ${viewport.label} tap targets shrank `
        + `(CTA=${rendered.buttonHeight}, Driver=${rendered.driverHeight})`,
      );
    }
    if (!rendered.artLoaded
        || rendered.artOrigin !== expectedOrigin
        || !/\/assets\/inverts-living-poster-v2(?:-840)?[.](?:png|webp)$/.test(
          rendered.artPath,
        )) {
      fail(
        `Pages ${viewport.label} did not render reviewed local art `
        + `(${rendered.artOrigin}${rendered.artPath})`,
      );
    }
    if (!rendered.badgeAbsent) {
      fail(`Pages ${viewport.label} restored the retired illustration badge`);
    }
    if (rendered.animations) {
      fail(`Pages ${viewport.label} exposes ${rendered.animations} live animation(s)`);
    }

    await page.keyboard.press("Tab");
    await requireKeyboardFocus(page, ".skip", `Pages ${viewport.label} skip link`);
    await page.keyboard.press("Enter");
    await page.waitForFunction(() => document.activeElement?.id === "main");
    await page.keyboard.press("Tab");
    await requireKeyboardFocus(
      page, ".suite-jump", `Pages ${viewport.label} Atlas route`,
    );
    await page.keyboard.press("Tab");
    await requireKeyboardFocus(page, ".button", `Pages ${viewport.label} CTA`);

    await page.waitForTimeout(250);
    requireCleanPage(diagnostics, `Pages ${viewport.label}`);
  } finally {
    await page.close();
  }
}

async function verifyConnectViewport(page, viewport, expectedOrigin) {
  await page.setViewportSize({ width: viewport.width, height: viewport.height });
  await page.waitForTimeout(250);
  const connectRendered = await page.evaluate(({ width }) => {
    // The desktop art intentionally bleeds beneath the poster's overflow-hidden
    // crop; validate the containing poster rather than the raw crop.
    const selectors = [
      ".inverts-poster", ".inv-poster-copy", ".inv-poster-topline",
      ".inv-poster-brand", ".inv-poster-suite-link", ".inverts-poster h1",
      ".inv-poster-promise", ".inv-poster-cta", ".inv-poster-note",
    ];
    const clipped = selectors.flatMap((selector) => {
      const element = document.querySelector(selector);
      if (!element) return [`${selector}:missing`];
      const rect = element.getBoundingClientRect();
      const style = getComputedStyle(element);
      const bad = style.display === "none" || style.visibility === "hidden"
        || rect.width <= 0 || rect.height <= 0
        || rect.left < -1 || rect.right > window.innerWidth + 1;
      return bad
        ? [`${selector}:${[rect.left, rect.right, rect.width, rect.height].join(",")}`]
        : [];
    });
    const overlaps = (left, right) => Boolean(left && right
      && left.left < right.right - 1 && left.right > right.left + 1
      && left.top < right.bottom - 1 && left.bottom > right.top + 1);
    const poster = document.querySelector(".inverts-poster");
    const image = document.querySelector(".inv-poster-art img");
    const imageUrl = image?.currentSrc ? new URL(image.currentSrc) : null;
    const brand = document.querySelector(".inv-poster-brand")?.getBoundingClientRect();
    const suite = document.querySelector(".inv-poster-suite-link")
      ?.getBoundingClientRect();
    const art = document.querySelector(".inv-poster-art")?.getBoundingClientRect();
    const copy = document.querySelector(".inv-poster-copy")?.getBoundingClientRect();
    const cta = document.querySelector(".inv-poster-cta")?.getBoundingClientRect();
    return {
      viewportWidth: window.innerWidth,
      requestedWidth: width,
      horizontalOverflow:
        document.documentElement.scrollWidth - document.documentElement.clientWidth,
      clipped,
      posterDisplay: poster ? getComputedStyle(poster).display : "missing",
      headerOverlap: overlaps(brand, suite),
      mobileOrderBad: width <= 900
        && Boolean(art && copy && art.bottom > copy.top + 1),
      ctaHeight: cta?.height || 0,
      driverHeight: suite?.height || 0,
      artLoaded: Boolean(image?.complete && image.naturalWidth > 0
        && image.naturalHeight > 0),
      artOrigin: imageUrl?.origin || "",
      artPath: imageUrl?.pathname || "",
      badgeAbsent: !document.querySelector(".inv-poster-art figcaption"),
      posterAnimations: poster?.getAnimations({ subtree: true })
        .filter((animation) => animation.playState !== "finished").length || 0,
    };
  }, { width: viewport.width });
  if (connectRendered.viewportWidth !== connectRendered.requestedWidth) {
    fail(`Connect ${viewport.label} rendered at ${connectRendered.viewportWidth}px`);
  }
  if (connectRendered.horizontalOverflow > 1 || connectRendered.clipped.length) {
    fail(
      `Connect ${viewport.label} clips or overflows `
      + `(overflow=${connectRendered.horizontalOverflow}; `
      + `${connectRendered.clipped.join(" | ")})`,
    );
  }
  if (connectRendered.posterDisplay !== "grid") {
    fail(`Connect ${viewport.label} poster display is ${connectRendered.posterDisplay}`);
  }
  if (connectRendered.headerOverlap) {
    fail(`Connect ${viewport.label} poster header items overlap`);
  }
  if (connectRendered.mobileOrderBad) {
    fail(`Connect ${viewport.label} does not keep artwork before poster copy`);
  }
  if (connectRendered.ctaHeight < 51 || connectRendered.driverHeight < 43) {
    fail(
      `Connect ${viewport.label} tap targets shrank `
      + `(CTA=${connectRendered.ctaHeight}, Driver=${connectRendered.driverHeight})`,
    );
  }
  if (!connectRendered.artLoaded
      || connectRendered.artOrigin !== expectedOrigin
      || !/\/assets\/inverts-living-poster-v2(?:-840)?[.](?:png|webp)$/.test(
        connectRendered.artPath,
      )) {
    fail(
      `Connect ${viewport.label} did not render reviewed local art `
      + `(${connectRendered.artOrigin}${connectRendered.artPath})`,
    );
  }
  if (!connectRendered.badgeAbsent) {
    fail(`Connect ${viewport.label} restored the retired illustration badge`);
  }
  if (connectRendered.posterAnimations) {
    fail(
      `Connect ${viewport.label} poster exposes `
      + `${connectRendered.posterAnimations} live animation(s)`,
    );
  }
}

async function verifyConnect(browser, releaseId, revision, tileState) {
  const expectedOrigin = new URL(app).origin;
  const page = await browser.newPage({
    reducedMotion: "reduce",
    viewport: { width: 1280, height: 900 },
  });
  page.setDefaultTimeout(180_000);
  const diagnostics = watchPage(page, expectedOrigin);
  watchCartoTiles(page, tileState);
  try {
    const url = new URL(app);
    url.searchParams.set("verify", revision);
    const response = await page.goto(url.href, {
      waitUntil: "domcontentloaded",
      timeout: 90_000,
    });
    if (!response || !response.ok()) {
      fail(`Connect navigation returned ${response ? response.status() : "no response"}`);
    }
    if (!sameOrigin(page.url(), expectedOrigin)) {
      fail(`Connect navigation left ${expectedOrigin}`);
    }

    await page.waitForFunction(
      ({ expectedMarker, expectedRelease }) => {
        const marker = document.querySelector('meta[name="ddl-app-ready"]')
          ?.getAttribute("content");
        const release = document.querySelector('meta[name="ddl-release-instance"]')
          ?.getAttribute("content");
        return marker === expectedMarker && release === expectedRelease;
      },
      { expectedMarker: appMarker, expectedRelease: releaseId },
    );
    await requireDocumentShell(page, "Connect");

    await page.locator(".inv-poster-art img").waitFor({ state: "visible" });
    await page.waitForFunction(() => {
      const image = document.querySelector(".inv-poster-art img");
      return image?.complete && image.naturalWidth > 0 && image.naturalHeight > 0;
    });
    const appSurface = await page.evaluate(() => {
      const image = document.querySelector(".inv-poster-art img");
      const imageUrl = image?.currentSrc ? new URL(image.currentSrc) : null;
      const stylesheets = [...document.styleSheets]
        .map((sheet) => sheet.href || "");
      return {
        artLoaded: Boolean(image?.complete && image.naturalWidth > 0
          && image.naturalHeight > 0),
        artOrigin: imageUrl?.origin || "",
        artPath: imageUrl?.pathname || "",
        posterCss: stylesheets.some((href) => /\/poster[.]css(?:[?]|$)/.test(href)),
        invertsCss: stylesheets.some((href) => /\/inverts[.]css(?:[?]|$)/.test(href)),
        posterDisplay: getComputedStyle(
          document.querySelector(".inverts-poster"),
        ).display,
        horizontalOverflow:
          document.documentElement.scrollWidth - document.documentElement.clientWidth,
      };
    });
    if (!appSurface.artLoaded
        || appSurface.artOrigin !== expectedOrigin
        || !/\/assets\/inverts-living-poster-v2(?:-840)?[.](?:png|webp)$/.test(
          appSurface.artPath,
        )) {
      fail(
        `Connect did not render reviewed local art `
        + `(${appSurface.artOrigin}${appSurface.artPath})`,
      );
    }
    if (!appSurface.posterCss || !appSurface.invertsCss
        || appSurface.posterDisplay !== "grid"
        || appSurface.horizontalOverflow > 1) {
      fail(
        `Connect poster styles are incomplete `
        + `(posterCss=${appSurface.posterCss}, invertsCss=${appSurface.invertsCss}, `
        + `display=${appSurface.posterDisplay}, overflow=${appSurface.horizontalOverflow})`,
      );
    }

    for (const viewport of connectViewports) {
      await verifyConnectViewport(page, viewport, expectedOrigin);
    }
    await page.setViewportSize({ width: 320, height: 568 });
    await page.evaluate(() => {
      if (document.activeElement instanceof HTMLElement) document.activeElement.blur();
      window.scrollTo(0, 0);
    });
    await page.keyboard.press("Tab");
    await page.waitForFunction(() => {
      const skip = document.querySelector(".app-skip");
      const style = skip ? getComputedStyle(skip) : null;
      const rect = skip?.getBoundingClientRect();
      return document.activeElement === skip
        && skip.matches(":focus-visible")
        && Number.parseFloat(style?.outlineWidth || "0") >= 2
        && rect && rect.top >= 0;
    });
    await requireKeyboardFocus(page, ".app-skip", "Connect 320px skip link");
    await page.keyboard.press("Enter");
    await page.waitForFunction(
      () => document.activeElement?.id === "site-picker-start",
    );
    await page.setViewportSize({ width: 1280, height: 900 });

    // nationalPicker starts as an empty output div. A Leaflet pane exists only
    // after the live Shiny session sends and binds the server-rendered value.
    await page.waitForFunction(() => {
      const output = document.querySelector("#nationalPicker");
      return output?.classList.contains("shiny-bound-output")
        && output.querySelector(".leaflet-pane");
    });
    await page.locator("details.site-browse > summary").click();
    await page.waitForFunction((canonicalSites) => {
      const output = document.querySelector("#siteCards");
      const codes = [...(output?.querySelectorAll(".site-card .sc-name b") || [])]
        .map((node) => node.textContent.trim());
      return output?.classList.contains("shiny-bound-output")
        && !document.querySelector(".synth-banner")
        && codes.length === canonicalSites.length
        && new Set(codes).size === canonicalSites.length
        && canonicalSites.every((code) => codes.includes(code));
    }, expectedSites);

    // Load one canonical lazy bundle, not just the site index. The exact site
    // route and five exact visible receipt-bound stats prove the runtime data path.
    await page.locator(".site-card")
      .filter({ has: page.locator(".sc-name b", { hasText: "SYCA" }) })
      .click();
    await waitForSycaHero(page);

    // This button is a Shiny input and the modal is emitted by observeEvent on
    // the server, so seeing it is an explicit bidirectional session round trip.
    await page.locator("#help").click();
    await page.locator(".modal-content")
      .filter({ hasText: "How to read My Little Inverts" })
      .waitFor({ state: "visible" });

    const outputErrors = await page.locator(".shiny-output-error:visible")
      .allTextContents();
    if (outputErrors.length) {
      fail(`visible Shiny output error: ${outputErrors.join(" | ")}`);
    }
    if (await page.locator("#shiny-disconnected-overlay:visible").count()) {
      fail("Shiny disconnected after the interactive round trip");
    }

    await page.locator(".modal-footer button")
      .filter({ hasText: "Got it" })
      .click();
    await page.locator(".modal-content").waitFor({ state: "hidden" });
    await requireStatusBarFills(page);
    await requireInactiveTabContrast(page, "Connect desktop");

    // The site load was user-initiated from the bare picker URL, so it owns one
    // history entry: Back must return to the in-app picker, not leave the app.
    await page.goBack({ waitUntil: "commit", timeout: 60_000 });
    if (!sameOrigin(page.url(), expectedOrigin)) {
      fail(`browser Back after a site load left the app for ${page.url().split("?")[0]}`);
    }
    try {
      await page.waitForFunction(() => {
        const visible = (element) => Boolean(element
          && element.getClientRects().length > 0
          && getComputedStyle(element).display !== "none"
          && getComputedStyle(element).visibility !== "hidden");
        return visible(document.querySelector("#splash"))
          && !visible(document.querySelector("#mainTabsWrap"));
      }, undefined, { timeout: 60_000 });
    } catch {
      fail(
        "browser Back after a site load did not return to the picker "
        + `(#splash visible and #mainTabsWrap hidden; url=${page.url()})`,
      );
    }

    await page.waitForTimeout(500);
    requireCleanPage(diagnostics, "Connect");

    console.log(
      `OK: Connect opened an interactive Shiny session for exact production instance ${releaseId}.`,
    );
  } finally {
    await page.close();
  }
}

const identity = JSON.parse(await readFile(identityPath, "utf8"));
const releaseId = identity.release_id;
if (identity.schema_version !== 1
    || identity.app_id !== "NEON-My-Little-Inverts"
    || !/^sha256:[0-9a-f]{64}$/.test(releaseId || "")) {
  fail("the committed production identity is malformed");
}

async function verifyConnectPhoneTabs(browser, releaseId, revision, tileState) {
  const expectedOrigin = new URL(app).origin;
  const page = await browser.newPage({
    reducedMotion: "reduce",
    viewport: { width: phoneViewport.width, height: phoneViewport.height },
  });
  page.setDefaultTimeout(180_000);
  const diagnostics = watchPage(page, expectedOrigin);
  watchCartoTiles(page, tileState);
  try {
    const url = new URL(app);
    url.searchParams.set("site", "SYCA");
    url.searchParams.set("verify", `${revision}-phone`);
    const response = await page.goto(url.href, {
      waitUntil: "domcontentloaded",
      timeout: 90_000,
    });
    if (!response || !response.ok()) {
      fail(
        `Connect ${phoneViewport.label} navigation returned `
        + `${response ? response.status() : "no response"}`,
      );
    }
    if (!sameOrigin(page.url(), expectedOrigin)) {
      fail(`Connect ${phoneViewport.label} navigation left ${expectedOrigin}`);
    }
    await page.waitForFunction(
      (expectedRelease) => document.querySelector('meta[name="ddl-release-instance"]')
        ?.getAttribute("content") === expectedRelease,
      releaseId,
    );
    await requireDocumentShell(page, `Connect ${phoneViewport.label}`);
    await waitForSycaHero(page);

    for (const tab of mainTabs) {
      const link = page
        .locator(`#mainTabsWrap .nav-tabs a[data-value="${tab}"]`)
        .first();
      await link.click();
      await page.waitForFunction((value) => {
        const active = document.querySelector(
          `#mainTabsWrap .nav-tabs a[data-value="${value}"]`,
        );
        return active?.classList.contains("active")
          && !document.documentElement.classList.contains("shiny-busy");
      }, tab);
      await page.waitForTimeout(1_000);
      const overflowing = await page.evaluate(() => (
        [...document.querySelectorAll(".card-body")]
          .filter((body) => body.getClientRects().length > 0
            && getComputedStyle(body).visibility !== "hidden"
            && body.scrollWidth > body.clientWidth + 4)
          .map((body) => {
            const header = body.closest(".card")?.querySelector(".card-header");
            const name = header?.textContent.replace(/\s+/g, " ").trim()
              || "(no card header)";
            return `${name.slice(0, 80)} (${body.scrollWidth}px > ${body.clientWidth}px)`;
          })
      ));
      if (overflowing.length) {
        fail(
          `Connect ${phoneViewport.label} "${tab}" tab has card bodies wider than `
          + `the card: ${overflowing.join(" | ")}`,
        );
      }
    }
    await requireInactiveTabContrast(page, `Connect ${phoneViewport.label}`);

    await page.waitForTimeout(500);
    requireCleanPage(diagnostics, `Connect ${phoneViewport.label}`);
    console.log(
      `OK: Connect ${phoneViewport.label} renders ${mainTabs.length} main tabs without card overflow.`,
    );
  } finally {
    await page.close();
  }
}

function reportCartoTiles(tileState) {
  if (tileState.cartoRequests > 0) {
    console.log(`OK: the Connect pass requested ${cartoTileHost} basemap tiles.`);
    return;
  }
  console.log(
    "::warning title=CARTO basemap key not in effect::The Connect pass made no "
    + `${cartoTileHost} tile request, so the app is serving the keyless fallback `
    + "basemap. Set the suite CARTO basemap key in the Connect Cloud settings.",
  );
  if (requireCartoTiles) {
    fail(`no ${cartoTileHost} tile request while INV_REQUIRE_CARTO_TILES=1`);
  }
}

const revision = encodeURIComponent(
  `${process.env.GITHUB_SHA || "manual"}-${Date.now()}`,
);
const browser = await chromium.launch({ headless: true });
try {
  await verifyExactPagesBytes(browser, revision);
  for (const viewport of pagesViewports) {
    await verifyPagesViewport(browser, viewport, revision);
  }
  console.log(
    `OK: Pages serves exact reviewed bytes and renders cleanly at ${pagesViewports.map((value) => value.width).join("/")}px.`,
  );
  const tileState = { cartoRequests: 0 };
  await verifyConnect(browser, releaseId, revision, tileState);
  await verifyConnectPhoneTabs(browser, releaseId, revision, tileState);
  reportCartoTiles(tileState);
} finally {
  await browser.close();
}
