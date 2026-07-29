# Changelog

All notable changes to keelson are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows the 0.x rule
stated in `CLAUDE.md` — **new capability or break → minor**, **fix or fine-tuning → patch**,
bumped once per release batch.

Every entry points at the governance decision that motivated it (`docs/_meta/decisions.md`,
§4.x) so the *why* stays one hop away. The **Quality Charter**
(`guidelines/_meta/QUALITY-CHARTER.md`) is versioned separately and is noted only when it moved.

This repository carries no release tags, so each entry is anchored by the commit that bumped
`.claude-plugin/plugin.json`. Entries before `0.29.0` were reconstructed from those bumps, the
commit messages and the matching decisions.

## [Unreleased]

---

## [0.36.0] — 2026-07-28

Decision 4.57

### Added
- **`/keelson:update` — update the installed plugin in one step.** A new human-only
  command (`disable-model-invocation`) runs the bundled `scripts/update.sh`, which
  drives the Claude Code CLI in the order that matters: `claude plugin marketplace
  update keelson` *then* `claude plugin update keelson` (refreshing the marketplace
  alone does **not** update the installed plugin — and a failed refresh aborts, since
  proceeding on a stale cache would report "already up to date" untruthfully). Takes
  an optional `--scope user|project|local` pass-through; reads the before/after
  version from the CLI's plugin manifest (`installed_plugins.json` via `jq`, selected
  by scope) with a best-effort fallback on `claude plugin list`, and says "nothing to
  do" when the version didn't move. Failures are named errors (CLI missing from PATH,
  plugin not installed in that scope, development install), never silently worked
  around, and every applied update ends with the mandatory reminder that the running
  session keeps the old version until restarted (*restart required to apply*).
  Field-validated on a real consumer before landing.

---

## [0.35.0] — 2026-07-28

Decision 4.56

### Added
- **`/keelson:auto`'s delivery report now shows how long the session took.** The cycle
  gains a measured clock: at kickoff the Tech Lead runs `TZ=America/Sao_Paulo date` and
  records the timestamp in the BRIEF front-matter (`Largada`); as each stage completes,
  a mark is appended to the BRIEF's `Cronologia` section; the delivery report gains a
  mandatory line with the total wall-clock duration plus the per-stage breakdown
  (specify · plan · tasks · implement), displayed in Brasília time. Routes without a
  BRIEF file carry the kickoff mark inline and report the total only; a missing mark is
  reported as a named gap — never estimated. The timezone is pinned so behavior is
  identical on a UTC server/CI. Duration is transparency for the Director, never a stop
  trigger ("stamina is not a trigger" stays intact).

### Changed
- The canonical BRIEF contract (`docs/_meta/conventions/index-contract.md`) gains the
  `Largada` front-matter field and the `Cronologia` section that back the duration line.

---

## [0.34.0] — 2026-07-28

Decision 4.55

### Added
- **`/keelson:jira-sync` now accepts a single SPEC as its target.** Passing `SPEC-NNN`
  (or the SPEC's file path) scopes the reconciliation to that SPEC's subtree — the Epic,
  its Stories (declared FEATs or the implicit Story) and the sub-tasks of the TASKs whose
  covering PLAN includes the SPEC — leaving sibling SPECs untouched. Since the whole sync
  is idempotent, running it against a virgin SPEC *is* the bulk creation: this is the
  manual fallback for a cycle that finished with an empty tracker, while the `/keelson:auto`
  closure reconciliation (4.53) is still being proven in real runs. No new command and no
  second owner of the sync logic: the scope rule lives in the protocol's §12 and the
  command only orchestrates it.

---

## [0.33.0] — 2026-07-28

Decision 4.54

### Added
- **`PROPOSTA_PLUGIN` findings now come with a message written for the plugin
  maintainer.** The `agile-coach` already did the hard part — detecting process errors,
  deduplicating against the ledger, picking the rule's owner, computing the line budget,
  even rejecting proposals that were project lessons — but its output was a YAML block
  for the session that invoked it, illegible to a maintainer who wasn't there; proposals
  died in a log file inside a repository the maintainer never reads. The agent now
  composes a second output per proposal, `mensagem_mantenedor`: the concrete scene
  (stack, active gates, the command that ran, expected vs. happened, and the real cost
  of the failure — a retry, a review round, a gate that passed vacuously — which only
  the end of the cycle knows), the diagnosis and the minimal diff — never the
  generalized rule, which is the maintainer's job (generalizing from a sample of one is
  not the agent's). Each finding is explicitly addressed: **local** (fixed in the
  project, mentioned only as context) × **process** (the proposal itself) × the easy-to-
  miss third case — a local cause that reveals a question `/keelson:init` never asked,
  reported to both destinations. If an agent caused the failure, the first line says so
  before arguing why the design made it silent.
