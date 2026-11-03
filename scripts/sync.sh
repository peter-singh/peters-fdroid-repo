#!/usr/bin/env bash
# Publish the latest GitHub release of each app below to this F-Droid repo.
#   scripts/sync.sh              download, sign the index, commit and push
#   scripts/sync.sh --no-push    stop before committing
# The repo signing key stays on this Mac (fdroid/keystore.p12), so this runs here, not in CI.
set -euo pipefail

# GitHub repo | release asset pattern | SHA-256 of the signing certificate
APPS=(
  "peter-singh/tv-app|vod-*.apk|ad4cc2a54766dd701cca4ad31fd6d7d0c343511c289cb7d256b3384a55ae3001"
  "peter-singh/shopping-list|scran-*-list.prd.scot.apk|1a2927a1189c9a2f1738dd7e531a13b6cb69ecec40bdc4bf9467a1c6dca1ded9"
)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
export PATH="$JAVA_HOME/bin:$PATH"
build_tools="$(printf '%s\n' "$ANDROID_HOME"/build-tools/* | sort -V | tail -n1)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
added=()

for app in "${APPS[@]}"; do
  IFS='|' read -r repo pattern cert <<< "$app"
  tag="$(gh release list -R "$repo" --exclude-drafts --limit 1 --json tagName --jq '.[0].tagName')"
  dir="$tmp/${repo##*/}"; mkdir -p "$dir"
  gh release download "$tag" -R "$repo" -p "$pattern" -D "$dir"
  apk="$(printf '%s\n' "$dir"/*.apk | head -n1)"

  # A different key could never update installed copies, and a debuggable build shouldn't be public.
  actual="$("$build_tools/apksigner" verify --print-certs "$apk" 2>/dev/null | sed -n 's/^Signer #1 certificate SHA-256 digest: //p')"
  if [ "$actual" != "$cert" ]; then echo "sync: $repo $tag has the wrong signing certificate: $actual" >&2; exit 1; fi
  badging="$("$build_tools/aapt2" dump badging "$apk")"
  if grep -q '^application-debuggable' <<< "$badging"; then echo "sync: $repo $tag is debuggable, refusing to publish" >&2; exit 1; fi

  package="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" <<< "$badging")"
  code="$(sed -n "s/.*versionCode='\([0-9]*\)'.*/\1/p" <<< "$badging" | head -n1)"
  target="$ROOT/fdroid/repo/${package}_${code}.apk"
  if [ -e "$target" ]; then echo "sync: $package $code already published"; continue; fi
  cp "$apk" "$target"
  added+=("$package $tag")
done

if [ ${#added[@]} -eq 0 ]; then echo "sync: nothing new"; exit 0; fi
(cd "$ROOT/fdroid" && fdroid update)
if [ "${1:-}" = "--no-push" ]; then echo "sync: ready to commit: ${added[*]}"; exit 0; fi
git -C "$ROOT" add -A
git -C "$ROOT" commit -m "Publish ${added[*]}"
git -C "$ROOT" push origin main
