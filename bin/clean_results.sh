#!/usr/bin/env bash
set -euo pipefail
BASE="${FILEUPLOAD_BASE:-/opt/fileUpload}"
find "$BASE/results" -type f ! -name '.gitkeep' -delete
find "$BASE/wordlists/generated" -type f ! -name '.gitkeep' -delete
echo "[+] Cleaned results and generated wordlists"
