#!/usr/bin/env node

// A real browser/session gate for the public Connect app. The companion curl
// probe proves byte identity in initial HTML; this probe goes further by
// requiring the server-rendered exact site roster, one lazy-loaded site bundle,
// and a browser -> Shiny server -> browser help-modal round trip.

import { readFile } from "node:fs/promises";
import { chromium } from "playwright";

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

function fail(message) {
  throw new Error(`Connect browser probe failed: ${message}`);
}

const identity = JSON.parse(await readFile(identityPath, "utf8"));
const releaseId = identity.release_id;
if (identity.schema_version !== 1
    || identity.app_id !== "NEON-My-Little-Inverts"
    || !/^sha256:[0-9a-f]{64}$/.test(releaseId || "")) {
  fail("the committed production identity is malformed");
}

const revision = encodeURIComponent(
  `${process.env.GITHUB_SHA || "manual"}-${Date.now()}`,
);
const url = new URL(app);
url.searchParams.set("verify", revision);

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  reducedMotion: "reduce",
  viewport: { width: 1280, height: 900 },
});
page.setDefaultTimeout(180_000);

const pageErrors = [];
page.on("pageerror", (error) => pageErrors.push(error.message));

try {
  const response = await page.goto(url.href, {
    waitUntil: "domcontentloaded",
    timeout: 90_000,
  });
  if (!response || !response.ok()) {
    fail(`navigation returned ${response ? response.status() : "no response"}`);
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
  // route and a positive opportunity stat prove the runtime data path works.
  await page.locator(".site-card")
    .filter({ has: page.locator(".sc-name b", { hasText: "SYCA" }) })
    .click();
  await page.waitForFunction(() => {
    const stats = [...document.querySelectorAll("#heroStats .hero-stat")];
    const opportunity = stats.find((stat) => (
      stat.querySelector(".hs-l")?.textContent.trim() === "field opportunities"
    ));
    const value = Number(opportunity?.querySelector(".hs-v")?.dataset.target);
    const overlay = document.querySelector("#loadOverlay");
    return new URL(window.location.href).searchParams.get("site") === "SYCA"
      && stats.length === 5
      && Number.isFinite(value)
      && value > 0
      && (!overlay || getComputedStyle(overlay).display === "none");
  });
  await page.waitForFunction(
    () => !document.documentElement.classList.contains("shiny-busy"),
  );

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
  if (pageErrors.length) {
    fail(`uncaught browser error: ${pageErrors.join(" | ")}`);
  }

  console.log(
    `OK: Connect opened an interactive Shiny session for exact production instance ${releaseId}.`,
  );
} finally {
  await browser.close();
}
