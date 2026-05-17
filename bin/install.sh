#!/usr/bin/env bash
set -euo pipefail
DEST="${1:-/opt/fileUpload}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sudo mkdir -p "$DEST"
sudo cp -a "$SRC/." "$DEST/"
sudo chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$DEST"
chmod +x "$DEST"/bin/*

echo "[+] Installed into $DEST"
echo "    cd $DEST"
echo "    bin/setup_symlinks.sh"
