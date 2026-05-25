# motion-archaeologist

> Motion architecture analyst. Reverse-engineer how any website's animation
> is built — transport, timing, easing, orchestration — and lift the
> keyframe / shape / asset data to disk.

A Claude Code plugin from [EnactSkill](https://enactskill.com).

## What it does

You paste a URL. The plugin:

1. Fetches the index HTML (via Firecrawl, with curl fallback)
2. Parses the loader graph (Vite `__vite__mapDeps`, webpack manifest, raw
   `<script>` tags)
3. Downloads the asset tree to a local workspace, preserving the original
   hashed filenames so the deployment works locally
4. Identifies the animation framework (Lottie, GSAP, Framer Motion, Web
   Animations API, Anime.js, Three.js, CSS keyframes, or custom procedural)
5. Extracts the animation data per engine type — Lottie JSON, GSAP tween
   catalogs, CSS keyframes, or an escape-hatch report for procedural rigs
6. Replicates the site at `localhost:<port>` so you can verify motion
   parity in your browser
7. Writes a report fusing technique prose with lifted assets

The hard constraint: every report includes **both** technique prose AND
lifted assets. Technique-without-asset is a failed run.

## Install

```
/plugin marketplace add https://github.com/pauldabrowski85/enact-plugins.git
/plugin install motion-archaeologist@enact-plugins
```

Setup:

1. Get a Firecrawl API key at [firecrawl.dev](https://www.firecrawl.dev/).
2. Export it: `export FIRECRAWL_API_KEY=fc-xxxx`
3. Restart Claude Code so the bundled Firecrawl MCP can reach the key.

The Firecrawl `branding` format consumes 1 credit per scrape; the rest are
free / curl.

## Use

The skill auto-invokes whenever you ask about how a site's animation is
built:

> "How does stripe.com's hero animate?"
>
> "What's the motion stack on linear.app?"
>
> "Tear down lovefrom.com — I want to see how the bear is built."

The plugin handles the rest. Output lands in `./teardown-<host>/` with
`out/REPORT.md` as the entry point.

## What it refuses

- Sites that block both Firecrawl and curl (Cloudflare challenges, etc.).
  The plugin reports the block and asks for a real-browser session.
- Procedural engines with no extractable keyframed data. The plugin
  documents the engine and explicitly refuses to fabricate Lottie that
  doesn't exist.
- Asset extraction from authenticated surfaces. The plugin only fetches
  what's public.

## License

Apache-2.0. See [LICENSE](LICENSE).

## Author

[EnactSkill LLC](https://enactskill.com). Source:
[github.com/pauldabrowski85/enact-plugins](https://github.com/pauldabrowski85/enact-plugins).
