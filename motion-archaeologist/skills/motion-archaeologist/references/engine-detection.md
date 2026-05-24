# Engine detection — full probe table

The 9-row table referenced from SKILL.md step 4. Load this when you need
to know exactly what string each engine's detection probes against.

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

## Per-engine extraction notes

The full extraction logic per engine is encoded in `scripts/probe-engine.sh`
(automated detection) and SKILL.md step 5 (per-type extraction). This file
documents corner cases the script doesn't cover.

### Lottie object-literal (case b)

When Lottie is inlined in a minified bundle, the schema keys are short:
`v`, `fr`, `ip`, `op`, `w`, `h`, `assets`, `layers`, `markers`. The
extraction process is:

1. Find the literal: grep for the multi-key signature in #b above
2. Identify the enclosing function or const — usually exported via Vite's
   `__vite__mapDeps` chunk or webpack's manifest
3. Reconstruct: trace each short variable back to its definition,
   substitute, emit pretty-printed JSON

This was the lovefrom.com case — see `~/Code/lovefrom-teardown/out/` for
the worked example (the comma cells extracted cleanly; the bears didn't,
which triggered the escape hatch for that asset class).

### Custom procedural engine (case i, escape hatch)

The defining signature of a procedural engine: large class hierarchies
(50-150 mangled classes per bundle), bone/transform vector arrays as
runtime data, no library-import signatures.

Examples encountered in the wild:
- lovefrom.com bear bundles (Patrick Coleman's hand-rolled skeletal-rig
  engine) — 99 to 129 classes per bear, 9-tuple bone poses,
  `R._strings.push({R, D, F})` animation records

The escape hatch IS the report:
1. Document the class structure (count, naming, inheritance)
2. Document the data shape (what gets keyframed, what's computed)
3. Document what canNOT be extracted (the runtime physics, the tween
   logic in `r0`, `n0`, `f`, `U` classes)
4. Refuse to fabricate Lottie that doesn't exist

### Three.js / WebGL (case g)

If the page is canvas-rendered, traditional asset extraction is limited.
The skill should:
1. Identify the scene graph (look for `THREE.Scene`, `THREE.Group`)
2. Extract any GLTF/GLB asset URLs (these ARE downloadable assets)
3. Document the render loop technique (RAF? Three's WebGLRenderer.render?)
4. Capture timing constants from JS source

WebGL shader extraction is a separate study — out of scope for v0.1.

## References

- LottieFiles Bodymovin schema: https://lottiefiles.com/lottie
- GSAP API: https://gsap.com/docs/
- Web Animations API: https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API
- Anthropic skills-doctrine on progressive disclosure (`brand/skills-doctrine.md` in the EnactSkill repo)