- **`/keelson:auto`'s delivery report gains a conditional section (item 7.5)**: with at
  least one `PROPOSTA_PLUGIN` in the cycle, the maintainer message(s) appear as a
  copy-paste block, ready for the Director to forward — the same mechanism as the
  handoff prompt, pointed at another recipient. No proposal → no section; it never
  blocks, and nobody invents a report to fill a form.

---

## [0.32.0] — 2026-07-28

Decision 4.53

### Added
- **`/keelson:auto`'s delivery step now reconciles the slug with Jira before reporting.**
  The per-command sync hooks (`specify` creates the Epic and Story, `tasks` the sub-tasks,
  `implement` transitions) were three independent chances to fail silently: no hook repaired
  the one before it, and the delivery hook only commented the push. The delivery step now
  runs the same idempotent reconciliation as `/keelson:jira-sync` — a cheap no-op when every
  hook fired, a repair pass when one didn't. Three attempts plus a net. Motivated by a real
  end-to-end run that ended with only the Epic on the board — no Story, no sub-tasks, no
  transitions — and a delivery report that never mentioned it.
- **Mandatory tracker-state line in the delivery report**, next to the diff composition:
  `Jira: <KEY> (Epic) · Story: <KEY|—> · sub-tasks: K/N · transitions: <n|none>
  (transition: <mode>)`, measured by the closing reconciliation, never recalled from the
  hooks. One line is enough for the Director to spot an incoherent board without opening
  Jira. New doctrine ruler: **best-effort means it never blocks — never that it doesn't
  report.** A skipped or failed sync shows up on this line with its reason.
- **The end-of-cycle tracker state is now defined by the method**, not emergent from a chain
  of triggers: the close of `/keelson:auto` is a trigger of the "ready for QA" milestone —
  sub-tasks Done, the QA unit (Story) at the human-wait status, Epic untouched (protocol §9).

### Fixed
- **A map file whose prose contradicts the ficha gets flagged.** When `jira.mapFile` states a
  policy (e.g. `transition: comment`) that the ficha contradicts (`auto`), behavior used to
  depend on which file the agent happened to read. The ficha wins; the sync and
  `/keelson:init`'s self-check warn "map out of date" wherever both files are already read
  together.

---

## [0.31.0] — 2026-07-28

Decision 4.52

### Added
- **The gate-9 walkthrough script is authored with the TASK, before any code exists.**
  With `gates.screenVerify` on and an AC assigned to gate 9, the TASK now carries a
  "Roteiro do gate 9" section: environment (typeable URLs — with the app's real route
  base — plus realm), a concrete subject (which identity logs in, with which credential),
  preconditions with a recipe (how to build the state and how to restore it afterwards
  — "a user without permission" is a wish, not a precondition), and one step per AC: a
  gate-9 AC without a step is an AC without a gate. Previous handoffs of the slug are
  required reading — a scenario already recorded there as non-exercisable doesn't become
  a step by inheritance: reuse the accepted substitute proof, or prescribe a new attempt
  naming what changed since ("non-exercisable" is a dated record, not a permanent
  verdict). Motivated by a real full cycle where the pre-code QA pass returned 16
  findings on freshly generated TASKs, all four recurring shapes traced back to the
  generator having no ruler for the gate-9 script.

### Changed
- **Gate-1 verification pairs must be falsifiable.** The command+expected pair fixed
  before the code (4.34) now has to answer "what state makes this command FAIL?" —
  without an answer, the criterion approves anything. Absence-shaped expectations
  (empty output, path not in the output) get called out as the dangerous pattern:
  absence is the default state of a poorly anchored command, so the command needs an
  explicit anchor — `git diff --name-only main...HEAD`, never bare `git diff
  --name-only`, which compares against the index and returns empty after the commit,
  approving any diff. "Didn't get worse" expectations (suite, type baseline) require
  the baseline captured up front, inside the criterion. A real criterion passed
  vacuously this way; the code reviewer caught it, the `task-validator` can't (its
  check is syntactic by design) — if the error recurs, the answer is a mechanical
  validator check, not a second rule.

---

## [0.30.2] — 2026-07-28

Decision 4.51

