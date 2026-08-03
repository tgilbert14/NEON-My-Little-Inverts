#!/usr/bin/env bash
set -euo pipefail

pages="https://tgilbert14.github.io/NEON-My-Little-Inverts/"
app="https://019ef4fb-c6c4-7ddf-2667-7e1021b2ef10.share.connect.posit.cloud/"
pages_marker="inverts-living-poster-v2"
app_marker="my-little-inverts-release-2026-v1"
identity_path="${INV_PRODUCTION_IDENTITY_PATH:-release/production-identity.json}"
error_pattern='startup error|application failed to start|service unavailable|page not found|there isn.t a github pages site here|<title>[^<]*(404|error)|cannot connect to the server'

body_has_host_error() {
  grep -Eiq "$error_pattern" <<<"$1"
}

pages_body_ready() {
  local body="$1"
  grep -Fq "$pages_marker" <<<"$body" &&
    grep -Fq "DP1.20120.001" <<<"$body" &&
    ! body_has_host_error "$body"
}

app_body_ready() {
  local body="$1"
  local release_id="$2"
  grep -Fq "$app_marker" <<<"$body" &&
    grep -Fq "DP1.20120.001" <<<"$body" &&
    grep -Fq 'name="ddl-app-ready"' <<<"$body" &&
    grep -Fq 'name="ddl-release-instance"' <<<"$body" &&
    grep -Fq "$release_id" <<<"$body" &&
    ! body_has_host_error "$body"
}

receipt_ready() {
  local receipt="$1"
  local expected_sha256="$2"
  local release_id="$3"
  local observed_sha256
  observed_sha256=$(python3 -c '
import hashlib, pathlib, sys
path = pathlib.Path(sys.argv[1])
print(hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else "")
' "$receipt")
  [[ "$observed_sha256" == "$expected_sha256" ]] &&
    grep -Fq "$release_id" "$receipt" &&
    ! body_has_host_error "$(<"$receipt")"
}

if [[ "${INV_POST_DEPLOY_LIBRARY_ONLY:-0}" == "1" ]]; then
  return 0 2>/dev/null || exit 0
fi

if [[ ! -s "$identity_path" ]]; then
  echo "Missing committed production identity: $identity_path" >&2
  exit 1
fi

expected_release_id=$(python3 -c '
import hashlib, json, re, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    identity = json.load(handle)
fields = [
    "schema_version", "app_id", "product", "release", "doi",
    "source_artifact_sha256", "source_receipt_sha256",
    "release_contract_sha256", "bundle_family_sha256", "site_index_sha256",
    "cross_site_sha256", "search_index_sha256", "demo_bundle_sha256",
    "runtime_payload_sha256", "pages_payload_sha256",
    "manifest_contract_sha256", "manifest_source_list_sha256", "release_id",
]
if list(identity) != fields or identity.get("schema_version") != 1:
    raise SystemExit("invalid production-identity schema")
if (identity.get("app_id") != "NEON-My-Little-Inverts" or
        identity.get("product") != "DP1.20120.001" or
        identity.get("release") != "RELEASE-2026" or
        identity.get("doi") != "10.48443/hp56-s582"):
    raise SystemExit("invalid production-identity contract")
for field in fields[5:17]:
    if not re.fullmatch(r"[0-9a-f]{64}", identity.get(field, "")):
        raise SystemExit(f"invalid {field}")
material = "\n".join([
    "neon-my-little-inverts-production-instance-v1",
    *[str(identity[field]) for field in fields[1:17]],
])
expected = "sha256:" + hashlib.sha256(material.encode("utf-8")).hexdigest()
if identity.get("release_id") != expected:
    raise SystemExit("release_id does not independently re-derive")
print(expected)
' "$identity_path")

expected_receipt_sha256=$(python3 -c '
import hashlib, sys
with open(sys.argv[1], "rb") as handle:
    print(hashlib.sha256(handle.read()).hexdigest())
' "$identity_path")

temporary=$(mktemp -d)
trap 'rm -rf -- "$temporary"' EXIT
deadline=$((SECONDS + 900))
attempt=0

while (( SECONDS < deadline )); do
  attempt=$((attempt + 1))
  revision="${GITHUB_SHA:-manual}-$attempt"
  pages_body=$(curl --fail --silent --show-error --location --max-time 20 \
    --header "Cache-Control: no-cache" "${pages}?verify=${revision}" || true)
  app_body=$(curl --fail --silent --show-error --location --max-time 35 \
    --header "Cache-Control: no-cache" "${app}?verify=${revision}" || true)
  receipt_file="$temporary/pages-release.json"
  if ! curl --fail --silent --show-error --location --max-time 20 \
      --header "Cache-Control: no-cache" \
      --output "$receipt_file" "${pages}release.json?verify=${revision}"; then
    : > "$receipt_file"
  fi

  pages_ready=false
  pages_receipt_ready=false
  app_ready=false
  if pages_body_ready "$pages_body"; then
    pages_ready=true
  fi
  if receipt_ready "$receipt_file" "$expected_receipt_sha256" \
      "$expected_release_id"; then
    pages_receipt_ready=true
  fi
  if app_body_ready "$app_body" "$expected_release_id"; then
    app_ready=true
  fi

  if [[ "$pages_ready" == true && "$pages_receipt_ready" == true &&
        "$app_ready" == true ]]; then
    echo "OK: Pages and Connect initial HTTP responses serve exact production instance $expected_release_id."
    exit 0
  fi
  echo "Attempt $attempt: waiting for exact Pages + Connect identity (pages=$pages_ready receipt=$pages_receipt_ready app=$app_ready)..."
  sleep 15
done

echo "Production did not expose the exact validated Pages + Connect identity in 15 minutes." >&2
exit 1
