# Sandbox-test the motion-archaeologist plugin locally

Before pushing to GitHub / publishing the marketplace, verify the plugin
works end-to-end against a neutral test site.

## Setup

```bash
# 1. Get a Firecrawl API key at https://www.firecrawl.dev
export FIRECRAWL_API_KEY=fc-xxxx

# 2. Launch a sandbox Claude session with the local plugin loaded
claude --plugin-dir ~/Code/enact-plugins/motion-archaeologist
```

## Verify auto-trigger

Inside the sandbox session, try each of these prompts. The
`motion-archaeologist` skill should auto-invoke (no manual `Skill` tool
call required):

- `how does stripe.com's hero animate?`
- `reverse-engineer the motion on linear.app`
- `teardown the animation on apple.com/vision-pro`

Each should fire the skill, run the 7-step methodology, and return both
technique prose AND lifted assets in `./teardown-<host>/out/`.

## Verify the boundary

Pick any one of the above. The output must include:

- [ ] `out/REPORT.md` exists with both halves filled in
- [ ] At least one `out/*.lottie.json` (or escape-hatch report if
      procedural)
- [ ] Workspace replicates locally at `http://localhost:<port>/`
- [ ] No "Lottie fabricated" output for procedural engines

If a run produces technique prose without lifted assets, the boundary
failed — file an issue with the URL + run output.

## Validate the marketplace manifest

```bash
# From the marketplace root
cd ~/Code/enact-plugins
# Try adding it as a local marketplace
claude
> /plugin marketplace add file:///Users/pauldabrowski/Code/enact-plugins
> /plugin install motion-archaeologist@enact-plugins
```

If the install completes without errors and `/plugin list` shows the
plugin, the manifest is correct.

## Ship checklist (before pushing to GitHub)

- [ ] Sandbox test passes against ≥2 different sites (one mainstream, one
      lovefrom.com to confirm parity with the hand-run teardown)
- [ ] `plugin-dev:plugin-validator` returns no blocking issues
- [ ] `plugin-dev:skill-reviewer` returns no high-priority revisions
- [ ] All scripts are executable (`ls -la skills/*/scripts/`)
- [ ] Version bumped if any change since last published commit

## Publish (when ready)

```bash
# Create the GitHub repo under the EnactSkill org (or your personal org)
gh repo create pauldabrowski85/enact-plugins --public --source=. --remote=origin --push
```

The marketplace becomes installable via:

```
/plugin marketplace add https://github.com/pauldabrowski85/enact-plugins.git
/plugin install motion-archaeologist@enact-plugins
```