### Fixed
- **A responding MCP server is no longer taken for a configured one.** The first real
  `/keelson:init` under 0.30.0 found a server that answered fine and was wrong (`npx -y
  @playwright/mcp@latest`, no flags at all), and step 4.4 said to leave it alone. It now
  reads the effective config in named precedence order (project `.mcp.json` → per-project
  entry in `~/.claude.json` → global) and checks the flags that matter: `--output-dir`
  matching the ficha's `artifactsDir`, `--isolated`, and the chosen browser mode. Personal
  and global scopes are never edited by keelson — it hands you the command instead.
- **Multi-realm without `--isolated` now fails the self-check** instead of warning. With a
  persistent profile, `browser_close` between realms doesn't drop the session, so the
  second realm gets verified while still logged in as the first — the exact isolation bug
  the gate exists to catch. A divergent `--output-dir` fails too. Single-realm projects
  still get a warning.
- **`.playwright-mcp/` is gitignored.** Without `--output-dir` the server writes there, and
  `init`'s own probe navigation created the directory in a real run — an authenticated
  screenshot one `git add .` away from the repository. The ignore lines are now guaranteed
  **before** the probe runs, and `init` cleans up after itself.
- **Ignore coverage is proven, not inferred.** A `thoughts/` line no longer counts as
  covering `artifactsDir`: projects legitimately version part of `thoughts/`, so the check
  runs `git check-ignore` against the real path.
- **Corrected the personal-scope command** to the form verified in real use — the `--` goes
  after `npx`, separating its arguments from the server's own flags. Also documented that
  `add` won't overwrite an existing entry (remove it first) and that the session must be
  restarted.

---

## [0.30.1] — 2026-07-28

Decision 4.50

### Added
- **README section "Comments in generated code"** stating the comment doctrine publicly:
  the default is no comments; a comment exists only if deleting it would lose information
  the code can't give back (Charter Art. 7). The surviving comments are one-line
  `DEC-xx`/`FR-xx` anchors — a navigation graph from code to the decision behind it, not
  prose.

### Fixed
- **The PHP profile now materializes the docblock rule** the profile outline already
  required (§3): a docblock is mandatory only when it carries type information native
  syntax can't express — array shapes (`list<User>`, `array{id: int}`), generics for
  static analysis, actionable `@throws` — and must not exist when it restates a typed
  signature or is a ritual file/class header. This closes the gap that let community
  habit (full PHPDoc on every class and method) fill the silence, the main source of
  comment noise in generated PHP. The profile is `reviewed: true`, so the edit is
  flagged for human re-review.

---

## [0.30.0] — 2026-07-27

Decision 4.49

### Changed — **breaking for screen verification**
- **Screen verification now drives Playwright through MCP**, replacing the embedded browser
  as the single engine. The skill keeps its name and `method: "skill:screen-verify"` keeps
  working — no consumer ficha breaks — but the gate now needs the `@playwright/mcp` server.
  - **Headless by default**: no window steals focus, and the gate works on a machine with no
    display. The mode lives only in the MCP server config (`.mcp.json` or personal scope) —
    deliberately not mirrored into the ficha, since the server is what actually controls it.
  - **Realm isolation actually isolates**: one realm at a time with `browser_close` between
    them (tabs in one context share cookies, so the old "one tab per realm" rule guaranteed
    nothing). Cross-realm negative items stay inside the origin session.
  - The Playwright-as-a-library route is recorded as **rejected** for the default path (it
    would force Node onto a PHP project) but stays declarable in `gates.screenVerify.method`.

### Added
- **`/keelson:init` step 4.4** guarantees the browser runtime — proves the tools respond
  (MCP tools arrive deferred; not seeing them is not evidence), checks Node ≥ 18, writes the
  `.mcp.json` block after showing it (or hands you the `claude mcp add` command for personal
  scope), and offers to install the browser binary, always saying what it installed and
  where. Missing Node is reported as a pending item, never worked around.
- **Screen artifacts on disk**: screenshots and console/network dumps go to
  `gates.screenVerify.artifactsDir` (default `thoughts/screen-verify/<slug>/`, gitignored),
  with relative, speaking filenames. The artifact is never the proof — durable evidence
  stays textual in the HANDOFF and the slug INDEX.
- **Named unavailability diagnosis** (`handoff-protocol.md` §8.1): the probe distinguishes
  **missing browser runtime** × **missing credential** × **app down**, each with the command
  that fixes it. `qa` reports `causa_indisponibilidade`, `implement` rejects a generic cause
  when the probe knew which one it was, and no engine is silently swapped in as a fallback.
- README section covering requirements, macOS/Linux setup, the config block, artifacts, and
  the opt-in capabilities (`--caps devtools` for trace/video, `--allowed-origins`).

