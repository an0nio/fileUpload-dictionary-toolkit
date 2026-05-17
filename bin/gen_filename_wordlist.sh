#!/usr/bin/env bash
set -euo pipefail

BASE="${FILEUPLOAD_BASE:-/opt/fileUpload}"

EXTS_FILE="${1:-$BASE/wordlists/custom/php_exts.txt}"
OUT="${2:-$BASE/wordlists/generated/evasive_filenames.txt}"
ALLOWED_EXTS_FILE="${3:-$BASE/wordlists/custom/allowed_image_exts.txt}"

if [ ! -f "$EXTS_FILE" ]; then
  echo "[!] Dangerous extensions file not found: $EXTS_FILE" >&2
  exit 1
fi

if [ ! -f "$ALLOWED_EXTS_FILE" ]; then
  echo "[!] Allowed extensions file not found: $ALLOWED_EXTS_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT")"

# Separators/control characters used to confuse extension parsers and normalizers.
# They are kept intentionally compact. Add your own if needed.
CHARS=(
  ""
  "%20"
  "%09"
  "%0a"
  "%0A"
  "%00"
  "%0d"
  "%0D"
  "%0d%0a"
  "/"
  ".\\"
  "."
  ".."
  "..."
  "…"
  ":"
)

mapfile -t ALLOWED_EXTS < <(
  cat "$ALLOWED_EXTS_FILE" \
    | tr -d '\r' \
    | sed 's/#.*$//' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | sed '/^$/d' \
    | sed 's/^\([^.]\)/.\1/' \
    | sort -u
)

: > "$OUT"

while IFS= read -r ext; do
  ext="$(printf '%s' "$ext" | tr -d '\r' | sed 's/#.*$//' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [[ -z "$ext" ]] && continue
  [[ "$ext" != .* ]] && ext=".$ext"

  for allowed in "${ALLOWED_EXTS[@]}"; do
    for char in "${CHARS[@]}"; do
      # Dangerous extension before allowed one.
      echo "shell${char}${ext}${allowed}" >> "$OUT"
      echo "shell${ext}${char}${allowed}" >> "$OUT"

      # Allowed extension before dangerous one.
      echo "shell${allowed}${char}${ext}" >> "$OUT"
      echo "shell${allowed}${ext}${char}" >> "$OUT"

      # Direct double-extension forms.
      echo "shell${ext}${allowed}" >> "$OUT"
      echo "shell${allowed}${ext}" >> "$OUT"
    done
  done

  # Non-whitelist variants, useful when the filter can be bypassed before storage.
  echo "shell${ext}" >> "$OUT"
  echo "shell${ext}." >> "$OUT"
  echo "shell${ext}%20" >> "$OUT"
  echo "shell${ext}%0a" >> "$OUT"
  echo "shell${ext}%00" >> "$OUT"
done < "$EXTS_FILE"

sort -u "$OUT" -o "$OUT"

echo "[+] Generated: $OUT"
echo "[+] Dangerous extensions: $EXTS_FILE"
echo "[+] Allowed extensions:   $ALLOWED_EXTS_FILE"
wc -l "$OUT"
