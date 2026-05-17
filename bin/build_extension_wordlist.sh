#!/usr/bin/env bash
set -euo pipefail

BASE="${FILEUPLOAD_BASE:-/opt/fileUpload}"
OUT="${1:-$BASE/wordlists/generated/all_upload_exts.txt}"

mkdir -p "$(dirname "$OUT")"

# PayloadsAllTheThings is intentionally not included here because its upload list
# already contains generated filename patterns. This builder only combines raw
# extension-like sources.
SOURCES=(
  "$BASE/wordlists/custom/php_exts.txt"
  "$BASE/wordlists/custom/asp_exts.txt"
  "$BASE/wordlists/custom/jsp_exts.txt"
  "$BASE/wordlists/external/seclists-web-extensions.txt"
  "$BASE/wordlists/external/seclists-raft-small-extensions.txt"
  "$BASE/wordlists/external/seclists-raft-medium-extensions.txt"
)

: > "$OUT.tmp"

for src in "${SOURCES[@]}"; do
  if [ -f "$src" ]; then
    echo "[+] Adding: $src"
    cat "$src" >> "$OUT.tmp"
  else
    echo "[!] Missing, skipped: $src"
  fi
done

cat "$OUT.tmp" \
  | tr -d '\r' \
  | sed 's/#.*$//' \
  | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
  | sed '/^$/d' \
  | sed 's/^\([^.]\)/.\1/' \
  | sort -u \
  > "$OUT"

rm -f "$OUT.tmp"

echo "[+] Built extension list: $OUT"
wc -l "$OUT"