---

## [0.29.0] — 2026-07-27

Charter `0.5.1` · decision 4.48

### Added
- **This changelog**, backfilled from `0.1.0` — the release history stopped living only in the
  README's `Status` prose and in `git log`.
- **Release doctrine**: a version bump is not complete without a `CHANGELOG.md` entry. The
  version still lives in 3 synced places (`plugin.json` · `marketplace.json` · README `Status`);
  the changelog entry is now the fourth obligation of the same batch.

### Changed
- README `Status` points at the changelog instead of trying to be one — the section keeps the
  current headline and stops accumulating "Previously… / Recent…" prose.

---

## [0.28.0] — 2026-07-26

Decision 4.47 · `146d4f2`

### Added
- **`jira-guard` (Stop hook)** — the Jira sync stops depending on the model remembering it.
  Reading a *live* consumer session settled the diagnosis that 4.43–4.46 were chasing: nothing
  was broken (plugin `0.27.0` loaded, both command hooks present, Atlassian tools in the
  toolset, `jira.enabled` read) — the step simply never ran. It was the last sub-step, it was
  conditional, and it cost a re-read plus MCP calls in the middle of a code-focused run.
  The guard blocks the turn when the ficha has `jira.enabled: true` and an SDD artifact
  **touched on this branch** has no Jira key.
  - **Scope is narrow by branch** (working tree + diff against the base) — historical debt
    already merged would turn the guard into a perpetual nudge.
  - **Two ways out, never one**: sync, or record the skip with its proof (§0/§10) — the
    recorded skip clears the guard from then on, closing the pair 4.46 opened.
  - Standard keelson hook frame: bash 3.2, graceful fallback, `stop_hook_active` anti-loop,
    fingerprint anti-renudge. Validated with `bash -n` + 12 synthetic cases.

---

## [0.27.0] — 2026-07-26

Decision 4.46 · `787e753`

### Changed
- **Connector unavailability is proven, not presumed.** Before concluding the Atlassian
  connector is unavailable, load the tools (MCP tools arrive *deferred* and don't show up until
  searched) and make one cheap proof call (`atlassianUserInfo` /
  `getAccessibleAtlassianResources`). "I didn't see the tools in the list" is not evidence.
  MCP server names vary per install — resolve the tool by **suffix**, never by a fixed prefix.
- **A skipped or failed sync leaves a durable trace**: one line in the slug INDEX's "Histórico
  recente" — date, what would have been synced, why, and the proof evidence. `/keelson:jira-sync`
  reads those lines back and reports what was left behind. Same ruler decision 4.26 set for
  screen verification.
- `/keelson:init`'s self-check can only report "Jira sync skipped" with the proof attached.

Context: a consumer ran the cycle with `jira.enabled: true` for weeks and *none* of its 7 SPECs
got a key, with no record of why — best-effort worked as designed and degraded in silence.

---

## [0.26.0] — 2026-07-26

Decision 4.45 · `d0eed7d`

### Added
- **Required-field pre-check before bulk creation**: one `getJiraIssueTypeMetaWithFields` per
  issue type the plan uses; any uncovered `required: true` field is warned **before** the first
  creation. A missing required field isn't a skipped field — Jira rejects the whole issue, and
  the discovery would otherwise land on the *n*-th creation with the slug half-done.

### Fixed
- **TASK counting**: the source of truth is the `tasks/TASK-*.md` files **minus** `*-INDEX.md`
  (the glob was counting index files as tasks and inflating the per-SPEC distribution).
- **Canonical ID shapes** now have a single owner (`sdd-conventions.md`): FR/NFR/AC are bullets
  (`^- \*\*FR-`), FEAT is a heading (`^### FEAT-`), TASKs come from the glob without INDEX —
  plus the reading rule that was missing: **a count of `0` in a notoriously populated artifact
  means the pattern is wrong, not that the artifact is empty**.

---

## [0.25.0] — 2026-07-26

Decision 4.44 · `b0e0395`

### Added
- **Implicit Story step in the degradation ladder.** An epic-level `spec` type over sub-task
  `task` types with no FEAT layer now creates **one Story mirroring the SPEC** under the Epic,
  with the TASKs as its sub-tasks — because a SPEC that declares no features *is* a single
  feature (4.27). QA keeps a flow-level card instead of 70 dev-granularity ones. The ladder
  reads: **(0)** implicit Story → **(i)** `standalone` under the Epic → **(ii)** stop with a
  diagnosis. The Story gets its own header key (`**Jira Story**:`) and its "ready for QA"
  milestone when every TASK is `Done`.
