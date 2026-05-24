#!/usr/bin/env bash
# replicate.sh — fork a target site's deployment to localhost (Path C).
#
# Usage: ./replicate.sh <url> [workspace-dir]
# Default workspace: ./teardown-<hostname>
#
# 1. Fetch index HTML
# 2. Parse entry JS for asset references (Vite mapDeps + script src + link href)
# 3. Download all referenced assets, preserving hashed filenames
# 4. Start python3 http.server on a free port and print the URL

set -euo pipefail

URL="${1:?usage: replicate.sh <url> [workspace-dir]}"
HOST="$(echo "$URL" | sed -E 's|https?://||;s|/.*||')"
WORKSPACE="${2:-./teardown-${HOST}}"

UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'

mkdir -p "$WORKSPACE"
cd "$WORKSPACE"

echo "=== Replicating $URL → $WORKSPACE ==="
echo

# 1. Fetch index
echo "[1/4] Fetching index HTML..."
curl -fsSL -A "$UA" "$URL" -o index.html
echo "  saved: index.html ($(wc -c < index.html) bytes)"
echo

# 2. Extract asset references from HTML + entry JS
echo "[2/4] Parsing asset graph..."
ASSETS_TMP="$(mktemp)"

# From HTML: <script src=...>, <link href=...>
grep -oE '(src|href)="[^"]+"' index.html \
  | sed -E 's/.*="(.*)"/\1/' \
  | grep -E '\.(js|css|woff2?|json|svg|png|jpg|ico|webmanifest)' \
  | sort -u > "$ASSETS_TMP"

# Find any inline <script type=module> entries → fetch and recurse
ENTRY_SCRIPTS=$(grep -oE 'src="[^"]+\.js[^"]*"' index.html | sed 's/src="//;s/"$//' | head -5)
for entry in $ENTRY_SCRIPTS; do
  # Resolve to absolute URL
  if [[ "$entry" == /* ]]; then
    full="${URL%/}${entry}"
  elif [[ "$entry" == http* ]]; then
    full="$entry"
  else
    full="${URL%/}/${entry}"
  fi
  # Download to a temp file to grep
  ENTRY_TMP="$(mktemp)"
  curl -fsSL -A "$UA" "$full" -o "$ENTRY_TMP" 2>/dev/null || continue
  # Pull hashed-filename references from inside the entry
  grep -oE '[a-zA-Z0-9_-]+-[A-Za-z0-9_-]{8,}\.(js|css|woff2?|json|svg|png|jpg)' "$ENTRY_TMP" | sort -u >> "$ASSETS_TMP" || true
  rm -f "$ENTRY_TMP"
done

sort -u "$ASSETS_TMP" -o "$ASSETS_TMP"
echo "  $(wc -l < "$ASSETS_TMP") unique asset paths"
echo

# 3. Download all assets, preserving paths
echo "[3/4] Downloading assets..."
COUNT=0
FAILED=0
while IFS= read -r path; do
  # Resolve absolute URL
  if [[ "$path" == http* ]]; then
    full="$path"
    rel="$(echo "$path" | sed -E "s|https?://[^/]+||")"
  elif [[ "$path" == /* ]]; then
    full="${URL%/}${path}"
    rel="$path"
  else
    full="${URL%/}/${path}"
    rel="/$path"
  fi
  # rel starts with /; make local path
  local_path=".${rel}"
  mkdir -p "$(dirname "$local_path")"
  if curl -fsSL -A "$UA" "$full" -o "$local_path" 2>/dev/null; then
    COUNT=$((COUNT + 1))
  else
    FAILED=$((FAILED + 1))
    echo "  FAIL: $full"
  fi
done < "$ASSETS_TMP"
rm -f "$ASSETS_TMP"
echo "  downloaded: $COUNT, failed: $FAILED"
echo

# 4. Start http.server on a free port
echo "[4/4] Starting local server..."
PORT=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
echo "  → http://localhost:$PORT/"
echo "  (Ctrl-C to stop)"
echo
python3 -m http.server "$PORT" --bind 127.0.0.1
