#!/usr/bin/env bash
#
# Deploy the Lily Hair and Beauty House site to Cloudflare Pages.
#
#   ./deploy.sh              stage dist/ and deploy it
#   ./deploy.sh --stage-only stage dist/ only (no login, no upload)
#
# There is no build step — index.html is the whole site. "Staging" just means
# copying the files that should be public into dist/, so the unused legacy
# assets still sitting in the repo never reach a public URL.
#
# Override defaults with env vars:
#   PROJECT_NAME=lily-hair-beauty BRANCH=main ./deploy.sh
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-lily-hair-beauty}"
BRANCH="${BRANCH:-main}"

STAGE_ONLY=0
case "${1:-}" in
  --stage-only) STAGE_ONLY=1 ;;
  "") ;;
  *) echo "✗ Unknown option '$1'. Usage: ./deploy.sh [--stage-only]" >&2; exit 1 ;;
esac

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SRC_DIR/dist"

# --- Locate wrangler ---------------------------------------------------------
# Reuses the copy pinned in the baratech repo when it is checked out alongside
# this one, so both sites deploy with the same version.
BARATECH_WRANGLER="$SRC_DIR/../../baratech/baratech-landing/node_modules/.bin/wrangler"
if [ -x "$SRC_DIR/node_modules/.bin/wrangler" ]; then
  WRANGLER=("$SRC_DIR/node_modules/.bin/wrangler")
elif [ -x "$BARATECH_WRANGLER" ]; then
  WRANGLER=("$BARATECH_WRANGLER")
elif command -v wrangler >/dev/null 2>&1; then
  WRANGLER=(wrangler)
elif command -v npx >/dev/null 2>&1; then
  echo "→ wrangler not found locally; using 'npx wrangler@latest'"
  WRANGLER=(npx --yes wrangler@latest)
else
  echo "✗ wrangler not found. Install Node.js, or run 'npm i -D wrangler' here." >&2
  exit 1
fi

# --- Stage a clean dist/ -----------------------------------------------------
echo "→ Staging dist/ …"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/images" "$DIST_DIR/assets"

cp "$SRC_DIR/index.html" "$DIST_DIR/"
# Without a 404.html, Pages serves index.html with a 200 for every unknown URL,
# which reads to search engines as thousands of duplicate pages (soft 404s).
[ -f "$SRC_DIR/404.html" ] && cp "$SRC_DIR/404.html" "$DIST_DIR/"
[ -f "$SRC_DIR/_headers" ] && cp "$SRC_DIR/_headers" "$DIST_DIR/"

# Only the studio look set is referenced. images/h_s_*.jpeg and images/h_s_3.webp
# are the retired stock photos — scraped shots of identifiable people, one of them
# a public figure. They must never be published from a commercial salon site.
cp -R "$SRC_DIR/images/hair_styles" "$DIST_DIR/images/"
cp -R "$SRC_DIR/images/cards" "$DIST_DIR/images/"   # faded service-card backgrounds (single size; kept out of the six-variant check)

# assets/hero/ is a superseded render set that nothing on the page references.
# lily-logo.png is the design source and is not referenced by the page — not published.
for f in lily-logo-220.webp lily-logo-440.webp favicon-96.png apple-touch-icon.png; do
  [ -f "$SRC_DIR/assets/$f" ] && cp "$SRC_DIR/assets/$f" "$DIST_DIR/assets/"
done

# Strip dot-files that rode along with cp -R (.DS_Store and friends). Anything
# left in dist/ gets served at a public URL.
find "$DIST_DIR" -name '.*' -prune -exec rm -rf {} + 2>/dev/null || true

# Fail loudly rather than publish something credential-shaped or a retired photo.
LEAKED="$(find "$DIST_DIR" \( -name '.*' -o -name '*.pem' -o -name '*.key' -o -name 'h_s_*' \) -print 2>/dev/null || true)"
if [ -n "$LEAKED" ]; then
  echo "✗ Refusing to stage — unexpected files in dist/:" >&2
  echo "$LEAKED" >&2
  exit 1
fi

# Every <picture> assumes all six variants exist for a look; a missing one is a
# broken image on someone's phone, which is invisible from here.
MISSING=0
while IFS= read -r base; do
  for w in 400 800 1200; do
    for ext in avif webp; do
      [ -f "$DIST_DIR/images/hair_styles/${base}-${w}.${ext}" ] || { echo "✗ missing ${base}-${w}.${ext}" >&2; MISSING=1; }
    done
  done
done < <(ls "$DIST_DIR/images/hair_styles" | sed -E 's/-(400|800|1200)\.(avif|webp)$//' | sort -u)
[ "$MISSING" -eq 0 ] || { echo "✗ Refusing to deploy with missing image variants." >&2; exit 1; }

echo "   $(find "$DIST_DIR" -type f | wc -l | tr -d ' ') files, $(du -sh "$DIST_DIR" | cut -f1)"

if [ "$STAGE_ONLY" -eq 1 ]; then
  echo "✓ Staged into dist/ (not deployed)."
  exit 0
fi

# --- Authenticate + ensure the project exists --------------------------------
if "${WRANGLER[@]}" whoami >/dev/null 2>&1; then
  echo "✓ Already logged in to Cloudflare."
else
  echo "→ Not logged in. Opening a browser to authenticate…"
  "${WRANGLER[@]}" login
fi

if ! "${WRANGLER[@]}" pages project list 2>/dev/null | grep -qw "$PROJECT_NAME"; then
  echo "→ Creating Pages project '$PROJECT_NAME' (production branch: $BRANCH)…"
  "${WRANGLER[@]}" pages project create "$PROJECT_NAME" --production-branch "$BRANCH"
fi

# --- Deploy ------------------------------------------------------------------
echo "→ Deploying to Cloudflare Pages project '$PROJECT_NAME'…"
cd "$SRC_DIR"
"${WRANGLER[@]}" pages deploy "$DIST_DIR" \
  --project-name "$PROJECT_NAME" \
  --branch "$BRANCH" \
  --commit-dirty=true

echo
echo "✓ Done — https://lily-beauty.baratech.my/"