- **Backfill warning (§12)**: before bulk creation, measure the real TASK state — mostly `Done`
  with `transition: comment`/`off` means the board would be born lying. The sync reports it up
  front with both ways out and never changes the ficha or forces a transition on its own.

### Changed
- The slug overview is read from its `INDEX.md`, not by walking `{docsRoot}/` (a real dry-run
  listed 37 directories before opening the artifact that already had the overview).

---

## [0.24.0] — 2026-07-26

Decision 4.43 · `9d1d2ab`

### Added
- **Feasibility is a precondition, not a discovery**: new step 0.4 in `/keelson:jira-sync`
  crosses `hierarchyLevel` against the FEAT declaration and classifies the projection in one
  line. Infeasible → the plan becomes a diagnosis plus a recommendation, instead of listing
  creations Jira would reject.
- **Anti-duplicate JQL probe** — recommended before bulk-creating with no local key, mandatory
  in `--dry-run`.

### Changed
- **The hierarchy-adjacency ruler moves to the core protocol** (§7.0, single owner) and is
  resolved **once** at the start, never issue by issue. It used to live only in
  `jira-sync-feat.md`, which is a no-op when the 3rd level is inactive — the exact scenario
  that produced, in a real sync, **7 orphan Epics and 70 sub-tasks rejected one by one**.
  A parent issue is never created when no child projection is possible.

### Fixed
- **The phantom "front-matter"**: the doctrine told agents to read the SPEC's Jira key from
  front matter, but keelson SPECs have no YAML front matter — the key lives on the markdown
  header line `**Jira**:`. The distinction (real YAML × `**Key**: value` header) now has a
  single owner in `sdd-conventions.md`, with explicit `grep` recipes.
- Missing ficha ≠ Jira disabled — `/keelson:jira-sync` separates the two and tells you to run
  from inside the consumer project.

---

## [0.23.0] — 2026-07-26

Decision 4.42 · `4192a0f`

### Added
- **`agent-guard` (PreToolUse on `Task|Agent`)** — cycle work only runs with the cast. A real
  transcript showed SPEC validation dispatched to a `general-purpose` subagent with an
  improvised prompt: a generic agent carries none of the role's doctrine, and a validator run
  "from memory" applies a different ruler. `keelson:*` always passes; a generic spawn whose
  prompt carries a **role-work fingerprint** gets a single `deny` telling it to re-issue with
  the cast agent (exploration and research pass). Anti-renudge by fingerprint — the second
  identical attempt passes, as a valve for deliberate generic use.
- **Validator execution rule** (owner: `validator-protocol.md` §2): a validator skill runs in
  the main session **or** in an executor subagent whose briefing **cites the canonical
  SKILL.md path**. A generic subagent validating without reading the SKILL.md is a deviation.

---

## [0.22.1] — 2026-07-26

`3ab34f0`

### Fixed
- Precise Agent Teams facts in the teams-mode owner.

---

## [0.22.0] — 2026-07-26

Decision 4.41 · `a37adcb`

### Changed
- **Coherence sweep across every living rule for the team model.**
  - Status promotion gains explicit **mode clauses** in its 6 owners (po/main session in the
    BRIEF cycle, human otherwise).
  - The **PO acceptance report moves to delivery item 2.5** — it gates *before* commit and push.
  - `specify` gains the BRIEF input channel; the inline mirror counts as the PO's brief for the
    bugfix/refactor and standalone-risk-TASK routes.
  - PO pre-code answers rewrite the ambiguous criterion instead of parking it in closure notes.
  - The autonomy boundary reads **"ends at the branch push, no PR"** everywhere.
  - The consumer `CLAUDE.md` block now teaches the autonomous default with the Director–PO
    contract — **re-run `/keelson:init`** to refresh the block.

---

## [0.21.1] — 2026-07-26

`f639fec`

### Fixed
- `/keelson:auto` resolves the slug and the BRIEF number at step 0.5, **before** the kickoff.
  The brief was persisted at 0.5 while slug resolution and SPEC numbering lived inside
  `specify` — an ambiguity that could write the brief into a parallel slug or mismatch the
  pairing number.

---

## [0.21.0] — 2026-07-26

Decision 4.40 · `cb0d0f1`, `85a6e4a`

### Changed — **breaking**
- **Agent ids renamed to real-life role names**: `task-implementer`→`developer`,
  `task-reviewer`→`code-reviewer`, `task-verifier`→`qa`, `security-reviewer`→`security-engineer`,
  `product-critic`→`product-analyst`, `process-tuner`→`agile-coach`,
  `profile-writer`→`staff-engineer`. Atomic: file renames plus every live reference (commands,
  skills, hooks, core guidelines, conventions, method guide, README).
