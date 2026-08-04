#!/usr/bin/env node

import { createHash } from "node:crypto";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const read = (path) => readFileSync(resolve(root, path), "utf8");
const cover = read("docs/index.html");
const ui = read("ui.R");
const posterCss = read("www/poster.css");
const provenance = read("docs/IMAGE-PROVENANCE.md");
const workflow = read(".github/workflows/refresh-data.yml");
const postDeployWorkflow = read(".github/workflows/post-deploy.yml");
const identityWriter = read("scripts/write_release_identity.R");
const manifestWriter = read("scripts/write_manifest.R");
const postDeploySmoke = read("scripts/post_deploy_smoke.sh");
const postDeployBrowser = read("scripts/post_deploy_browser.mjs");
const npmPackage = JSON.parse(read("package.json"));
const npmLock = JSON.parse(read("package-lock.json"));
const expectedBrowserSites = [
  "ARIK", "BARC", "BIGC", "BLDE", "BLUE", "BLWA", "CARI", "COMO",
  "CRAM", "CUPE", "FLNT", "GUIL", "HOPB", "KING", "LECO", "LEWI",
  "LIRO", "MART", "MAYF", "MCDI", "MCRA", "OKSR", "POSE", "PRIN",
  "PRLA", "PRPO", "REDB", "SUGG", "SYCA", "TECR", "TOMB", "TOOK",
  "WALK", "WLOU",
];
const errors = [];

function requireContract(condition, message) {
  if (!condition) errors.push(message);
}

requireContract(existsSync(resolve(root, "scripts/check_loaded_app_contract.R")), "loaded-app checker is missing from scripts/");
requireContract(!existsSync(resolve(root, "R/check_loaded_app_contract.R")), "executable loaded-app checker must not be auto-sourced from R/");
requireContract(
  JSON.stringify(readdirSync(resolve(root, "R")).filter((name) => name.endsWith(".R")).sort())
    === JSON.stringify(["inv_helpers.R", "report_pdf.R", "site_metadata.R"]),
  "deployed R/ helper family differs from the exact non-executable allowlist",
);

function count(source, pattern) {
  return (source.match(pattern) || []).length;
}

function sha256(path) {
  return createHash("sha256").update(readFileSync(resolve(root, path))).digest("hex");
}

function pngDimensions(path) {
  const data = readFileSync(resolve(root, path));
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  requireContract(data.length >= 24 && data.subarray(0, 8).equals(signature), `${path} is not a PNG`);
  if (data.length < 24) return [0, 0];
  return [data.readUInt32BE(16), data.readUInt32BE(20)];
}

function webpDimensions(path) {
  const data = readFileSync(resolve(root, path));
  const valid = data.length >= 30
    && data.subarray(0, 4).toString("ascii") === "RIFF"
    && data.subarray(8, 12).toString("ascii") === "WEBP";
  requireContract(valid, `${path} is not a WebP`);
  if (!valid) return [0, 0];
  const chunk = data.subarray(12, 16).toString("ascii");
  if (chunk === "VP8 ") {
    return [data.readUInt16LE(26) & 0x3fff, data.readUInt16LE(28) & 0x3fff];
  }
  if (chunk === "VP8X") {
    return [data.readUIntLE(24, 3) + 1, data.readUIntLE(27, 3) + 1];
  }
  errors.push(`${path} uses unsupported WebP chunk ${chunk}`);
  return [0, 0];
}

const mainMatch = cover.match(/<main id="main" class="poster" tabindex="-1">([\s\S]*?)<\/main>/);
const main = mainMatch?.[1] ?? "";
const posterStart = ui.indexOf("inverts_poster <- function()");
const posterEnd = ui.indexOf("\n\nui <-", posterStart);
const appPoster = posterStart >= 0 && posterEnd > posterStart
  ? ui.slice(posterStart, posterEnd)
  : "";
const loadedStart = ui.indexOf('div(id = "mainTabsWrap"');
const firstImpression = loadedStart > 0 ? ui.slice(0, loadedStart) : ui;

