#!/usr/bin/env bash
# probe-engine.sh — identify the animation framework in a workspace dir.
#
# Usage: ./probe-engine.sh <workspace-dir>
# Runs 9 detection signatures in priority order; first hit wins (printed at top).

set -euo pipefail

WORKSPACE="${1:?usage: probe-engine.sh <workspace-dir>}"

if [[ ! -d "$WORKSPACE" ]]; then
  echo "ERROR: $WORKSPACE is not a directory" >&2
  exit 2
fi

cd "$WORKSPACE"

probe() {
  local label="$1"
  local pattern="$2"
  local files
  files=$(grep -rlE "$pattern" --include='*.js' --include='*.mjs' --include='*.json' --include='*.css' . 2>/dev/null | head -5)
  if [[ -n "$files" ]]; then
    echo "HIT: $label"
    while IFS= read -r f; do echo "  $f"; done <<< "$files"
    return 0
  fi
  return 1
}

echo "=== motion-archaeologist engine probe ==="
echo "workspace: $WORKSPACE"
echo

WINNER=""
declare -a HITS=()

# a) Lottie raw — bodymovin schema markers
if probe 'Lottie/bodymovin (raw JSON)' '"v":"5\.|"fr":[0-9]+|"ip":[0-9]+|"op":[0-9]+|"markers":'; then
  WINNER="${WINNER:-Lottie raw}"
  HITS+=("Lottie raw")
fi

# b) Lottie embedded as object literal in minified bundle
if probe 'Lottie in bundle (object literal)' '\{[^{}]*\bip:[A-Za-z0-9_$]+,op:[A-Za-z0-9_$]+'; then
  WINNER="${WINNER:-Lottie inlined}"
  HITS+=("Lottie inlined")
fi

# c) GSAP
if probe 'GSAP' 'gsap\.|TweenLite|TimelineMax|ScrollTrigger'; then
  WINNER="${WINNER:-GSAP}"
  HITS+=("GSAP")
fi

# d) Framer Motion
if probe 'Framer Motion' 'framer-motion|motion\.div|motion\.span'; then
  WINNER="${WINNER:-Framer Motion}"
  HITS+=("Framer Motion")
fi

# e) Web Animations API
if probe 'Web Animations API' '\.animate\(|KeyframeEffect'; then
  WINNER="${WINNER:-Web Animations API}"
  HITS+=("Web Animations API")
fi

# f) Anime.js
if probe 'Anime.js' 'anime\('; then
  WINNER="${WINNER:-Anime.js}"
  HITS+=("Anime.js")
fi

# g) Three.js / WebGL
if probe 'Three.js / WebGL' 'THREE\.|@react-three|WebGLRenderer'; then
  WINNER="${WINNER:-Three.js}"
  HITS+=("Three.js")
fi

# h) CSS @keyframes
if probe 'CSS @keyframes' '@keyframes'; then
  WINNER="${WINNER:-CSS keyframes}"
  HITS+=("CSS keyframes")
fi

echo
if [[ -z "$WINNER" ]]; then
  echo "VERDICT: no library signatures matched."
  echo "Likely: custom procedural engine (escape hatch path)."
  echo "Inspect bundles manually for class definitions + bone/transform vectors."
  exit 1
fi

echo "VERDICT: $WINNER (first match wins)"
echo "ALL HITS: ${HITS[*]}"