- **History is never rewritten**: `decisions.md` and `learning-log.md` keep the old ids with a
  rename note on top; `generated-by:` stamps in generated profiles stay historical, and future
  generations stamp `staff-engineer`.

---

## [0.20.0] — 2026-07-26

Decision 4.39 · `d0868df`, `f7f1329`, `4f2b5b5`

### Added
- **`pm` agent** — owns the portfolio layer: decomposes a multi-demand brief into independent,
  prioritized, routable demands, each running its own SDD cycle with its own PO. Never conducts
  cycles, never decides per-demand product.
- **`/keelson:specify-epic`** — resolves the anchor slug, dispatches the PM, takes the
  Director's explicit confirmation of the decomposition (the one intentional stop) and persists
  the epic BRIEF (date-based id: epics don't pair with a SPEC). It hands back the prioritized
  queue; cycles are fired by the Director.
- `triage` gains category 7 (epic); `auto` proposes the epic route **pre-kickoff only** —
  post-kickoff scope expansion stays a PO escalation.

---

## [0.19.0] — 2026-07-26

Decision 4.38 · `b7854e7`, `3b9dea1`, `80a0337`, `575950e`, `ba2c5c8`

### Added
- **`po` agent** — owner of the demand on the Director's behalf: validates the SPEC and the
  delivery **against the BRIEF** (never against its own opinion), produces the acceptance
  report, and escalates only by exception, always with a proposal plus a default.
  `product-critic` is placed under the PO.
- **BRIEF as a durable artifact** — the Director's intent stops being conversation-only.
- **Director–PO contract** operationalized in `auto`, `specify` and `guided`: interpretation
  mirrored back in ~5 lines, veto window, no waiting for routine approval.
- **Lateral team signals with named routes**: plan gap (developer → tech lead), pre-code
  verifiability (qa → po), out-of-scope findings (reviewer/qa → tech lead).
- **Wave bulletin**: each wave closes with a team-language report addressed to the Director.

---

## [0.18.0] — 2026-07-25

Decision 4.36 · `9f54f84`

### Added
- **`/keelson:review`** — standalone code review for code that arrived without an SDD artifact
  (a diff, a branch, someone else's change), with the gate 1–7 ruleset **single-owned** by
  `guidelines/core/CODE-REVIEW.md` and executed by `code-reviewer` in both the cycle and the
  standalone route.

---

## [0.17.0] — 2026-07-25

Decision 4.35 · `8877f39`

### Changed
- **Instruction compression per load model** — an audit measured the real context cost per flow
  and restructured for on-demand loading without losing adherence:
  - Runtime owners split out of the method guide into `docs/_meta/conventions/`
    (`sdd-conventions`, `index-contract`, `handoff-protocol`, `agent-teams`); the method guide
    stays a human guide with one-line pointers (35k → 18.7k).
  - The Jira FEAT layer moves to `skills/_shared/jira-sync-feat.md`, loaded only when the 3rd
    level is active; command hooks get transitive read lists and partial reads via `grep`.
  - `developer`/`code-reviewer` read the active profile **by section** (1–5, 7, 9, 11
    unconditional; 6/8/10/12 gated; no-spine fallback = full read).
  - PHP profiles shrunk in place; human-review logistics moved to `guidelines/backend/_review/`.
  - `desc-guard` now covers agents (cap 350); `disable-model-invocation` on `audit` and
    `verify-handoff`; the consumer block slims from 3.2k to 2.6k.
- Quality Charter `0.5.0` → `0.5.1` (redundant-rationale pass).

---

## [0.16.0] — 2026-07-24

Decision 4.34 · `d469990`

### Added
- **Executable verification pre-code**: the TASK template attaches a command plus its expected
  result to each test criterion, fixed *before* the code exists, with a paired `task-validator`
  ERROR scoped to Todo/In Progress.
- **Phased schema migration** (expand → migrate → contract) in `WORKFLOW` §6 — legacy removal
  never ships in the same deploy as the code that stopped consuming it.

Both gaps came from an adversarial coverage review of an external letter on instructing AI
(13 of its 15 recommendations were already owned by keelson).

---

## [0.15.0] — 2026-07-24

Decisions 4.31, 4.32, 4.33 · Charter `0.3.0` → `0.5.0` · `f573e48`

> `0.14.0` was skipped: the batch bumped the plugin straight from `0.13.0` to `0.15.0` to track
> the Charter's two-step move.

### Changed
- **Comments have a floor and a ceiling, and density is not inherited from neighboring code**
  (Art. 5, Art. 7). Art. 7 collapses to one falsifiable test — *does deleting it lose
  information the code can't give back?* The old "same comment density as surrounding code"
  wording was, in verbose legacy bases, a fat factory.
- **Boy-scout rule sanctioned and declared** (Art. 6): legitimate iff within reading distance,
  behavior preserved, and declared per item. `developer` gains the `escoteiro:` report field;
  `code-reviewer`'s gate 4 tells declared cleanup from scope drift, and gate 7 loses the
  "excessive comments don't block" exemption.
- `/keelson:auto`'s delivery reports diff composition (production/test/docs/migration plus
  out-of-PLAN additions with a reason).
- **Coherence sweep**: `WORKFLOW` §6 rewritten by reversibility (it contradicted the `/auto`
  reaction ladder); `specify`/`plan`/method guide gain the autonomous-mode clause; gate 9's
  trigger aligns with its owner.
- **Rule form going forward**: falsifiable test plus anchor examples, single owner — agents
  reference the Charter, never duplicate it.

---

## [0.13.0] — 2026-07-24

Decision 4.30 · `8cf7864`

Lessons from the first real `/keelson:auto` run (a 2FA feature — the maximally sensitive case),
where the security gate ran only *after* delivery and caught a real critical bypass.

### Added
- **Delivery demands gate evidence, not gate recollection**: a deterministic pre-check before
  the push requires a `security-engineer` verdict on the final diff with
  `reviewed_by ≠ implemented_by`. "I checked as I built it" does not satisfy it.
- **`worktree-guard` (PreToolUse on Edit/Write/NotebookEdit)** — a session in a linked worktree
  writing into the main working tree gets denied with the worktree path.
- **Code identity is proven, not presumed** (mirror of 4.26): before trusting any functional
  exercise, prove the running process executes the diff's worktree/branch.

### Changed
- `security-guard` loses its self-certification valve — a clean exit now requires the
  `security-engineer` to have run.
- **Guard at the sink, not at the surface** (`core/SECURITY.md`): step-up lives where the data
  is written; enumerate every writer and prove the refusal at each one.
- SINGLE_THREAD waives orchestration, not independence — per-task attribution
  (implemented_by/reviewed_by/gate 8/gate 9) makes any collapse visible.

---

## [0.12.0] — 2026-07-24

Decision 4.29 · `5f6494f`

### Fixed
- **250-character cap on command and skill `description`.** `/keelson:verify-handoff` had
  vanished from the command list: Claude Code (≥ v2.1.86) **silently hides** a command whose
  frontmatter description exceeds 250 characters and truncates a skill's. Descriptions
  shortened with trigger terms up front, detail moved into the body.
- **`desc-guard` (Stop hook)** measures in code points and blocks the turn listing every
  offender — active only in the keelson dev repo, `exit 0` everywhere else.

---

## [0.11.0] — 2026-07-23

Decision 4.28 · `12a7167`

### Added
- **Jira hierarchy guardrail**: `/keelson:init` validates that the configured type mapping
  actually nests (Jira only links strictly adjacent hierarchy levels) and warns with the
  correct type when a leg doesn't.
- **`issueType.standalone`** for one-off work (a bugfix or chore routed straight to a TASK, or
  a cross-cutting task with no honest primary feature) — a level-0 card QA can test on its own,
  hung under the Epic when the hierarchy allows.

---

## [0.10.0] — 2026-07-23

Decision 4.27 · `6add21c`

### Added
- **Optional feature layer (`FEAT-*`)** — the QA unit of test, collapsible: a SPEC that declares
  features plus a configured `issueType.feature` gets the full Epic ▸ Story ▸ Sub-task
  projection, with a "feature ready for QA" milestone per Story. Both opt-ins missing → nothing
  changes.

---

## [0.9.0] — 2026-07-23

Decisions 4.25, 4.26 · `10c611e`

### Added
- **Multi-realm screen verification**: named realms in `keelson.local.json` (each with its own
  URL and DEV credentials), so a project with more than one authenticated surface can be
  verified.
- **Proof of unavailability**: gate 9 only degrades into a HANDOFF after a probe that actually
  failed and was recorded — never on the assumption that the environment is down.

---

## [0.8.0] — 2026-07-23

Decisions 4.23, 4.24 · `e98e46c`

### Changed
- **Running out of breath is not a trigger**: `/keelson:auto` runs to Delivery and no longer
  stops at a "clean point" between waves.
- **`wave-guard` (Stop hook)** plus an on-disk run-state make it mechanical instead of a
  matter of the model remembering.

---

## [0.7.0] — 2026-07-22

Decision 4.22 · `b1bb97a`

### Added
- **Optional Jira integration** via the Atlassian MCP connector: issue types, statuses and
  custom fields are **discovered at runtime** by `/keelson:init` and stored as **IDs** in the
  ficha (no site, project key or field id ever ships in the plugin). Two modes (`create` /
  `link`), default status policy `comment` (moving cards is opt-in per project and validated
  against the live workflow), and `/keelson:jira-sync` for idempotent reconciliation.

---

## [0.6.0] — 2026-07-22

Decision 4.21 · `c49e122`

### Changed
- **Namespace naming doctrine** recorded, plus the renames `guiado` → `guided` and
  `state` → `status`.

---

## [0.5.1] — 2026-07-22

Decision 4.20 · `498dcdf`

### Changed
- **Anti-redundancy trim** across commands, agents and skills: a native harness capability is
  not re-instructed. `security-engineer` reads the `core/SECURITY.md` checklist at runtime
  instead of replicating it.

---

## [0.5.0] — 2026-07-22

Decision 4.19 · `eaec382`

### Added
- **Legacy PHP ladder embedded** (5.6 · 7.0 · 7.4 · 8.0) with **nearest-lower** version
  resolution — a generated profile starts from the closest embedded version *below* the
  project's and writes only the delta, never from a higher one.

---

## [0.4.0] — 2026-07-22

Decisions 4.16, 4.17, 4.18 · `871bcf9`, `33ab90a`, `657cd45`

### Added
- **Multi-edition OWASP superset plus CVE/NVD** as the security gate's ruler.
- **`/keelson:audit`** — dependency audit outside the task cycle.
- Repo `CLAUDE.md` with the plugin's own development conventions (versioning, doc sync, commit
  style).