// Static Pages: the first viewport is exactly one compact Living Poster.
requireContract(count(cover, /<h1\b/gi) === 1, "Pages cover must contain exactly one h1");
requireContract(count(cover, /<main\b/gi) === 1, "Pages cover must contain exactly one main landmark");
requireContract(Boolean(mainMatch), "Pages poster main must be the focusable #main skip target");
requireContract(/<html lang="en">/i.test(cover), "document language must be English");
requireContract(/class="skip" href="#main"/.test(cover), "Pages cover needs a skip link to #main");
requireContract(/<nav class="cover-nav" aria-label="NEON Explorer Suite">/.test(main), "suite navigation needs an accessible label");
requireContract(count(main, /<a\b/g) === 2, "poster face must contain only the Driver route and live-app CTA");
requireContract(count(main, /class="suite-jump"/g) === 1, "poster face must contain exactly one Driver route");
requireContract(count(main, /class="button"/g) === 1, "poster face must contain exactly one contextual CTA");
requireContract(count(main, /<figure\b/g) === 1 && count(main, /<figcaption\b/g) === 1, "poster face needs one artwork and one caption");
requireContract(count(main, /<p\b/g) === 2, "poster face must contain only the eyebrow and one-line promise");
requireContract(/NEON My Little Inverts · unofficial/.test(main), "approved eyebrow is missing");
requireContract(/aria-label="What lives below the surface\?"/.test(main), "approved accessible hook is missing");
requireContract(/Explore the aquatic invertebrates NEON recorded in stream, river, and lake-bottom samples\./.test(main), "approved promise is missing");
requireContract(/Choose an aquatic site/.test(main), "approved CTA is missing");
requireContract(/href="https:\/\/019ef4fb-c6c4-7ddf-2667-7e1021b2ef10\.share\.connect\.posit\.cloud\/"/.test(main), "live-app CTA URL drifted");
requireContract(count(main, /https:\/\/tgilbert14\.github\.io\/NEON-Driver-Cascade\//g) === 1, "Driver route is missing or duplicated");
requireContract(/inverts-living-poster-v2-840\.webp 840w, assets\/inverts-living-poster-v2\.webp 1672w/.test(main), "responsive poster WebP set is incomplete");
requireContract(/inverts-living-poster-v2\.png" width="1672" height="941"/.test(main), "poster fallback lacks reviewed dimensions");
requireContract(/fetchpriority="high" decoding="async"/.test(main), "poster artwork priority/decoding attributes drifted");
requireContract(/alt="Editorial screenprint of a mayfly nymph,[^"]+field tags\."/.test(main), "poster artwork needs the reviewed descriptive alt");
requireContract(/Editorial illustration—not a field photograph or data record\./.test(main), "visible art/data boundary is missing");

for (const retired of [
  /constel(?:lation|-sec)?/i,
  /cascade-band/i,
  /class="(?:stats|stat|ghost|launch|frung|flow)"/i,
  /suite directory/i,
  /feature-card/i,
]) {
  requireContract(!retired.test(cover), `retired long-form cover block remains: ${retired}`);
}

// Footer honesty and metadata are compact and remain below the poster.
requireContract(count(cover, /<details class="honesty">/g) === 1, "cover needs one collapsed honesty disclosure");
requireContract(
  /Every non-metabarcoding field opportunity is retained/i.test(cover)
    && /Missing taxon rows remain unknown/i.test(cover)
    && /not a verified zero or absence/i.test(cover),
  "field-first opportunity/zero boundary is missing",
);
requireContract(
  /density is a collection record, not population size/i.test(cover),
  "population boundary is missing",
);
requireContract(
  /EPT composition is descriptive/i.test(cover)
    && /not a water-quality rating/i.test(cover),
  "rating boundary is missing",
);
requireContract(/descriptive, not causal/i.test(cover), "causal boundary is missing");
requireContract(/Explore 34 aquatic sites/.test(cover) && /DP1\.20120\.001/.test(cover), "release scope or data product is missing");
requireContract(/unofficial and not endorsed by NEON, Battelle, or the NSF/.test(cover), "independent-project boundary is missing");
requireContract(/>Source<\/a>/.test(cover) && />Feedback<\/a>/.test(cover), "Source/Feedback links are missing");
requireContract(/href="release\.json">Release receipt<\/a>/.test(cover), "public Pages release receipt link is missing");
requireContract(/rel="canonical" href="https:\/\/tgilbert14\.github\.io\/NEON-My-Little-Inverts\/"/.test(cover), "canonical Pages URL drifted");
requireContract(/og:image" content="https:\/\/tgilbert14\.github\.io\/NEON-My-Little-Inverts\/og-image-v2\.png"/.test(cover), "Open Graph image URL drifted");
requireContract(/og:image:width" content="1200"/.test(cover) && /og:image:height" content="630"/.test(cover), "Open Graph dimensions are missing");
requireContract(/og:image:alt/.test(cover) && /twitter:image:alt/.test(cover), "social image alt metadata is missing");
requireContract(/data-release-marker="inverts-living-poster-v2"/.test(cover), "Pages release marker is missing");
requireContract(/tags\$meta\(name = "ddl-app-ready", content = APP_RELEASE_MARKER\)/.test(ui), "app readiness meta is missing");
requireContract(/tags\$meta\(name = "ddl-release-instance", content = RELEASE_INSTANCE_ID\)/.test(ui), "exact app release-instance meta is missing");

// Both poster surfaces are static and make no remote runtime/prewarm requests.
for (const [name, source] of [["Pages cover", cover], ["app poster CSS", posterCss]]) {
  requireContract(!/@keyframes\b/i.test(source), `${name} must not define keyframes`);
  requireContract(!/\banimation\s*:/i.test(source), `${name} must not animate`);
  requireContract(!/\btransition\s*:/i.test(source), `${name} must not add decorative motion`);
}
requireContract(!/\bfetch\s*\(/.test(cover), "Pages cover must not prewarm or fetch");
requireContract(!/<script\b/i.test(cover), "Pages cover must not contain scripts");
requireContract(!/\son[a-z]+\s*=/i.test(cover), "Pages cover must not contain inline event handlers");
requireContract(!/(?:href|src)\s*=\s*["']\s*javascript:/i.test(cover), "Pages cover must not contain javascript: URLs");
requireContract(!/<script\b[^>]+src=["']https?:/i.test(cover), "Pages cover has a remote script");
requireContract(!/<img\b[^>]+src=["']https?:/i.test(cover), "Pages cover has a remote image");
requireContract(!/<link\b[^>]+rel=["']stylesheet["'][^>]+href=["']https?:/i.test(cover), "Pages cover has a remote stylesheet");
requireContract(!/fonts\.(?:googleapis|gstatic)\.com/i.test(cover), "Pages cover must use local/system fonts");

const bannedPositiveClaims = [
  /tell(?:s)? you (?:a lot )?about the water/i,
  /clean[- ]water (?:signal|bugs|groups)/i,
  /need(?:s)? clean(?:,| )/i,
  /tracks? better conditions/i,
  /the more stressed one/i,
  /read the clean[- ]water signal/i,
  /healthy (?:water|stream|river|lake|site|ecosystem)/i,
];
for (const pattern of bannedPositiveClaims) {
  requireContract(!pattern.test(cover), `Pages cover contains banned positive claim: ${pattern}`);
  requireContract(!pattern.test(firstImpression), `app first impression contains banned positive claim: ${pattern}`);
}

// In-app splash mirrors the public poster, then routes directly to the picker.
requireContract(Boolean(appPoster), "inverts_poster() component is missing");
requireContract(/poster\.css/.test(ui), "app does not load poster.css");
requireContract(/class = "inverts-poster"/.test(appPoster), "app Living Poster class is missing");
requireContract(/aria-labelledby\` = "inverts-poster-title"|\`aria-labelledby\` = "inverts-poster-title"/.test(appPoster), "app poster needs an accessible title relationship");
requireContract(count(appPoster, /\bh1\(/g) === 1, "app poster must contain exactly one h1 constructor");
requireContract(/What lives below the surface\?/.test(appPoster), "app hook diverges from Pages");
requireContract(/Explore the aquatic invertebrates NEON recorded in stream, river, and lake-bottom samples\./.test(appPoster), "app promise diverges from Pages");
requireContract(/Choose an aquatic site/.test(appPoster), "app CTA diverges from Pages");
requireContract(/Public NEON DP1\.20120\.001 · collection records—not verified zeros, population counts, or water-quality scores\./.test(appPoster), "app claim-boundary note drifted");
requireContract(count(appPoster, /NEON-Driver-Cascade\//g) === 1, "app poster must contain exactly one Driver route");
requireContract(/href = "#site-picker-start"/.test(appPoster), "app CTA must route to the picker");
requireContract(/class = "app-skip", href = "#site-picker-start"/.test(ui), "app skip link must route to the picker");
requireContract(/id = "site-picker-start", class = "picker-map-wrap", tabindex = "-1"/.test(firstImpression), "picker must be a focusable CTA target");
requireContract(!/class = "splash-guide"/.test(firstImpression), "floating mascot prompt remains on the first impression");
requireContract(/inverts-living-poster-v2-840\.webp/.test(appPoster) && /inverts-living-poster-v2\.webp/.test(appPoster) && /inverts-living-poster-v2\.png/.test(appPoster), "app responsive art set is incomplete");
requireContract(/alt = paste\(/.test(appPoster)
  && /Editorial screenprint of a mayfly nymph/.test(appPoster)
  && /leaves beside field tags\./.test(appPoster),
  "app poster artwork needs the reviewed descriptive alt");
requireContract(/Editorial illustration—not a field photograph or data record\./.test(appPoster), "app art/data boundary is missing");
requireContract(/@media \(max-width: 900px\)/.test(posterCss), "app poster tablet seam is missing");
requireContract(/@media \(max-width: 420px\) and \(max-height: 860px\)/.test(posterCss), "app poster short-phone seam is missing");
requireContract(/@media \(prefers-reduced-motion: reduce\)/.test(posterCss), "app poster reduced-motion rule is missing");
requireContract(/@media \(prefers-contrast: more\)/.test(posterCss), "app poster contrast rule is missing");
requireContract(/@media \(forced-colors: active\)/.test(posterCss), "app poster forced-colors rule is missing");

// Reviewed, local, byte-identical artwork.
const assets = {
  "docs/assets/inverts-living-poster-v2.png": {
    hash: "28f7d4cf1e7b323b265d22a00cf9e23b9f0cf0614ebe0c1376a04d4c4c500547",
    dimensions: "1672x941",
    kind: "png",
  },
  "docs/assets/inverts-living-poster-v2.webp": {
    hash: "8669baa2fbbc92edf1090a15009fcea7b1fd64ad99d11de7dab42035374346a9",
    dimensions: "1672x941",
    kind: "webp",
    maximum: 600_000,
  },
  "docs/assets/inverts-living-poster-v2-840.webp": {
    hash: "a7ec018bc6b93018d8d9a95c07be57b4b5858a4ad22dbb19d3078c4fe9d53000",
    dimensions: "840x473",
    kind: "webp",
    maximum: 140_000,
  },
  "www/assets/inverts-living-poster-v2.png": {
    hash: "28f7d4cf1e7b323b265d22a00cf9e23b9f0cf0614ebe0c1376a04d4c4c500547",
    dimensions: "1672x941",
    kind: "png",
  },
  "www/assets/inverts-living-poster-v2.webp": {
    hash: "8669baa2fbbc92edf1090a15009fcea7b1fd64ad99d11de7dab42035374346a9",
    dimensions: "1672x941",
    kind: "webp",
    maximum: 600_000,
  },
  "www/assets/inverts-living-poster-v2-840.webp": {
    hash: "a7ec018bc6b93018d8d9a95c07be57b4b5858a4ad22dbb19d3078c4fe9d53000",
    dimensions: "840x473",
    kind: "webp",
    maximum: 140_000,
  },
  "docs/og-image-v2.png": {
    hash: "20850a4a7305064212b5a29e649fe169e20116b27029b684ac41a5be12396ee1",
    dimensions: "1200x630",
    kind: "png",
    maximum: 1_500_000,
  },
};

for (const [path, contract] of Object.entries(assets)) {
  requireContract(existsSync(resolve(root, path)), `missing reviewed image asset ${path}`);
  if (!existsSync(resolve(root, path))) continue;
  requireContract(sha256(path) === contract.hash, `${path} digest drifted`);
  requireContract(provenance.includes(contract.hash), `${path} digest is missing from provenance`);
  const dimensions = contract.kind === "png" ? pngDimensions(path) : webpDimensions(path);
  requireContract(dimensions.join("x") === contract.dimensions, `${path} dimensions are ${dimensions.join("x")}; expected ${contract.dimensions}`);
  if (contract.maximum) {
    requireContract(statSync(resolve(root, path)).size <= contract.maximum, `${path} exceeds ${contract.maximum} bytes`);
  }
}

for (const filename of [
  "inverts-living-poster-v2.png",
  "inverts-living-poster-v2.webp",
  "inverts-living-poster-v2-840.webp",
]) {
  const docsBytes = readFileSync(resolve(root, "docs/assets", filename));
  const wwwBytes = readFileSync(resolve(root, "www/assets", filename));
  requireContract(docsBytes.equals(wwwBytes), `docs/www copies differ for ${filename}`);
}

requireContract(/built-in\s+ImageGen workflow/i.test(provenance), "provenance must name the built-in ImageGen workflow");
requireContract(/Use case: stylized-concept/.test(provenance), "provenance is missing the final prompt");
requireContract(/not a field photograph/i.test(provenance) && /not[\s\S]{0,180}data visualization/i.test(provenance), "provenance lacks the editorial/non-data boundary");
requireContract(/node scripts\/check_cover\.mjs/.test(workflow), "cover checker is not wired into CI");
requireContract(/node --check scripts\/post_deploy_browser\.mjs/.test(workflow), "browser probe syntax check is not wired into CI");
requireContract(/INV_MANIFEST_PHASE=prestamp/.test(workflow)
  && /bash scripts\/test_post_deploy_smoke\.sh/.test(workflow)
  && /INV_RELEASE_IDENTITY_MODE=write INV_WRITE_PAGES_RELEASE=1/.test(workflow)
  && /INV_MANIFEST_PHASE=final/.test(workflow)
  && /INV_RELEASE_IDENTITY_MODE=verify INV_WRITE_PAGES_RELEASE=1/.test(workflow)
  && /Reject a stale committed identity on pull requests/.test(workflow),
"clean validator does not generate and reverify the exact production identity");
requireContract(/release\/production-identity\.json/.test(identityWriter)
  && /docs["', ]+release\.json|docs", "release\.json/.test(identityWriter),
"identity writer does not publish both runtime and Pages receipts");
requireContract(/INV_MANIFEST_PHASE/.test(manifestWriter)
  && /release\/production-identity\.json/.test(manifestWriter),
"Connect manifest lacks the prestamp/final identity cycle break");
requireContract(/branches: \[main\]/.test(postDeployWorkflow)
  && /INV_RELEASE_IDENTITY_MODE=verify INV_WRITE_PAGES_RELEASE=1/.test(postDeployWorkflow)
  && /bash scripts\/post_deploy_smoke\.sh/.test(postDeployWorkflow)
  && /npm ci --ignore-scripts --no-audit --no-fund/.test(postDeployWorkflow)
  && /node scripts\/post_deploy_browser\.mjs/.test(postDeployWorkflow),
"content-aware post-deploy workflow is not wired to main");
requireContract(npmPackage.private === true
  && npmPackage.scripts?.["check:cover"] === "node scripts/check_cover.mjs"
  && npmPackage.devDependencies?.playwright === "1.55.0"
  && npmLock.lockfileVersion === 3
  && npmLock.packages?.["node_modules/playwright"]?.version === "1.55.0"
  && npmLock.packages?.["node_modules/playwright"]?.integrity
    === "sha512-sdCWStblvV1YU909Xqx0DhOjPZE4/5lJsIS84IfN9dAZfcl/CIZ5O8l3o0j7hPMjDvqoTF8ZUcc+i/GL5erstA=="
  && npmLock.packages?.["node_modules/playwright-core"]?.version === "1.55.0"
  && npmLock.packages?.["node_modules/playwright-core"]?.integrity
    === "sha512-GvZs4vU3U5ro2nZpeiwyb0zuFaqb9sUiAJuyrWpcGouD8y9/HLgGbNRjIph7zU9D3hnPaisMl9zG9CgFi/biIg==",
"post-deploy Playwright dependency tree is not version- and integrity-locked");
requireContract(/ddl-release-instance/.test(postDeploySmoke)
  && /release\.json/.test(postDeploySmoke)
  && /startup error\|application failed to start\|service unavailable/i.test(postDeploySmoke),
"post-deploy verifier does not require exact identity and reject host error pages");
requireContract(/#nationalPicker/.test(postDeployBrowser)
  && /shiny-bound-output/.test(postDeployBrowser)
  && /#siteCards/.test(postDeployBrowser)
  && /codes\.length === canonicalSites\.length/.test(postDeployBrowser)
  && /new Set\(codes\)\.size === canonicalSites\.length/.test(postDeployBrowser)
  && /canonicalSites\.every/.test(postDeployBrowser)
  && /\.synth-banner/.test(postDeployBrowser)
  && /hasText: "SYCA"/.test(postDeployBrowser)
  && /field opportunities/.test(postDeployBrowser)
  && /value > 0/.test(postDeployBrowser)
  && /#help/.test(postDeployBrowser)
  && /How to read My Little Inverts/.test(postDeployBrowser)
  && /ddl-release-instance/.test(postDeployBrowser),
"post-deploy browser gate does not prove an exact live Shiny round trip");
requireContract(/const pagesFiles = \[/.test(postDeployBrowser)
  && /docs\/index\.html/.test(postDeployBrowser)
  && /docs\/og-image-v2\.png/.test(postDeployBrowser)
  && /docs\/assets\/inverts-living-poster-v2-840\.webp/.test(postDeployBrowser)
  && /verifyExactPagesBytes/.test(postDeployBrowser)
  && /observedHash !== expectedHash/.test(postDeployBrowser),
  "post-deploy browser gate does not byte-verify the reviewed Pages surface");
requireContract(/width: 1280, height: 900/.test(postDeployBrowser)
  && /width: 390, height: 844/.test(postDeployBrowser)
  && /width: 320, height: 568/.test(postDeployBrowser)
  && /horizontalOverflow/.test(postDeployBrowser)
  && /headerOverlap/.test(postDeployBrowser)
  && /requireKeyboardFocus/.test(postDeployBrowser)
  && /naturalWidth > 0/.test(postDeployBrowser),
  "post-deploy browser gate does not render-check Pages at desktop/390/320");
requireContract(/page\.on\("console"/.test(postDeployBrowser)
  && /page\.on\("pageerror"/.test(postDeployBrowser)
  && /page\.on\("requestfailed"/.test(postDeployBrowser)
  && /response\.status\(\) >= 400/.test(postDeployBrowser)
  && /sameOrigin\(response\.url\(\), expectedOrigin\)/.test(postDeployBrowser)
  && /appSurface\.artLoaded/.test(postDeployBrowser)
  && /appSurface\.posterCss/.test(postDeployBrowser),
  "post-deploy Connect gate does not reject browser/resource/render failures");
const browserRosterBlock = postDeployBrowser.match(
  /const expectedSites = \[([\s\S]*?)\];/,
);
const browserRoster = browserRosterBlock
  ? [...browserRosterBlock[1].matchAll(/"([A-Z]{4})"/g)].map((match) => match[1])
  : [];
requireContract(JSON.stringify(browserRoster) === JSON.stringify(expectedBrowserSites),
  "post-deploy browser gate does not require the exact canonical 34-site roster");
const browserOpenIndex = postDeployBrowser.indexOf("details.site-browse > summary");
const browserRosterIndex = postDeployBrowser.indexOf('document.querySelector("#siteCards")');
const browserSycaIndex = postDeployBrowser.indexOf('hasText: "SYCA"');
requireContract(browserOpenIndex >= 0
  && browserOpenIndex < browserRosterIndex
  && browserRosterIndex < browserSycaIndex,
"post-deploy browser gate must open the suspended roster before checking and loading it");

// Responsive/accessibility contracts on the static face.
requireContract(/\.button \{[\s\S]{0,160}min-height: 52px/.test(cover), "Pages CTA must be at least 52px high");
requireContract(/\.suite-jump \{[\s\S]{0,160}min-height: 44px/.test(cover), "Pages Driver route must be at least 44px high");
requireContract(/\.honesty summary \{[\s\S]{0,180}min-height: 44px/.test(cover), "Pages honesty disclosure must be at least 44px high");
requireContract(/@media \(max-width: 700px\)/.test(cover), "Pages mobile seam is missing");
requireContract(/@media \(max-width: 420px\) and \(max-height: 860px\)/.test(cover), "Pages short-phone seam is missing");
requireContract(/@media \(max-width: 340px\)/.test(cover), "Pages narrow-phone seam is missing");
requireContract(/@media \(prefers-reduced-motion: reduce\)/.test(cover), "Pages reduced-motion rule is missing");
requireContract(/@media \(prefers-contrast: more\)/.test(cover), "Pages high-contrast rule is missing");
requireContract(/@media \(forced-colors: active\)/.test(cover), "Pages forced-colors rule is missing");

if (errors.length) {
  for (const message of errors) console.error(`FAIL: ${message}`);
  process.exit(1);
}

console.log("OK: compact static and in-app Inverts Living Posters, local reviewed artwork, claim boundaries, metadata, responsive seams, and CI wiring passed.");
