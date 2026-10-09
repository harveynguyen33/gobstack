# gobstack `gob extras` — Candidate Catalogue Research

**Curated for Harvey — research only, nothing added to any catalogue.**
Date: 2026-10-08. All URLs verified live via GitHub API (stars/license/last-push pulled from `repos` API on this date, not search-cache).

Verification key: kind = `skill` (folder with SKILL.md, agent-consumable, no registration) / `mcp` (MCP server, needs mcp.json registration) / `workflow` (playbooks/agents, not a single SKILL.md) / `meta` (list/collection, harvest source). Freshness = last push. "today" = 2026-10-08.

---

## 1. FRONTEND (React / Next.js / Vue)

| name | kind | source URL | what it does | license | freshness | adoption | verdict |
|---|---|---|---|---|---|---|---|
| taste-skill | skill (13 SKILL.md) | github.com/Leonxlnx/taste-skill | Gives agents design taste; stops generic AI-slop UI output | MIT | 2026-10-07 (1d ago) | ★93,730 | **RECOMMEND** — de-facto community standard for taste, huge adoption, fresh, pure SKILL.md format |
| vercel-labs/agent-skills | skill pack (9 SKILL.md) | github.com/vercel-labs/agent-skills | Official Vercel skills: `react-best-practices`, `composition-patterns`, `web-design-guidelines` (design review), `react-view-transitions` | NO LICENSE FILE on repo | 2026-08-28 | ★32,078 | **LICENSE-PENDING** (2026-10-09) — vendor-official React review/polish skills, but the hard gate holds: no repo-level license and no verified per-skill file, so it is never pre-ticked and refuses install until the license is verified |
| anthropics/skills → `frontend-design` | skill | github.com/anthropics/skills | Official Anthropic frontend-design skill (aesthetic direction, polish) | repo-wide NO LICENSE file (has THIRD_PARTY_NOTICES) | 2026-10-05 | ★180,150 (repo) | **LICENSE-PENDING** (2026-10-09) — canonical frontend design skill, but the hard gate holds: resolve licensing (per-skill or fair-use excerpt) before it can install |
| vuejs-ai/skills | skill pack | github.com/vuejs-ai/skills | Agent skills for Vue 3 development | MIT | 2026-05-30 | ★2,889 | **RECOMMEND** — match for Vue detection in `gob init`; only real Vue-specific skill pack |
| ux-ui-agent-skills | skill pack | github.com/plugin87/ux-ui-agent-skills | Senior-design-architect persona: DTCG design tokens, 52 components, WCAG 2.2 AA-AAA, 138 design-system rules | MIT | 2026-10-08 (today) | ★1,551 | **RECOMMEND** — best accessibility/design-system coverage; pairs well with taste-skill |
| superdesign-skill | skill | github.com/superdesigndev/superdesign-skill | Turns AI-slop UI into designed output; design iteration loop | MIT | 2026-08-21 | ★633 | MAYBE — good but overlaps taste-skill + vercel web-design-guidelines |
| garden-skills | meta + skills | github.com/ConardLi/garden-skills | Collection incl. web-design skills, knowledge retrieval, image gen | MIT | 2026-07-12 | ★12,771 | MAYBE — harvest individual web-design skills from it; not a single clean unit |
| Claude-Code-Frontend-Design-Toolkit | meta | github.com/wilwaldon/Claude-Code-Frontend-Design-Toolkit | Curated list of skills/plugins/MCPs for better-looking frontend output | no license | 2026-04-11 | ★1,176 | SKIP as entry — use as harvest source only |
| nuxt-skills | skill pack | github.com/onmax/nuxt-skills | Vue/Nuxt/NuxtHub skills | no license | 2026-10-06 | ★719 | SKIP — no license; revisit if author adds one |
| design-audit | skill | github.com/wonjyou/design-audit | UI/UX design-audit checklist skill | no license | 2026-03-28 | ★8 | SKIP — low adoption, no license; vercel `web-design-guidelines` covers this better |
| vibe-coded-website-review | skill | github.com/zuocharles/vibe-coded-website-review | YC Design Review checklist for vibe-coded sites | no license | 2026-03-29 | ★0 | SKIP — niche checklist; content idea worth cribbing at review time |

**Strongest starts:** taste-skill, vercel-labs web-design-guidelines + react-best-practices, anthropics frontend-design, vuejs-ai/skills, ux-ui-agent-skills.

