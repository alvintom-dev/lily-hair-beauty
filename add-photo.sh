#!/usr/bin/env bash
#
# Prepare one photo for the website, in all six sizes the page needs.
#
#   ./add-photo.sh <photo> <short-name>
#   ./add-photo.sh ~/Desktop/new.jpg 07-soft-perm
#
# Produces images/hair_styles/<short-name>-{400,800,1200}.{avif,webp}.
# AVIF is roughly 40% smaller than WebP; browsers that don't understand AVIF fall
# back to the WebP on their own, which is why both are made.
set -uo pipefail

SRC="${1:-}"
NAME="${2:-}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/images/hair_styles"

die(){ echo "✗ $1" >&2; [ $# -gt 1 ] && echo "  $2" >&2; exit 1; }

if [ -z "$SRC" ] || [ -z "$NAME" ]; then
  cat >&2 <<USAGE
Usage: ./add-photo.sh <photo> <short-name>

  <photo>       the picture on your computer, e.g. ~/Desktop/new.jpg
  <short-name>  lowercase, hyphens instead of spaces, e.g. 07-soft-perm

Example:
  ./add-photo.sh ~/Desktop/new.jpg 07-soft-perm
USAGE
  exit 1
fi

[ -f "$SRC" ] || die "Can't find that photo: $SRC"

# A name with spaces or capitals becomes a broken image link that is very hard to
# spot later, so refuse it here rather than publish it.
printf '%s' "$NAME" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' \
  || die "'$NAME' won't work as a name." "Use lowercase letters, numbers and hyphens only — e.g. 07-soft-perm"

for tool in sips cwebp avifenc; do
  command -v "$tool" >/dev/null 2>&1 \
    || die "Missing '$tool'." "Run this once, then try again:  brew install webp libavif"
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FLAT="$TMP/source.png"

# Convert to PNG once up front. sips handles JPEG/PNG/HEIC/TIFF; WebP and AVIF
# each need their own decoder, so try those before giving up.
if   sips -s format png "$SRC" --out "$FLAT" >/dev/null 2>&1; then :
elif command -v dwebp   >/dev/null 2>&1 && dwebp -quiet "$SRC" -o "$FLAT" >/dev/null 2>&1; then :
elif command -v avifdec >/dev/null 2>&1 && avifdec --quiet "$SRC" "$FLAT" >/dev/null 2>&1; then :
else
  die "Couldn't read that image." "JPEG, PNG and HEIC work best. For WebP or AVIF: brew install webp libavif"
fi

W=$(sips -g pixelWidth  "$FLAT" 2>/dev/null | awk '/pixelWidth/{print $2}')
H=$(sips -g pixelHeight "$FLAT" 2>/dev/null | awk '/pixelHeight/{print $2}')
[ -n "${W:-}" ] && [ -n "${H:-}" ] || die "That file doesn't look like an image."

echo "→ Source: ${W}x${H}"
[ "$W" -ge 1200 ] || echo "  ! Only ${W}px wide. Under 1200px the largest size will look soft."
[ "$H" -gt "$W" ] || echo "  ! This is a landscape photo. The site shows portraits, so the sides will be cropped off."

compgen -G "$DIR/$NAME-*" >/dev/null && echo "  ! '$NAME' already exists — replacing it."

# The page frames every photo at 4:5. Crop to that shape first, then scale — resizing
# straight to 4:5 would stretch the picture instead of cropping it.
if [ $(( W * 5 )) -gt $(( H * 4 )) ]; then      # wider than 4:5 -> trim the sides
  CW=$(( H * 4 / 5 )); CH=$H
else                                            # taller than 4:5 -> trim top and bottom
  CW=$W; CH=$(( W * 5 / 4 ))
fi
sips -c "$CH" "$CW" "$FLAT" --out "$TMP/crop.png" >/dev/null 2>&1 \
  || die "Couldn't crop that image to the 4:5 shape the site uses."

echo "→ Making six sizes…"
for TARGET in 400 800 1200; do
  TALL=$(( TARGET * 5 / 4 ))
  sips -z "$TALL" "$TARGET" "$TMP/crop.png" --out "$TMP/out.png" >/dev/null 2>&1 \
    || die "Resizing to ${TARGET}px failed."
  cwebp -quiet -q 72 -m 6 -sharp_yuv "$TMP/out.png" -o "$DIR/$NAME-$TARGET.webp" \
    || die "Making the ${TARGET}px WebP failed."
  avifenc --min 0 --max 63 -a end-usage=q -a cq-level=32 -a tune=ssim -s 4 -j all \
    "$TMP/out.png" "$DIR/$NAME-$TARGET.avif" >/dev/null 2>&1 \
    || die "Making the ${TARGET}px AVIF failed."
  printf "   %4spx   webp %-6s  avif %s\n" "$TARGET" \
    "$(du -h "$DIR/$NAME-$TARGET.webp" | cut -f1 | tr -d ' ')" \
    "$(du -h "$DIR/$NAME-$TARGET.avif" | cut -f1 | tr -d ' ')"
done

cat <<DONE

✓ Six files created in images/hair_styles/

Next, to show it on the site:
  1. Open index.html and search for:  var LOOKS
  2. Copy one of the entries there and change its details, using:
        file: IMG + '$NAME'
  3. Save, then run:  ./deploy.sh
DONE
