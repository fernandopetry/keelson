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
| **Language profiles** | The Charter *instantiated* for a language/version (`backend/php.md`, `frontend/*`). Ships with PHP; other stacks are **generated on install** from your standard, then reviewed by you. |
| **The ficha** (`keelson.config.json`) | The per-project adapter: paths, quality commands, active profile, gates. |
| **Gates** | The definition of done: tests, lint, scope, security, verified behavior — calibrated to *complexity × risk*, not fixed. |

## Install

```
/plugin marketplace add fernandopetry/keelson
/plugin install keelson@keelson
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
standard and marks it `reviewed: false` until you sign off. Profiles you refine can be
contributed back to the plugin — that's how it grows, by curation, not by empty stubs.

## Repository layout

```
keelson/
├── commands/          # /keelson:* slash commands (the cycle)
├── agents/            # subagents: implementer, reviewers, profile-writer…
├── skills/            # spec / plan / task validators + state
├── hooks/             # doc-guard, security-guard (read the ficha)
├── guidelines/
│   ├── _meta/         # QUALITY-CHARTER.md · PROFILE-OUTLINE.md
│   ├── core/          # language-agnostic doctrine (always active)
│   ├── backend/       # php.md (reference example) · none.md
│   └── frontend/      # none.md (others generated on install)
├── templates/         # keelson.config.example.json · CLAUDE block
└── docs/_meta/        # method guide, decisions, learning log
```

## Status

`0.1.0` — early. The engine and the PHP reference profile are the stable core; the
profile generator and non-PHP profiles are evolving. Feedback and profile
contributions welcome.

## Author & license

Built by [Fernando Petry](https://github.com/fernandopetry). Released under the
[MIT License](LICENSE) — use it, fork it, adapt it to your team.