## 2. AUTOMATION TESTING (Playwright / CDP / E2E)

| name | kind | source URL | what it does | license | freshness | adoption | verdict |
|---|---|---|---|---|---|---|---|
| playwright-mcp (Microsoft, official) | mcp | github.com/microsoft/playwright-mcp | Official Playwright MCP: structured accessibility-tree browser automation for agents | Apache-2.0 | 2026-10-08 (today) | ★37,929 | **RECOMMEND** — the browser-automation anchor for any E2E detection |
| chrome-devtools-mcp (official) | mcp | github.com/ChromeDevTools/chrome-devtools-mcp | Chrome DevTools (CDP) for coding agents: performance traces, network, console, screenshots | Apache-2.0 | 2026-10-08 (today) | ★53,117 | **RECOMMEND** — official Google CDP server; complements playwright-mcp (debug/perf vs automation) |
| playwright-skill | skill (1 SKILL.md) | github.com/lackeyjb/playwright-skill | General-purpose Playwright automation as a skill — no MCP registration needed | MIT | 2026-10-01 | ★3,180 | **RECOMMEND** — skill-form alternative when gobstack shouldn't spawn an MCP server |
| anthropics/skills → `webapp-testing` | skill | github.com/anthropics/skills | Official Anthropic skill: use Playwright scripts to test web apps, verify agent-made changes | repo NO LICENSE file | 2026-10-05 | ★180,150 (repo) | **LICENSE-PENDING** (2026-10-09) — canonical "test what the agent built" loop, but the hard gate holds: same license caveat as frontend-design, refuses install until verified |
| dev-browser | skill | github.com/SawyerHood/dev-browser | Gives the agent a general web browser as a Claude skill | MIT | 2026-09-05 | ★6,656 | MAYBE — overlaps playwright-mcp; useful where MCP is unavailable |
| playwright-best-practices-skill (Currents.dev) | skill | github.com/currents-dev/playwright-best-practices-skill | Playwright authoring best practices from a commercial testing vendor | MIT | 2026-07-21 | ★393 | MAYBE — solid vendor-maintained guidance skill |
| playwright-skill (TestDino) | skill | github.com/testdino-hq/playwright-skill | AI guides for Playwright best practices | MIT | 2026-09-06 | ★389 | MAYBE — alternative to Currents; pick one, not both |
| qa-skills | workflow | github.com/neonwatty/qa-skills | E2E test-generation + QA pipeline for Claude Code (workflow docs, multi-user flows) | MIT | 2026-05-03 | ★33 | SKIP — small; workflow-style doesn't map cleanly to extras entries |
| agentmantis/test-skills | skill pack | github.com/agentmantis/test-skills | Playwright E2E skills for Claude Code/Codex/Cursor | MIT | 2026-04-08 | ★12 | SKIP — no adoption signal over Currents/TestDino |
| invisible_playwright_mcp | mcp | github.com/feder-cr/invisible_playwright_mcp | Anti-bot-stealth Playwright MCP (anti-detect) | no license file | 2026-10-08 | ★2,660 | SKIP — stealth/bot-evasion focus is wrong fit for a dev harness |

**Strongest starts:** microsoft/playwright-mcp, ChromeDevTools/chrome-devtools-mcp, lackeyjb/playwright-skill, anthropics webapp-testing.

## 3. GAME DEV (Godot / Unity)

