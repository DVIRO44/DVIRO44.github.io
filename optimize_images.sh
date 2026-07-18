#!/usr/bin/env bash
#
# optimize_images.sh — batch-convert dish photos to optimized WebP.
#
# SAFETY: never modifies, renames, moves, or deletes anything in images/.
#   It only READS the originals and WRITES new .webp files into images/optimized/.
#   Delete that folder to undo; re-run any time (it skips images already up to date).
#
# Requires: cwebp  (brew install webp)   and   sips (built into macOS, for dimensions).
#
# Usage:
#   ./optimize_images.sh                 # images/  ->  images/optimized/
#   ./optimize_images.sh --dry-run       # show the plan, write nothing
#   ./optimize_images.sh --force         # rebuild even if output is up to date
#   MAX_EDGE=1200 QUALITY=82 ./optimize_images.sh    # tune longest edge / quality
#
set -eo pipefail

SRC_DIR="${SRC_DIR:-images}"
OUT_DIR="${OUT_DIR:-images/optimized}"
MAX_EDGE="${MAX_EDGE:-1600}"   # cap the longest edge (px); never upscales
QUALITY="${QUALITY:-80}"       # cwebp quality 0-100; ~80 is visually lossless for photos
FORCE=0; DRY=0

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }
for a in "$@"; do
  case "$a" in
    --force)   FORCE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $a" >&2; usage; exit 2 ;;
  esac
done

command -v cwebp >/dev/null || { echo "error: cwebp not found. Install with:  brew install webp" >&2; exit 1; }
command -v sips  >/dev/null || { echo "error: sips not found (expected on macOS)." >&2; exit 1; }
[ -d "$SRC_DIR" ] || { echo "error: source dir '$SRC_DIR' not found." >&2; exit 1; }

human() { awk -v b="${1:-0}" 'BEGIN{ split("B KB MB GB",u); i=1; while(b>=1024&&i<4){b/=1024;i++} printf "%.1f %s", b, u[i] }'; }
filesize() { stat -f%z "$1" 2>/dev/null || echo 0; }

mkdir -p "$OUT_DIR"

total_in=0; total_out=0; converted=0; skipped=0; count=0

# -maxdepth 1 keeps us out of images/optimized/; -print0 + read -d '' handle spaces & Hebrew names safely.
while IFS= read -r -d '' src; do
  count=$((count+1))
  base="$(basename "$src")"
  out="$OUT_DIR/${base%.*}.webp"

  if [ "$FORCE" -eq 0 ] && [ -f "$out" ] && [ "$out" -nt "$src" ]; then
    skipped=$((skipped+1)); continue
  fi

  w="$(sips -g pixelWidth  "$src" 2>/dev/null | awk '/pixelWidth:/{print $2}')"
  h="$(sips -g pixelHeight "$src" 2>/dev/null | awk '/pixelHeight:/{print $2}')"

  resize=()
  if [ -n "$w" ] && [ -n "$h" ]; then
    if   [ "$w" -ge "$h" ] && [ "$w" -gt "$MAX_EDGE" ]; then resize=(-resize "$MAX_EDGE" 0)
    elif [ "$h" -gt "$w" ] && [ "$h" -gt "$MAX_EDGE" ]; then resize=(-resize 0 "$MAX_EDGE")
    fi
  fi

  in_sz="$(filesize "$src")"

  if [ "$DRY" -eq 1 ]; then
    printf "  would build  %-42s  %9s  (%sx%s)\n" "$base" "$(human "$in_sz")" "${w:-?}" "${h:-?}"
    total_in=$((total_in+in_sz)); continue
  fi

  if ! cwebp -q "$QUALITY" -m 6 -mt -metadata none "${resize[@]}" "$src" -o "$out" >/dev/null 2>&1; then
    echo "  FAILED: $base" >&2; continue
  fi
  out_sz="$(filesize "$out")"
  total_in=$((total_in+in_sz)); total_out=$((total_out+out_sz)); converted=$((converted+1))
  pct=$(awk -v a="$in_sz" -v o="$out_sz" 'BEGIN{ if(a>0) printf "%.0f",(1-o/a)*100; else print 0 }')
  printf "  ✓ %-42s  %9s -> %9s  (-%s%%)\n" "$base" "$(human "$in_sz")" "$(human "$out_sz")" "$pct"
done < <(find "$SRC_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)

echo ""
if [ "$DRY" -eq 1 ]; then
  echo "Dry run: $count source image(s), $(human "$total_in") total. Nothing written."
else
  saved=$((total_in-total_out))
  pct=$(awk -v s="$saved" -v t="$total_in" 'BEGIN{ if(t>0) printf "%.0f", s/t*100; else print 0 }')
  echo "Optimized $converted image(s); skipped $skipped already up to date."
  [ "$total_in" -gt 0 ] && echo "Total: $(human "$total_in") -> $(human "$total_out")   saved $(human "$saved")  (-${pct}%)"
  echo "Output: $OUT_DIR/   (originals in $SRC_DIR/ untouched)"
fi
