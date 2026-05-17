#!/usr/bin/env bash
set -euo pipefail

BASE="${FILEUPLOAD_BASE:-/opt/fileUpload}"
EXT_DIR="$BASE/wordlists/external"
mkdir -p "$EXT_DIR"

SECLISTS_CANDIDATES=(
  "/usr/share/seclists"
  "/usr/share/wordlists/seclists"
  "/opt/SecLists"
  "$HOME/SecLists"
)

SECLISTS_DIR=""
for d in "${SECLISTS_CANDIDATES[@]}"; do
  if [ -d "$d" ]; then
    SECLISTS_DIR="$d"
    break
  fi
done

if [ -z "$SECLISTS_DIR" ]; then
  echo "[!] SecLists not found in common paths."
else
  echo "[+] SecLists: $SECLISTS_DIR"

  declare -A LINKS=(
    ["seclists-web-extensions.txt"]="Discovery/Web-Content/web-extensions.txt"
    ["seclists-raft-small-extensions.txt"]="Discovery/Web-Content/raft-small-extensions.txt"
    ["seclists-raft-medium-extensions.txt"]="Discovery/Web-Content/raft-medium-extensions.txt"
    ["seclists-raft-large-extensions.txt"]="Discovery/Web-Content/raft-large-extensions.txt"
    ["seclists-all-content-types.txt"]="Discovery/Web-Content/web-all-content-types.txt"
    ["seclists-common-web-content.txt"]="Discovery/Web-Content/common.txt"
  )

  for link_name in "${!LINKS[@]}"; do
    target="$SECLISTS_DIR/${LINKS[$link_name]}"
    link="$EXT_DIR/$link_name"
    if [ -f "$target" ]; then
      ln -sfn "$target" "$link"
      echo "[+] $link_name -> $target"
    else
      echo "[!] Missing: $target"
    fi
  done
fi

# Optional reference files downloaded from PayloadsAllTheThings.
PATT_LOCAL="$EXT_DIR/payloadsallthethings"
if [ -f "$PATT_LOCAL/php-extensions.lst" ]; then
  ln -sfn "$PATT_LOCAL/php-extensions.lst" "$EXT_DIR/payloadsallthethings-php-extensions.lst"
fi
if [ -f "$PATT_LOCAL/upload-insecure-files-README.md" ]; then
  ln -sfn "$PATT_LOCAL/upload-insecure-files-README.md" "$EXT_DIR/payloadsallthethings-upload-readme.md"
fi

find "$EXT_DIR" -maxdepth 1 -type l -printf '%f -> %l\n' | sort
