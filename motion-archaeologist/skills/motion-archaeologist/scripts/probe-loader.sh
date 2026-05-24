#!/usr/bin/env bash
# probe-loader.sh — extract the loader graph from an entry JS bundle.
#
# Usage: ./probe-loader.sh <entry-js-file>
# Detects Vite (__vite__mapDeps), webpack (manifest), and raw dynamic imports.

set -euo pipefail

ENTRY="${1:?usage: probe-loader.sh <entry-js-file>}"

if [[ ! -f "$ENTRY" ]]; then
  echo "ERROR: $ENTRY not found" >&2
  exit 2
fi

echo "=== loader graph probe: $ENTRY ==="
echo

# Vite: __vite__mapDeps([...])
echo "--- Vite (__vite__mapDeps) ---"
if grep -oE '__vite__mapDeps\(\[[^]]+\]' "$ENTRY" | head -3; then
  echo "(Vite loader graph found — dependency arrays printed above)"
else
  echo "(no __vite__mapDeps array — not a Vite-bundled app, or already inlined)"
fi
echo

# Webpack: __webpack_require__ or manifest objects
echo "--- Webpack (__webpack_require__ / manifest) ---"
if grep -oE '__webpack_require__|webpackChunk[A-Za-z0-9_]+' "$ENTRY" | sort -u | head -5; then
  echo "(Webpack signatures found above)"
else
  echo "(no webpack signatures — not a webpack bundle)"
fi
echo

# Raw dynamic imports / fetches / workers
echo "--- Dynamic imports / fetches / workers ---"
grep -oE 'import\("[^"]+"\)|fetch\("[^"]+"\)|new Worker\("[^"]+"\)' "$ENTRY" | sort -u | head -20 || true
echo

# All hashed asset references (likely siblings in /assets/)
echo "--- All hashed asset references (chunks, fonts, lottie) ---"
grep -oE '[a-zA-Z0-9_-]+-[A-Za-z0-9_-]{8,}\.(js|css|woff2?|json|svg|png|jpg)' "$ENTRY" | sort -u | head -50 || true
