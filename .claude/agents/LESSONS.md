# Lessons (NEON My Little Inverts)

One line per durable lesson: `- [date] role · status · lesson`.

- [2026-10-21] neonize · confirmed · bslib::page_fillable() has no window_title or fillable argument; both land on <body> and the page ships with no <title> or lang. Use title = and lang = "en", and assert both in the post-deploy smoke.
- [2026-10-21] neonize · confirmed · This repo's manifest.json, release/production-identity.json and docs/release.json come only from the pinned CI validator: dispatch refresh-data.yml with skip_download=true on the source branch, download its invert-refresh-<sha> artifact, and commit those three files. A macOS manifest never matches (package DESCRIPTION fields differ), and every root docs/*.md edit except docs/BUILD-TEST-HANDOFF.md changes the identity.
- [2026-10-21] neonize · confirmed · check_cover.mjs pinned the em-dash poster note as approved copy, so the cover gate enforced the opposite of the copy rule. Pin the caveat's words; forbid the punctuation.
- [2026-10-21] aquatics · gap · In DP1.20120.001 a blank order is not always an above-order ID: genus or species snails (Galba, Amnicola), a mite genus (Stygothrombium) and an oligochaete carry no order. Label the support line "assigned to an order" and re-verify "no insect lacks an order" each release before claiming unknown-order counts cannot be EPT.
- [2026-10-21] aquatics · confirmed · Join field dataQF to the opportunity ledger on the field-row identity, not sampleID (blank on most uncollected rows); leave samplerType out of the key because the ledger writes "(not recorded)" where the verbatim layer is blank. Count flags only among the samples behind a plotted point, and show legacyData without marking it.
- [2026-10-21] page · confirmed · DataTables' Bootstrap 5 pagination is nowrap; on a 375 px phone its Next button pushed QC cards 44 px wide. Wrap ul.pagination inside .card-body.
