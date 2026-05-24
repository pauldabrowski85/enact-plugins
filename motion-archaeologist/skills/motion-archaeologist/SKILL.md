---
name: motion-archaeologist
description: Motion architecture analyst. ALWAYS invoke when the user asks how a website's animation or motion is built. Always extract keyframe or shape data — and report technique.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - mcp__firecrawl__firecrawl_scrape
  - mcp__firecrawl__firecrawl_map
---

# motion-archaeologist

You analyze how a target website's animation or motion is built, lift the
underlying keyframe / shape / asset data to disk, and produce a report that
fuses *technique prose* with *lifted assets*.

This is a craft-study tool. The output lets the user understand a motion
system well enough to author their own in the same shape — not copy-paste
a deployment.

## The hard constraint (the boundary)

Every report MUST include BOTH halves:

- **Technique prose** — transport layers, timing strategy, orchestration
  sequence, easing source
- **Lifted assets** — keyframes / shape paths / animation JSON written to
  `out/<name>.lottie.json` (or escape-hatch report if the engine is
  procedural)

Technique-without-asset is a failed run. Asset-without-technique is also a
failed run. Refuse to stop until both halves exist.

## The 7-step methodology

This is the workflow proven on lovefrom.com that produced
`~/Code/lovefrom-teardown/REPLICATION.md`. Apply verbatim to any URL.

### 1. FETCH the index HTML

- **Default**: `firecrawl_scrape` with `formats: ["rawHtml", "branding"]`.
  The `branding` format auto-extracts colors / fonts / spacing / components
  for free.
- **Fallback** (if Firecrawl is blocked by the site, e.g. anthropic.com):
  `curl` with a real desktop User-Agent.
- Capture: `<script type="module">`, `<link rel="modulepreload|stylesheet|
  manifest|icon">`, inline `<style>`, inline `@font-face`.

### 2. PARSE the loader graph

- **Vite-bundled apps**: open the entry JS, locate the `__vite__mapDeps`
  array — it lists every preloadable dep by hashed filename.
- **Webpack**: open entry JS, find the webpack manifest object.
- **Raw scripts**: enumerate `<script src=...>` manually.
- **Dynamic imports**: grep the entry for `import("./...)`, `fetch(`,
  `new Worker(`.

### 3. DOWNLOAD the asset tree

- All JS bundles + CSS + woff/woff2 + Lottie JSON + SVGs + images.
- **PRESERVE original hashed filenames** — Vite / webpack resolve by exact
  path. Renaming breaks the loader graph. (Most common rookie mistake.)
- Mirror URL structure under a workspace dir: `/assets/`, `/fonts/`,
  `/images/`, plus any custom paths.

Helper: `scripts/replicate.sh <url>` automates 1–3.

### 4. IDENTIFY the animation framework

Probe in this order — **first hit wins**:

| # | Engine | Detection signal |
|---|---|---|
| a | Lottie/bodymovin raw | `grep '"v":"5.', '"fr":', '"ip":', '"op":', '"markers":'` in JS/JSON |
| b | Lottie in bundle (object literal) | `grep '{[^{}]*\bip:[A-Za-z0-9_$]+,op:[A-Za-z0-9_$]+'` |
| c | GSAP | `grep 'gsap\.', 'TweenLite', 'TimelineMax', 'ScrollTrigger'` |
| d | Framer Motion | `grep 'framer-motion', 'motion\.'` |
| e | Web Animations API | `grep '\.animate(', 'KeyframeEffect'` |
| f | Anime.js | `grep 'anime('` |
| g | Three.js / WebGL | `grep 'THREE\.', '@react-three'` |
| h | CSS `@keyframes` | `grep '@keyframes'` in stylesheets |
| i | Custom procedural engine | no library signatures + large class-heavy bundles + bone/transform-vector data structures |

Helper: `scripts/probe-engine.sh <workspace>` runs all 9 probes.

### 5. EXTRACT animation data per engine type

- **Lottie raw** → save JSON as-is to `out/<name>.lottie.json`
- **Lottie object-literal** → reconstruct as valid JSON: trace short vars to
  their definitions, substitute, emit pretty-printed JSON
- **GSAP** → catalog tween definitions: target, properties, duration,
  ease, stagger
- **WAA** → extract keyframes arrays
- **CSS `@keyframes`** → extract rule blocks
- **Procedural** → **ESCAPE HATCH**: document engine class structure,
  extract any keyframed data present (bone poses, transform matrices),
  **DO NOT FABRICATE Lottie**. The Lottie route is closed for procedural
  engines — say so explicitly in the report.

### 6. REPLICATE locally (verification)

- Construct workspace mirroring URL paths
- Copy HTML verbatim
- `python3 -m http.server PORT` (find a free port if 8000 is taken — see
  `scripts/replicate.sh` for the port-discovery one-liner)
- Open in chrome (or Playwright / chrome-devtools MCP): verify page loads,
  animations run, no critical 404s, no fallback class triggered
- Take two screenshots a few seconds apart to prove motion is alive

### 7. REPORT

Write `out/REPORT.md` with both halves:

**Technique prose:**
- Transport layers (DOM/CSS, SVG/Lottie, canvas, WebGL, mixed)
- Timing strategy (computed easing functions vs. hand-authored bezier
  arrays vs. CSS keyframes)
- Orchestration sequence (which fires when, what triggers them)
- Easing source (Lottie bezier handles? GSAP eases? CSS bezier()? Custom
  tween classes?)

**Lifted assets:**
- Path to each `out/<name>.lottie.json` (or escape-hatch report)
- Per-asset summary: frames, duration, layer count, key transforms
- Replication URL + verification screenshots

## How to invoke the helper scripts

```bash
# 1+2+3: Fetch + parse + download
bash $CLAUDE_PLUGIN_ROOT/skills/motion-archaeologist/scripts/replicate.sh https://example.com

# 4: Probe for animation framework
bash $CLAUDE_PLUGIN_ROOT/skills/motion-archaeologist/scripts/probe-engine.sh ./workspace

# Loader-graph diagnostic only
bash $CLAUDE_PLUGIN_ROOT/skills/motion-archaeologist/scripts/probe-loader.sh ./workspace/assets/<entry>.js
```

## Worked example

The canonical worked example is `~/Code/lovefrom-teardown/`:
- `REPLICATION.md` documents Path C (fork the working deployment)
- `out/REPORT.md` documents the procedural-engine escape hatch
- 5 bear bundles teardown synthesis demonstrates per-asset analysis

When debugging this skill, read those files for what a complete run looks
like end-to-end.

## Refusal cases

- **Site blocks Firecrawl AND curl** → say so, escalate to user (Cloudflare
  challenge needs a real browser session via chrome-devtools MCP)
- **Engine identified but no extractable data** (e.g., entirely procedural
  with no keyframed values) → escape hatch: document the engine, name what
  CAN'T be extracted, refuse to fabricate
- **Asset is licensed/proprietary** (e.g., Lottie behind auth) → report
  only what's publicly fetched; do not bypass auth

## Setup

First-run user setup:
1. Get a Firecrawl API key at https://www.firecrawl.dev
2. Export it: `export FIRECRAWL_API_KEY=fc-xxxx`
3. Restart Claude Code so the bundled Firecrawl MCP can reach the key

The Firecrawl `branding` format consumes 1 credit per scrape; the rest are
free / curl.
