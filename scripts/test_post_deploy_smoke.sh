#!/usr/bin/env bash
set -euo pipefail

temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT

fail() {
  echo "Post-deploy fixture failed: $1" >&2
  exit 1
}

# Missing and malformed local identities must fail before any network request.
if INV_PRODUCTION_IDENTITY_PATH="$temporary/missing.json" \
    bash scripts/post_deploy_smoke.sh >/dev/null 2>&1; then
  fail "missing identity was accepted"
fi
printf '%s\n' '{"schema_version":99}' > "$temporary/bad-schema.json"
if INV_PRODUCTION_IDENTITY_PATH="$temporary/bad-schema.json" \
    bash scripts/post_deploy_smoke.sh >/dev/null 2>&1; then
  fail "invalid identity schema was accepted"
fi

python3 - "$temporary/bad-id.json" <<'PY'
import json, sys
fields = [
    "source_artifact_sha256", "source_receipt_sha256",
    "release_contract_sha256", "bundle_family_sha256", "site_index_sha256",
    "cross_site_sha256", "search_index_sha256", "demo_bundle_sha256",
    "runtime_payload_sha256", "pages_payload_sha256",
    "manifest_contract_sha256", "manifest_source_list_sha256",
]
identity = {
    "schema_version": 1,
    "app_id": "NEON-My-Little-Inverts",
    "product": "DP1.20120.001",
    "release": "RELEASE-2026",
    "doi": "10.48443/hp56-s582",
}
for field in fields:
    identity[field] = "a" * 64
identity["release_id"] = "sha256:" + "0" * 64
with open(sys.argv[1], "w", encoding="utf-8") as handle:
    json.dump(identity, handle, separators=(",", ":"))
PY
if INV_PRODUCTION_IDENTITY_PATH="$temporary/bad-id.json" \
    bash scripts/post_deploy_smoke.sh >/dev/null 2>&1; then
  fail "non-derivable release ID was accepted"
fi

# Load only the pure body/receipt classifiers; no network or committed identity.
export INV_POST_DEPLOY_LIBRARY_ONLY=1
# shellcheck disable=SC1091
source scripts/post_deploy_smoke.sh
unset INV_POST_DEPLOY_LIBRARY_ONLY

release_id="sha256:$(printf '1%.0s' {1..64})"
valid_pages='<html data-release-marker="inverts-living-poster-v2">DP1.20120.001</html>'
pages_body_ready "$valid_pages" || fail "valid Pages marker was rejected"
pages_body_ready "$valid_pages service unavailable" &&
  fail "Pages host-error shell with spoofed markers was accepted"

valid_app="<meta name=\"ddl-app-ready\" content=\"my-little-inverts-release-2026-v1\"><meta name=\"ddl-release-instance\" content=\"$release_id\">DP1.20120.001"
app_body_ready "$valid_app" "$release_id" || fail "valid app identity was rejected"
app_body_ready "$valid_app application failed to start" "$release_id" &&
  fail "Connect error shell with spoofed markers was accepted"
app_body_ready "$valid_app" "sha256:$(printf '2%.0s' {1..64})" &&
  fail "wrong Connect release ID was accepted"

printf '%s\n' "{\"release_id\":\"$release_id\"}" > "$temporary/receipt.json"
receipt_sha256=$(python3 -c '
import hashlib, sys
with open(sys.argv[1], "rb") as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
' "$temporary/receipt.json")
receipt_ready "$temporary/receipt.json" "$receipt_sha256" "$release_id" ||
  fail "byte-exact Pages receipt was rejected"
receipt_ready "$temporary/receipt.json" "$(printf '0%.0s' {1..64})" "$release_id" &&
  fail "Pages receipt hash mismatch was accepted"
printf '%s\n' "{\"release_id\":\"$release_id\",\"error\":\"service unavailable\"}" > "$temporary/error-receipt.json"
error_receipt_sha256=$(python3 -c '
import hashlib, sys
with open(sys.argv[1], "rb") as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
' "$temporary/error-receipt.json")
receipt_ready "$temporary/error-receipt.json" "$error_receipt_sha256" \
  "$release_id" && fail "error-page receipt with matching hash was accepted"

echo "OK: post-deploy schema, exact-ID, receipt, and host-error rejection fixtures passed."
