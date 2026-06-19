#!/usr/bin/env bash
#
# to-webp.sh — convert PNG/JPEG images to WebP.
#
# Walks the given paths (files or directories), converts every PNG/JPG/JPEG
# into a sibling .webp, and skips images whose .webp is already up to date.
# Originals are kept unless --delete is passed.
#
# Usage:
#   scripts/to-webp.sh [options] [path ...]
#
# Options:
#   -q, --quality N   WebP quality 0-100 (default: 82; env WEBP_QUALITY)
#       --lossless    lossless mode (best for screenshots / line art)
#       --delete      remove the source image after a successful convert
#       --force       reconvert even when the .webp looks up to date
#   -h, --help        show this help
#
# When no path is given, defaults to static/img.

set -euo pipefail

# ---- pretty output -------------------------------------------------------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; RESET=''
fi

die()  { printf '%serror:%s %s\n'   "$RED"    "$RESET" "$*" >&2; exit 1; }
warn() { printf '%swarning:%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }

usage() { sed -n '3,/^# When no path/p' "$0" | sed 's/^#\{0,1\} \{0,1\}//'; }

# Portable file size (BSD/macOS stat first, then GNU stat, then 0).
fsize() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0; }

# Bytes -> human readable (handles negatives).
human() {
  awk -v b="$1" 'BEGIN{
    s=""; if (b<0){s="-"; b=-b}
    split("B KB MB GB TB", u); i=1
    while (b>=1024 && i<5){ b/=1024; i++ }
    printf (i==1 ? "%s%d %s" : "%s%.1f %s"), s, b, u[i]
  }'
}

# ---- args ----------------------------------------------------------------
QUALITY="${WEBP_QUALITY:-82}"
LOSSLESS=0
DELETE=0
FORCE=0
PATHS=()

while [ $# -gt 0 ]; do
  case "$1" in
    -q|--quality)
      [ $# -ge 2 ] || die "option $1 requires a value (0-100)"
      QUALITY="$2"; shift 2 ;;
    --quality=*)  QUALITY="${1#*=}"; shift ;;
    --lossless)   LOSSLESS=1; shift ;;
    --delete)     DELETE=1; shift ;;
    --force)      FORCE=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    --)           shift; PATHS+=("$@"); break ;;
    -*)           die "unknown option: $1 (try --help)" ;;
    *)            PATHS+=("$1"); shift ;;
  esac
done

[ ${#PATHS[@]} -gt 0 ] || PATHS=("static/img")

command -v cwebp >/dev/null 2>&1 \
  || die "cwebp not found — install it with: brew install webp"

case "$QUALITY" in
  ''|*[!0-9]*) die "quality must be an integer 0-100, got: '$QUALITY'" ;;
esac
[ "$QUALITY" -le 100 ] || die "quality must be 0-100, got: $QUALITY"

# Validate paths up front: a missing path is an error, not a silent no-op.
# (collect() runs in a subshell, so it can't report this back.)
missing=0
for p in "${PATHS[@]}"; do
  [ -e "$p" ] || { warn "no such path: $p"; missing=$((missing + 1)); }
done

# ---- collect candidate images (NUL-delimited) ----------------------------
collect() {
  local p
  for p in "${PATHS[@]}"; do
    if [ -f "$p" ]; then
      printf '%s\0' "$p"
    elif [ -d "$p" ]; then
      find "$p" -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print0
    fi
  done
}

# ---- convert -------------------------------------------------------------
shopt -s nocasematch  # case-insensitive extension match (bash 3.2 friendly)

converted=0; skipped=0; deleted=0; failed=0; saved=0

while IFS= read -r -d '' src; do
  case "$src" in
    *.png|*.jpg|*.jpeg) ;;
    *) continue ;;
  esac

  dst="${src%.*}.webp"

  # Already up to date: optionally drop the original, otherwise skip.
  if [ "$FORCE" -eq 0 ] && [ -f "$dst" ] && [ ! "$src" -nt "$dst" ]; then
    if [ "$DELETE" -eq 1 ]; then
      rm -f -- "$src"
      printf '%s   rm%s  %s %s(stale original)%s\n' "$YELLOW" "$RESET" "$src" "$DIM" "$RESET"
      deleted=$((deleted + 1))
    else
      printf '%s skip%s  %s\n' "$DIM" "$RESET" "$dst"
      skipped=$((skipped + 1))
    fi
    continue
  fi

  if [ "$LOSSLESS" -eq 1 ]; then
    cwebp_args=(-quiet -lossless)
  else
    cwebp_args=(-quiet -q "$QUALITY")
  fi

  if cwebp "${cwebp_args[@]}" "$src" -o "$dst" >/dev/null 2>&1 && [ -f "$dst" ]; then
    in=$(fsize "$src"); out=$(fsize "$dst")
    saved=$((saved + in - out))
    pct=0; [ "$in" -gt 0 ] && pct=$(((in - out) * 100 / in))
    printf '%s   ok%s  %s  %s(-%s%%)%s\n' "$GREEN" "$RESET" "$dst" "$DIM" "$pct" "$RESET"
    converted=$((converted + 1))
    if [ "$DELETE" -eq 1 ]; then
      rm -f -- "$src"
      deleted=$((deleted + 1))
    fi
  else
    warn "failed to convert: $src"
    failed=$((failed + 1))
  fi
done < <(collect)

# ---- summary -------------------------------------------------------------
printf '\n%sdone%s  %d converted · %d skipped · %d deleted · %d failed' \
  "$BOLD" "$RESET" "$converted" "$skipped" "$deleted" "$failed"
[ "$missing" -gt 0 ] && printf ' · %d missing' "$missing"
[ "$converted" -gt 0 ] && printf '  ·  saved %s' "$(human "$saved")"
printf '\n'

[ "$failed" -eq 0 ] && [ "$missing" -eq 0 ]
