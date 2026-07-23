# ⚓ Keelson

**Spec-driven development for Claude Code — one portable, verifiable quality standard, applied across languages through automated gates and per-language profiles.**

> A *keelson* is the beam that reinforces a ship's keel from the inside — the structure
> that keeps everything aligned and on course. That's the job of this plugin: keep a
> team's work aligned to one quality bar, no matter the language or the project.

---

## Why

Most quality standards live as tribal knowledge or as a wiki page nobody reads. Keelson
turns *your* standard into something an AI agent applies on every change — and that a
human can verify — while staying **portable across projects and languages**.

It separates two things that usually get tangled:

- **The engine** (generic): a spec-driven workflow (`specify → plan → tasks →
  implement`), quality gates, validators, and a language-agnostic **Quality Charter**.
- **The adapter** (per-project): a small `keelson.config.json` — where your code lives,
  which commands test/lint it, which language profile applies, which gates are on.

Same engine everywhere; only the ~15-line adapter changes.

## Core ideas

| Piece | What it is |
|-------|------------|
| **Quality Charter** | Nine language-agnostic articles that define "good". Each carries a *falsifiable rule* — how you prove it was met. Proof is external (a test), never a self-checklist. |
| **Profile Outline** | The mandatory table of contents every language profile fills in — so a Node profile covers the same ground as the PHP one (parity). |
| **Language profiles** | The Charter *instantiated* for a language/version (`backend/php.md`, `frontend/*`). Ships with PHP — the 8.5 exemplar plus a curated legacy ladder (5.6 · 7.0 · 7.4 · 8.0); other stacks are **generated on install** from your standard, then reviewed by you. |
| **The ficha** (`keelson.config.json`) | The per-project adapter: paths, quality commands, active profile, gates. |
| **Gates** | The definition of done: tests, lint, scope, security, verified behavior — calibrated to *complexity × risk*, not fixed. |

## Install

```
/plugin marketplace add fernandopetry/keelson
/plugin install keelson@keelson
```

To update to the latest version (refreshing the marketplace alone does **not**
update installed plugins):

```
/plugin marketplace update keelson
/plugin update keelson
```

## Quick start

In your project, run the interactive setup:

```
/keelson:init
```

It **detects what it can** (language, version, test/lint commands, whether there's a
frontend) and **only asks what it can't infer**. When your stack has no bundled profile,
it offers to **generate one from the Charter** at the same quality bar as the PHP
example — which you then review. It writes `keelson.config.json` and a managed block
into your `CLAUDE.md`.

Then work the cycle:

```
/keelson:specify   # capture the spec
/keelson:plan      # design the change
/keelson:tasks     # break into tasks
/keelson:implement # build, gated
```

or `/keelson:auto` for the autonomous end-to-end cycle.

## Commands

**The cycle** — each step gated by its validator:

| Command | What it does |
|---------|--------------|
| `/keelson:specify` | Capture a functional SPEC (EARS requirements, Given-When-Then ACs), tech-agnostic |
| `/keelson:plan` | Turn an approved SPEC into a technical PLAN (components, DEC decisions with alternatives) |
| `/keelson:tasks` | Break a PLAN into atomic TASKs ordered in waves, closure fields prepared |
| `/keelson:implement` | Execute the PLAN wave by wave via subagents (implementer → reviewer + dedicated gates) |

**Orchestration** — how you enter the cycle:

| Command | What it does |
|---------|--------------|
| `/keelson:auto` | The default: full cycle end-to-end — critical questions once at kickoff, then no per-step approval |
| `/keelson:guided` | Opt-in paused cycle — checkpoints at SPEC and PLAN for your OK |
| `/keelson:refine` | Polish a raw idea into a refined prompt before it becomes a demand |
| `/keelson:triage` | Triage a new demand — routes to SPEC, PLAN, TASK or direct action (classifies, doesn't execute) |

**Support:**

| Command | What it does |
|---------|--------------|
| `/keelson:init` | Interactive setup — detects the stack, writes the ficha and the `CLAUDE.md` block |
| `/keelson:integrate` | Validate the DoD, run the full suite, open the PR (merge and deploy stay human) |
| `/keelson:jira-sync` | Reconcile a slug with Jira via the Atlassian MCP connector — idempotent, best-effort (optional) |
| `/keelson:audit` | On-demand dependency audit against known vulnerabilities (CVE/NVD); `full` adds hygiene (outdated, abandoned, licenses) |
| `/keelson:status` | Executive summary of a slug's current state — what's done, in flight, planned |
| `/keelson:migrate-legacy` | Migrate a legacy slug (docs without `INDEX.md`) to the SDD layout |
| `/keelson:rebuild-index` | Rebuild a slug's `INDEX.md` from scratch out of its artifacts |
| `/keelson:verify-handoff` | Close a pending screen-verification handoff produced in an environment without display |

## How customization works

You never edit the engine. You edit the **ficha**:

```jsonc
{
  "profile": { "backend": { "lang": "php", "version": "8.5" },
               "frontend": { "lang": "none", "version": null } },
  "codePaths": { "backend": ["src"], "frontend": [] },
  "quality":   { "test": "composer test", "lint": "..." },
  "gates":     { "security": true, "screenVerify": false }
}
```

New language or version? `/keelson:init` generates a candidate profile from your
standard and marks it `reviewed: false` until you sign off. When the language ships
embedded profiles (PHP), the generator starts from the **nearest embedded version
below** the project's and writes only the delta — never from a higher version, whose
recommendations wouldn't exist in your runtime. Profiles you refine can be
contributed back to the plugin — that's how it grows, by curation, not by empty stubs.

## Jira integration (optional)

If your team runs work on Jira, keelson can mirror the SDD cycle onto it — a SPEC becomes
an issue (or Epic), each **feature** (a QA-testable flow declared in the SPEC, `FEAT-*`)
becomes a Story, its TASKs become sub-tasks, and progress flows back as comments (or
transitions). It's **off by default** and **best-effort**: it never blocks the cycle.

- **Connector, not tokens.** It works through the **Atlassian MCP connector** — no API token,
  no SDK, nothing in `keelson.local.json`. If the connector isn't authorized, the sync is
  simply skipped with a note.
- **Discovered, never hardcoded.** `/keelson:init` learns your project's issue types, statuses
  and custom fields at runtime (Jira metadata) and stores **IDs** in the ficha's `jira` block.
  No Atlassian site, project key or field ID ever ships in the plugin.
- **Two modes.** `create` (keelson creates the SPEC issue + sub-tasks — ideal for a clean,
  team-managed project) or `link` (it hangs work under an issue you already opened — ideal for
  a governed, company-managed project).
- **Two or three levels.** SPECs with a single deliverable flow stay on the 2-level projection
  (SPEC issue ▸ sub-tasks). SPECs that declare features (`FEAT-*` headings) plus a configured
  `issueType.feature` get the full Epic ▸ Story ▸ Sub-task hierarchy, with a
  "feature ready for QA" milestone per Story. Both opt-ins missing → nothing changes.
- **Custom fields & board columns** live in a per-project map file (`jira.mapFile`, a Markdown
  table) that `init` scaffolds and you fill in — write-enrichment (`fixed`/`from`) and, in
  `link` mode, read-seeding of the SPEC.
- **Status policy.** Default `comment` posts progress without moving the card; moving cards is
  opt-in per project (`transition: auto`), always validated against the live workflow.

The ficha's `jira` block (all IDs, zero secrets):

```jsonc
"jira": {
  "enabled": false,
  "site": null, "cloudId": null, "projectKey": null,
  "mode": "create",                       // "create" | "link"
  "issueType": { "spec": null, "feature": null, "task": null },
  "transition": "comment",                // "off" | "comment" | "auto"
  "mapFile": null, "boardId": null
}
```

Re-run `/keelson:jira-sync <slug>` any time to reconcile what a best-effort run skipped.
Governance: decisions 4.22 and 4.27 in `docs/_meta/decisions.md`.

## Repository layout

```
keelson/
├── commands/          # /keelson:* slash commands (the cycle)
├── agents/            # subagents: implementer, reviewers, profile-writer…
├── skills/            # spec / plan / task validators + state + screen-verify
├── hooks/             # doc-guard, security-guard, review-guard, stale-background-guard, wave-guard
├── guidelines/
│   ├── _meta/         # QUALITY-CHARTER.md · PROFILE-OUTLINE.md
│   ├── core/          # language-agnostic doctrine (always active)
│   ├── backend/       # php.md (8.5 exemplar) · php-{5.6,7.0,7.4,8.0}.md (legacy ladder) · none.md
│   └── frontend/      # none.md (others generated on install)
├── templates/         # keelson.config.example.json · keelson.local.example.json · CLAUDE block
└── docs/_meta/        # method guide, decisions, learning log
```

## Status

`0.10.0` — early. The engine and the PHP reference profile are the stable core; the
legacy PHP ladder (5.6/7.0/7.4/8.0) ships as reviewed-pending drafts, and the
profile generator and non-PHP profiles are evolving. The optional Jira integration
(via the Atlassian MCP connector), multi-realm screen verification and the optional
feature layer (`FEAT-*`, the QA unit with 3-level Jira projection) are new.
Feedback and profile contributions welcome.

## Author & license

Built by [Fernando Petry](https://github.com/fernandopetry). Released under the
[MIT License](LICENSE) — use it, fork it, adapt it to your team.