| name | kind | source URL | what it does | license | freshness | adoption | verdict |
|---|---|---|---|---|---|---|---|
| hi-godot/godot-ai (known) | mcp | github.com/hi-godot/godot-ai | Production-grade Godot MCP server + AI tools, Snap-installable | MIT | 2026-10-08 (today) | ★2,862 | **RECOMMEND** — Harvey already knows it; official-feeling, actively maintained |
| godot-mcp (Coding-Solo) | mcp | github.com/Coding-Solo/godot-mcp | MCP for Godot: launch editor, run projects, debug, manage scenes | MIT | 2026-04-16 | ★5,976 | **RECOMMEND** — most-starred community Godot MCP; the default suggestion, hi-godot as alternative |
| GodotPrompter | skills (66 SKILL.md) | github.com/jame581/GodotPrompter | Agentic skills framework for Godot 4.x — domain-specific skills for Claude Code/Copilot | MIT | 2026-10-06 | ★798 | **RECOMMEND** — pure-SKILL.md Godot knowledge (66 skills!); fits gobstack's skill system directly, no MCP registration |
| unity-mcp (CoplayDev) | mcp | github.com/CoplayDev/unity-mcp | Unity Editor bridge: manage assets, scenes, scripts, run editor ops from LLM | MIT | 2026-10-07 | ★14,767 | **RECOMMEND** — the Unity equivalent, clear community winner |
| Unity-MCP (IvanMurzak) | mcp + skills + cli | github.com/IvanMurzak/Unity-MCP | AI Skills + MCP tools + CLI for Unity; full develop-and-test loop | Apache-2.0 | 2026-10-04 | ★4,400 | MAYBE — strong alternative to CoplayDev; skills+CLI angle is interesting; suggest one Unity entry, keep this as fallback |
| Claude-Code-Game-Studios | workflow (49 agents, 72 skills) | github.com/Donchitos/Claude-Code-Game-Studios | Turns Claude Code into a full game studio with coordinating agents | MIT | 2026-10-08 (today) | ★25,900 | MAYBE — huge adoption but heavyweight multi-agent workflow, not modular; review whether gobstack wants the whole thing or cherry-picked skills |
| awesome-gamedev-agent-skills | meta (74 skills) | github.com/gamedev-skills/awesome-gamedev-agent-skills | 74 game-dev skills across Godot/Unity/Unreal/Phaser/three.js/Bevy/pygame | Apache-2.0 | 2026-09-27 | ★1,365 | **RECOMMEND (as source)** — harvest per-engine skills from it for engine-specific detections |
| mcp-unity (CoderGamester) | mcp | github.com/CoderGamester/mcp-unity | Unity Editor MCP plugin for Cursor/Claude Code | MIT | 2026-09-03 | ★1,922 | SKIP — superseded by CoplayDev/unity-mcp momentum |
| godot-ui-integration | skill | github.com/zimo-xiao-zheng/godot-ui-integration | Codex skill: Godot UI from approved designs, visual-progress proof | MIT | 2026-08-23 | ★275 | MAYBE — nice niche (design→Godot UI) if gobstack adds a Godot-UI extra later |
| Godot-MCP-Native | mcp | github.com/yurineko73/Godot-MCP-Native | Godot-native MCP server, no deps | MIT | 2026-08-03 | ★836 | SKIP — duplicate function of the two above |

**Strongest starts:** Coding-Solo/godot-mcp (default) or hi-godot/godot-ai (alternative), GodotPrompter (skill-form Godot), CoplayDev/unity-mcp (Unity), gamedev-skills meta as harvest source.

## 4. BACKEND NODE.JS (API / DB / queues)