### Changed
- `/keelson:change` renamed to `/keelson:triage`.

### Fixed
- `security-guard`'s PATTERN loses its PHP/JS bias — multi-language superset by category.

---

## [0.3.1] — 2026-07-22

Decision 4.15 · `3521e88`

### Added
- **`review-guard` (Stop hook)** — forced code review for code written outside the SDD flow,
  with a size threshold.

---

## [0.3.0] — 2026-07-22

Charter `0.2.0` → `0.3.0` · `6ead08a`, `9d54075`

### Changed
- Clean-code doctrine into the Charter: parameters, effects in the name, conditionals, naming
  red flags (`0.2.0`); abstraction parsimony and patterns as vocabulary (`0.3.0`). Plugin
  version realigned with the Charter.

---

## [0.2.5] — 2026-07-20

`1bf6538` (LRN-015/016/017)

### Fixed
- Process-chain tuning from an audit: the ficha reaches the validators, the INDEX contract is
  enforced, gate briefing is explicit.

---

## [0.2.4] — 2026-07-18

`a155bb3` (LRN-014)

### Fixed
- `/keelson:auto`'s understanding mirror is written in the conversation body, not in a dialog.

---

## [0.2.3] — 2026-07-18

Decision 4.14 · `b6f1062`

### Added
- **Understanding mirror on the last call**: the confirmed prompt is the contract.

---

## [0.2.2] — 2026-07-18

Decision 4.13 · `de9e6ea`

### Added
- **Absent mode** in the autonomous cycle: last call plus reaction ladder (recalibrates 4.11).

---

## [0.2.1] — 2026-07-17

`fc54360`

### Changed
- `/keelson:init` is merge-preserving; `keelson.local.example.json` is versioned.

---

## [0.2.0] — 2026-07-17

`806a9c5`

### Added
- **`screen-verify` skill** and the local access config — screen verification becomes a method
  (`screenVerify` gate) instead of an ad-hoc request.

---

## [0.1.3] — 2026-07-17

`3eb088b`

### Added
- **`/keelson:verify-handoff`** — closes a pending screen-verification HANDOFF.

---

## [0.1.2] — 2026-07-17

`9541b71`

### Added
- **`stale-background-guard` (Stop hook)**.

---

## [0.1.1] — 2026-07-17

`1d8469c`

### Fixed
- Full review pass: plugin/project boundary, hook anti-renudge, profile resolution.

---

## [0.1.0] — 2026-07-16

`079b973`

### Added
- **Initial scaffold**: the SDD engine (`specify → plan → tasks → implement`), the Quality
  Charter, the Profile Outline, language profiles, validators and the first hooks.
