# Contributing to keelson

Thank you for your interest in improving keelson. This repository **is** the plugin —
there is no separate source tree — so every change here ships to every consumer.
That is why the review bar for contributions is the same bar the plugin itself
enforces on the projects that adopt it.

## How contributions are reviewed and land (read this first)

External PRs are **reviewed as proposals**. This is deliberate, not distrust.
The repository maintains append-only registries — decision numbers, the plugin
version, the `CHANGELOG.md` — that collide silently between forks: a branch
based on an older `main` claims numbers that are already taken, and git merges
the duplicate entries **without any textual conflict**. Merging a stale base
would corrupt those registries invisibly.

The flow for a contribution is:

1. Your PR is reviewed as a **proposal** and registered in the maintainer queue
   ([docs/_meta/proposal-inbox.md](docs/_meta/proposal-inbox.md)) before any verdict.
2. The review produces a written verdict: **merge directly**, **absorb**,
   **absorb partially**, or **decline** — always with reasons anchored in the
   repository's quality rules.
3. **Direct merge** happens when the full ladder holds — all of it, no
   near-misses: your branch sits on the current `main` tip; no registry file is
   touched (`CHANGELOG.md`, `docs/_meta/decisions.md`, version files, the README
   *Status* section); the review finds **zero corrections**; and CI is green on
   the PR. Your commits then land **with your authorship** (rebase-and-merge),
   and the maintainer adds the release commit (version, changelog, decision
   entry) on top in the same batch.
4. Otherwise — the default — accepted work is **re-implemented on top of the
   current `main`, with credit to you** in the `CHANGELOG.md` entry and in the
   decision log ([docs/_meta/decisions.md](docs/_meta/decisions.md)). The first
   external PR to this repo (`/keelson:merge`) landed exactly this way,
   credited to its author.

Either way the credit is yours; the difference is whether your commits land
verbatim. A clear problem statement plus a focused diff is the highest-leverage
PR you can open — and meeting the ladder above makes it mergeable as-is.

## Before you open a PR

- **Open an issue first** for anything non-trivial — it lets us agree on the
  problem before you invest in a solution.
- **One concern per PR.** Small, focused diffs review faster and absorb cleaner.
- **Rebase on the latest `main`.** Stale bases are the main source of silent
  registry collisions described above.
- **Do not bump the version and do not edit** `CHANGELOG.md`,
  `docs/_meta/decisions.md` or the README *Status* section. Version numbers and
  decision numbers are assigned by the maintainer during absorption — claiming
  them in a PR guarantees a collision.

## Quality bar

The ruler is the **Quality Charter**
([guidelines/_meta/QUALITY-CHARTER.md](guidelines/_meta/QUALITY-CHARTER.md)) —
the same ten articles the plugin enforces on its consumers. The ones that most
often decide a verdict here:

- **Proof over assertion.** A behavior change ships with a test or fixture that
  fails without it. A bug fix is born with a **red fixture** reproducing the bug
  plus a positive control. The author's own checklist is not proof.
- **One owner per rule.** Every rule has exactly one owning file. Change the
  owner, never a copy — and grep for live copies your change might orphan.
- **The mechanical layer never invents errors.** Scripts and checks degrade
  with a WARNING when unsure; a false positive on a legitimate artifact is the
  worst defect this layer can have. A new check does not land without a fixture
  under `scripts/tests/`; changing a check's severity is an explicit decision,
  never a side effect.
- **Portability.** Shell scripts are bash 3.2-compatible with POSIX awk,
  shellcheck-clean, committed with the executable bit set. Hooks fail open
  (missing `jq` or config → `exit 0`), never blocking the consumer's flow.
- **Languages.** Doctrine (guidelines, commands, agents, skills, docs) is
  written in Portuguese; the public face (`README.md`, `CHANGELOG.md`, this
  file) and commit messages are in English, using
  [conventional commits](docs/_meta/conventions/commit-convention.md).
- **No consumer identifiers.** Real project names, paths, URLs or keys from
  keelson consumers never enter doctrine or registries — abstract the general
  pattern instead.

## Running the guards locally

The pre-commit hook runs the same quality guard as CI:

```bash
git config core.hooksPath scripts/git-hooks
```

CI (`.github/workflows/test.yml`) repeats the full set on Linux for every PR:
shellcheck, the regression suites, the sync and release checks. A green CI is
the floor for review, not the verdict.

## License

keelson is MIT-licensed. By contributing you agree that your contributions are
licensed under the same [MIT License](LICENSE).