| name | kind | source URL | what it does | license | freshness | adoption | verdict |
|---|---|---|---|---|---|---|---|
| supabase/agent-skills (official) | skill pack | github.com/supabase/agent-skills | Official Supabase skills: DB, auth, storage, edge functions for agent workflows | MIT | 2026-10-02 | ★2,708 | **RECOMMEND** — covers the DB/backend slice with vendor-official quality |
| pg-aiguide (Timescale) | mcp + plugin | github.com/timescale/pg-aiguide | Postgres skills + docs MCP: helps agents write correct Postgres, avoid anti-patterns | Apache-2.0 | 2026-10-07 | ★1,860 | **RECOMMEND** — best Postgres-specific asset found; MCP form |
| honojs/skills (official) | skill pack | github.com/honojs/skills | Official agent skills for Hono | MIT | 2026-10-08 (today) | ★13 | **RECOMMEND** — official, brand-new, fresh; low stars expected for age |
| agent-nestjs-skills | skill pack | github.com/Kadajett/agent-nestjs-skills | NestJS skills for agents | no license file | 2026-07-23 | ★289 | MAYBE — only NestJS option; license must be resolved before cataloguing |
| openapi-to-skills | skill/tool | github.com/neutree-ai/openapi-to-skills | Generates context-efficient agent skills from any OpenAPI spec | Apache-2.0 | 2026-06-23 | ★342 | MAYBE — strong as a gobstack *generator* (turn user's API spec into extras) more than a catalogue entry |
| do-app-platform-skills | skill pack | github.com/digitalocean-labs/do-app-platform-skills | DigitalOcean App Platform: deployment, migrations, DB config skills | MIT | 2026-10-04 | ★37 | MAYBE — deployment/migration guidance, vendor-official but low adoption |
| agent-skills-standard | skill pack | github.com/HoangNguyen0403/agent-skills-standard | Best-practice skills per language/framework | MIT | 2026-10-08 (today) | ★572 | MAYBE — broad quality bar; harvest Node/TS entries |
| fastify-skills | skill pack | github.com/TheCodePace/fastify-skills | Fastify skills (undocumented) | no license | 2026-10-08 (today) | ★12 | SKIP — no license, no description, no adoption |
| prisma skills (various, e.g. oldirty/drizzle-orm-skill) | skill | github.com/oldirty/drizzle-orm-skill | Drizzle ORM skill for Claude Code | no license | 2026-02-24 | ★0 | SKIP — **GAP: no credible Prisma/Drizzle migration skill exists yet**; strongest gap found in this category |

**Strongest starts:** supabase/agent-skills, timescale/pg-aiguide, honojs/skills. **Known gaps:** no good Prisma/Drizzle migration skill, no BullMQ/queue-worker skill, no Express/Fastify skill with adoption — candidates to *write in-house* for the catalogue rather than curate.

---

## 5. FORMAT QUESTION — emerging standards for skill marketplaces

Verified findings:

1. **Agent Skills spec (agentskills.io) is the emerging standard.** `anthropics/skills/spec/agent-skills-spec.md` now just points to **https://agentskills.io/specification**. A skill = folder with `SKILL.md` (YAML frontmatter: `name`, `description` + optional `allowed-tools` etc.). Adopted across Claude Code, Codex, Cursor, OpenCode, Gemini CLI, Pi (per pstack ports and skills.sh).
2. **Registry/manifest formats to stay compatible with:**
   - **`.claude-plugin/marketplace.json`** — present in `anthropics/skills`; the Claude Code plugin-marketplace manifest (lists skills/plugins for one-command install).
   - **`skills.sh.json`** — present in `vercel-labs/agent-skills`; schema at `https://skills.sh/schemas/skills.sh.schema.json`. **skills.sh** (and skills CLI) is the cross-agent install channel ("install with the skills CLI on Claude Code, Cursor, and other agents"); claudemarketplaces.com and agentskills.io are the directories indexing that same format.
   - **`cursor/plugins`** (★10,341, no license) — Cursor's plugin specification + official plugins; pstack upstream lives here.
3. **Recommendation for `catalogue.tsv`:** keep columns that are a superset of the above manifests — `name, category, kind (skill|mcp|workflow), source_repo, path_within_repo, has_skill_md, license, stars, last_push, install_hint (copy-folder | mcp.json snippet | cli), verdict, reviewed_by, reviewed_date`. Install semantics: skill entries = copy the folder (portable everywhere); MCP entries = mcp.json registration with a separate scope; this keeps round-trip compatibility with skills.sh / marketplace.json exporters.

## 6. Notes & caveats for review

- **Brief correction:** `github.com/26medias/pstack` **does not exist** (404). Upstream pstack is **`cursor/plugins`** (Cursor plugin spec; poteto = Lauren Tan). Best maintained Claude-side port: **`michael-denyer/pstack-claude`** (★1,628, MIT, pushed today, multi-agent). Others: `ericlitman/open-pstack` (★388, MIT). These are **workflow**-kind (playbooks/principles), suited as extras only if gobstack has a workflow slot; also `poteto/brainmaxxing` (★321, MIT) for memory/skill-improvement.
- **License attention list:** `anthropics/skills` and `vercel-labs/agent-skills` have **no repo-level license file** — verify per-skill licensing or treat as reference implementations before redistribution. SINCE the 2026-10-09 hard gate, unresolved-license rows carry verdict **LICENSE-PENDING**: never pre-ticked, `gob extras install` refuses them (`license pending verification`) until a curator flips `license_status` to `verified` in catalogue.tsv. Affected here: vercel-agent-skills, anthropic-frontend-design, webapp-testing — and agent-nestjs-skills (MAYBE, no license file, license must be resolved before cataloguing).
- **irgolic:** no skills repo found — his notable repo is `AutoPR` (★1,372, workflows); nothing to catalogue from that name.
- All star counts and dates in this file were fetched live from the GitHub API on 2026-10-08; re-check freshness before any entry is promoted.
