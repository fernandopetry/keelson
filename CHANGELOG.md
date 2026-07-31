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

## [0.49.0] — 2026-07-31

Decision 4.73

### Added
- **`code-scout` agent — anchored-conclusion codebase reconnaissance.** A tool outside
  the team cast (like the validators, not a role): the Tech Lead (main session)
  delegates broad codebase sweeps during exploratory phases (triage, specify, plan,
  status, standalone review) and gets back a short conclusion where every structural
  claim cites its `file:line` anchor — never file dumps, so the exploration stops
  polluting the main session's context. Claims without anchors don't become facts;
  gaps are reported as *not found*, never filled with plausible guesses. Runs on
  `sonnet` (read-only tools) — reconnaissance is pre-generation, not judgment, so the
  4.70 axis ("cheap generation, expensive judgment") stays intact. Deliberate limits:
  point lookups stay inline (the round trip only pays for broad sweeps), and
  exhaustive censuses ("every usage of X" before a rename) still require the caller's
  verification, with a declared confidence level in the report.

---

## [0.48.1] — 2026-07-31

Decision 4.72

### Fixed
- **Real-consumer input is abstracted before it becomes a record.** The 4.71 batch let
  a consumer project's literal config glob and episode slug travel into the CHANGELOG,
  the init doctrine and the decisions log. New standing rule (owner: this repo's
  `CLAUDE.md`): consumer identifiers — project names, demand slugs, paths, globs, URLs,
  key names — never enter doctrine, decisions or the CHANGELOG; what gets recorded is
  the generic pattern the case teaches, phrased so it works for any project. Applied
  retroactively to the 4.71 texts.

---

## [0.48.0] — 2026-07-31

Decision 4.71

### Added
- **`quality.boot` config field** — how this project's app is brought up for local
  exercise (`docker compose up -d`, a dev-server script…). `/keelson:init` detects it,
  asks when unsure (`null` is a valid answer — a permanent environment — but a chosen
  one, never a silent default) and self-checks that the declared command exists on
  disk. With `boot` declared, QA may only report `app_fora_do_ar` after actually
  attempting the boot and re-probing, with the attempt recorded as evidence; an absent
  field on an older config is a config gap to fill, not a presumption.
- **"Lessons registered" section in the delivery report** — a lesson persisted on a
  wave branch is declared **pending merge** until it lands on main; reporting it as
  "registered" without that state is the same false green the gates exist to prevent.

### Changed
- **Gate 9 waiver causes are a closed enum at acceptance time.** The main session now
  rejects a QA `PARCIAL` report whose `causa_indisponibilidade` is not one of
  `runtime_browser | credencial | app_fora_do_ar` (§8.1) — the waiver's grantor doesn't
  get to grow the catalog. A novel value signals the real blocker has another route
  (missing test data is created or escalated, never waived).
- **The code-reviewer's report declares gate-1 falsifiability.** The four mechanical
  anti-tautology checks from 4.68 are now a structured sub-field
  (`falsificabilidade:`) of the AC-coverage gate, mirroring the gate-6 sub-item
  pattern — applied and declared, not presumed.
- **A documented pendency is no longer a license for `Done`.** The developer contract
  states it explicitly: an unrealized AC, a verification that didn't run or a
  dependency that didn't answer imposes `Blocked`/`Failed` with the pendency under
  `falhas` — however well-narrated the blocker is, `Done` asserts everything the TASK
  requires was done and verified.
- **Init's self-check proves `sensitiveGlobs` coverage by real matching.** Secret-shaped
  files that exist in the project (`.env*` at any level — root included —, `*.pem`,
  `*.key`, project credential files) must each match some glob, proven mechanically
  (same ruler as 4.51); measured failure: a config whose globs covered subdirectory
  `.env*` files while the root `.env` went uncovered — and leaked. Uncovered
  candidate → add the exact-path glob.

The sixth postmortem residue — a hook governing *how* secret files are read (a `grep`
that echoes values where `cut -d= -f1` suffices) — is deferred to its own decision: it
needs false-positive design that doesn't fit this batch.

---

## [0.47.0] — 2026-07-30

Decision 4.70

### Changed
- **Per-role model assignment: cheap generation, expensive judgment.** Every agent now
  declares an explicit `model:` in its frontmatter instead of inheriting the session
  model. High-volume execution runs on `sonnet` — `developer` (the cycle's biggest
  token consumer, implementing an atomic TASK whose thinking already happened upstream
  in SPEC → PLAN → TASK), `qa` (runs and compares against literal ACs) and
  `agile-coach` (small process patches). Judgment and decision-making run on `opus` —
  `code-reviewer` (the net that holds quality when generation gets cheaper),
  `security-engineer`, `po`, `pm`, `product-analyst` and `staff-engineer`. The
  asymmetry is deliberate: cheapening the generator is safe *because* the evaluators
  stay strong. Validators (skills) are unaffected — they run in the invoker's context
  on the session model. This lowers cost per token, not context volume; the distilled
  briefing discipline (4.35) remains the volume lever.

---

## [0.46.0] — 2026-07-30

Decision 4.69

### Added
- **`/keelson:postmortem` — the end-of-session postmortem as a command.** The two
  consumer postmortems that moved doctrine the most (4.67, 4.68) were written by hand,
  on request — the same gap 4.54 closed for single findings. The existing machinery
  covers the *single* process finding at cycle close (`agile-coach` → `PROPOSTA_PLUGIN`
  → maintainer message); nothing owned the *whole episode*. The new human-only command
  is run by the Diretor at session end (default target: the current session — its
  interactions are the input) or pointed at a past episode. It re-reads every
  interaction (corrections asked, retries, failed gates, "forgot to mention" moments),
  cross-checks git and cycle artifacts, and builds: a facts table with an honest count
  (defect ≠ new scope — a requirement remembered later is not a defect), root-cause
  mechanisms with literal evidence (which gate saw it and approved, didn't run, or
  couldn't see — down to quoting the weak assertion), and the cheapest missed
  intervention point for each, including the Diretor's own. Addressing has one owner
  per finding: project lessons are applied on the spot; process findings are dispatched
  to the `agile-coach` (one invocation per root cause), which keeps its monopoly on
  proposal format (ledger dedup, literal diff, line budget — 4.54/4.64); reasoning
  failures and one-off cases are *declared discarded* — rules only for verification
  failures, never "a better model wouldn't". Outputs: a durable
  `<docsRoot>/_meta/postmortems/PM-<date>-<target>.md` plus the copy-paste maintainer
  block that feeds plugin evolution. The command analyzes, never fixes — open defects
  route to `/keelson:triage`. No new agent.

---

## [0.45.0] — 2026-07-30

Decision 4.68

### Added
- **Assertions that can actually fail — mechanical anti-tautology rules.** Real consumer
  postmortem: an e-mail delivery shipped with four defects visible in seconds in the
  rendered artifact (missing photo, duplicated headline, wrong currency in 5 countries,
  `file://` link) — with every gate green. The tests existed and passed, but could not
  fail with the behavior: expected values computed by calling the production code,
  "contains" assertions proving uniqueness, always-filled fixtures hiding fallback
  branches, one locale tested against an "all locales" NFR. `core/TESTING.md` gains an
  "Assertions that prove" section with four mechanical rules (independent expected
  value · uniqueness by counting · one case per fallback branch · quantified
  requirements as case tables), and `core/CODE-REVIEW.md` gate 1 applies them as
  blocking findings — a tautological test counts as *no test* for its AC. The
  `developer` (step 5) gets the same ruler at write time.
- **Creatable test data is not an environment gap.** The gate that would have caught
  everything (behavior verification) self-granted a pending handoff because the needed
  record "was not in the dataset" — while the database was up and the record creatable
  in seconds. `handoff-protocol.md` §8.1 and the `qa` agent now rule: "not found" ≠
  "not possible". With the environment up, missing data gets **created** (seed, factory,
  API); creation needing out-of-session access or decisions gets **escalated** (proposal
  + default) before any AC is declared unverifiable. A data-blocked item only exists
  with the creation attempt or escalation recorded — otherwise it is a shortcut handoff,
  same ruler as the unprobed-environment rule (4.26).
- **Rendered artifacts are evidence.** For renderable output (HTML e-mail, template,
  generated document) the `qa` exercise now renders with representative data, inspects
  the artifact itself (AC elements, duplication, links, empty-field fallbacks), saves it
  and cites the path in the evidence — so the human review sees at a glance what a
  20-item gate checklist hides.

### Changed
- **The runner's toolchain is a test double too** (`core/TESTING.md`, "the double is not
  production"): 6137 green tests, dead application — Jest transpiled with modern Babel
  while the runtime loaded through an old parser. When the runtime loads code through a
  different path than the runner, a green suite does not prove the app boots: changes to
  runtime-loaded code require a load/boot proof in the real runtime.
- **Gate 2 gains the sanctioned full-suite exception** (`core/CODE-REVIEW.md`): shared
  wide-reach data (locale, global config, central fixture) whose consumers cannot be
  confidently enumerated by grep/imports → the scoped run is insufficient, run the full
  suite. Fixing the shared locale data had broken two specs of another feature that only
  the full suite revealed.

---

## [0.44.0] — 2026-07-30

Decision 4.67

### Added
- **UI actions must specify observable feedback — at the SPEC level.** Real consumer
  case: a button that sends an e-mail on click shipped with no visual feedback at all,
  and the whole cycle approved it — the team delivered exactly what the SPEC asked for.
  The rule lands where it generates enforcement for free instead of as implementation
  prose someone must remember:
  - `/keelson:specify` gains mandatory principle 9, the **three states of a UI action**:
    an FR for a user-initiated interface action MUST specify the observable behavior of
    *in progress*, *success*, and *failure*. An invisible effect (e-mail sent, record
    saved, job dispatched) is not feedback — feedback is what the screen shows. Each
    state becomes a verifiable AC, so gate 1 (test per AC) and gate 9 (QA proves
    behavior) inherit the enforcement with no new machinery.
  - The `product-analyst` critique axis for scenario coverage now asks the classic
    missing-scenario question explicitly: does the user *perceive* the success, *see*
    the failure, *know* it is in progress?
  - A mechanical `spec-validator` check is deliberately **not** added — semantic rule,
    sample of one; reserved for recurrence (same ruler as 4.52/4.64).

---

## [0.43.0] — 2026-07-30

Decision 4.66

### Added
- **A failing verification can no longer be silently bypassed.** Real case from a consumer
  session: a pre-existing red Jest suite on main led the session to commit with
  `--no-verify`, run no tests at all — its own or anyone's — and report nothing. Four
  patches, each in the rule's owner, plus a mechanical guard:
  - `core/TESTING.md` gains the doctrine section **"Verificação que falha não se
    contorna"**: a failing (or un-runnable) verification has exactly two exits — fix the
    cause, or stop and report the blocker. A pre-existing error explains where the red
    came from; it never licenses delivering without proof. The named bypasses
    (`--no-verify`, narrowing the runner filter to exclude the red test, pass-with-no-tests
    flags, skipping/deleting tests, silence) are all the same gate violation as the silent
    workaround of decision 4.38.
  - The `developer` agent gains a mandatory **baseline step**: run the scoped suite once
    *before touching code*. Red baseline → stop and report `Blocked` right there, while
    reporting is still cheap; the Tech Lead decides (fix, park, or sanction proceeding
    with the red declared). The final run is compared against the baseline: no new red.
  - The developer report gains a mandatory **`verificacao` field** carrying the literal
    command executed and its result, for both baseline and final runs — "did not run:
    reason" is a valid state; omission never is.
  - **Gate 2 now measures regression, not the past**: a declared-and-sanctioned
    pre-existing red does not fail the gate by itself; a new red, an *undeclared*
    pre-existing red (rejected for omission), or evidence produced by a bypass does.
    Declaring passes, hiding fails — the incentive now points at honesty.
  - New `hooks/noverify-guard.sh` (PreToolUse on Bash) blocks `git commit/push
    --no-verify`; the conscious, named escape is prefixing the command with
    `KEELSON_ALLOW_NO_VERIFY=1` (same rule as 4.63). Doctrine covers the agent that reads
    it; the guard covers the one that didn't.

---

## [0.42.0] — 2026-07-30

Decision 4.65

### Fixed
- **The QA unit no longer ends the cycle in "done".** In the first real end-to-end run of
  the real-time board (0.41.0), the closing reconciliation walked the Story all the way to
  the last column — the exact move the 4.62 ceiling exists to prevent. Three fixes, one per
  cause: the sync protocol's §9 is now a **read prerequisite for any card movement** (and
  `/keelson:auto` lists it explicitly — it did not before); the **ceiling is resolved as a
  value** before moving (`ceiling = target status of "Trabalho iniciado (Story)"`; row
  missing → ceiling is the current status, comment only); and outside `--phase` there is
  **no route** past it — no combination of green gates, PO acceptance or a finished cycle
  moves the QA unit further.

### Changed
- **The board map is documentation, not a source of triggers.** Only the four canonical
  milestones and the `--phase` rows are ever *executed*. Any other row — the free-prose
  workflow notes that accumulate in a human-edited map, e.g. *"QA validates the feature /
  PR opened"* — is now explicitly documentation: it never fires, and it is reported as a
  one-line warning. Corollary spelled out: no keelson gate or agent (QA gate 9, code review,
  PO acceptance, push) satisfies a trigger that names a human act.
- **Reports state the ceiling.** `/keelson:jira-sync` gained a `Unidade de QA: <KEY> em
  <column> (teto: <column>)` line, and the mandatory tracker line of `/keelson:auto` now
  carries the Story's current column and its ceiling — a silently applied ceiling was
  indistinguishable from a forgotten one.
- `/keelson:init` now diagnoses **non-canonical milestone rows** in an existing map (lists
  them and recommends renaming or commenting them out) and never edits the human's table.

---

## [0.41.1] — 2026-07-30

Decision 4.64

### Changed
- **Literal examples in generated TASKs must satisfy the TASK's own formal rules.** The
  first real maintainer message from a consumer (decision 4.54's mechanism, validated in
  the field) reported a TASK whose scope mandated a key regex with a 2+ letter prefix
  while its dedupe criterion was illustrated with `B-2, A-1` — keys that regex can never
  match. The falsifiability paragraph of `/keelson:tasks` (step 3) now requires every
  literal example illustrating a criterion to be checked against any formal rule (regex,
  format) already mandatory elsewhere in the same TASK. The deviation mechanism had
  caught it downstream (developer noticed, reviewer confirmed, closure fixed the text) —
  this moves the catch to generation, saving that correction round. The mechanical
  variant (a `task-validator` semantic check) is reserved for recurrence.
- **Maintainer messages now open with the installed plugin version and attach a literal
  diff.** Judged against its own step-7 ruler, the received message had two gaps: no
  plugin version (the maintainer cannot tell whether current doctrine already covers the
  case) and a patch proposed in prose. The `agile-coach` scene now leads with the
  installed version, and the attachment must be the literal diff against the installed
  version's text — prose proposals force the maintainer to write the patch blind.

---

## [0.41.0] — 2026-07-30

Decision 4.62

### Added
- **The Jira board now moves in real time.** With `transition: auto`, the board only
  moved at task closure — mid-wave, cards sat in "to do" while the work was already
  running. The Etapas/Colunas map gains canonical cycle-milestone rows: `TASK iniciada`
  moves the sub-task to the in-development column the moment the Tech Lead dispatches
  the TASK to the developer (new hook in `/keelson:implement` step 3.2),
  `Trabalho iniciado (Story)` moves the Story when its **first** TASK is dispatched,
  and `TASK concluída` names the closure milestone that keeps moving sub-tasks to the
  final done column. A missing row degrades that milestone to a comment, as before.
- **No-regression guard on every automatic transition.** Before transitioning, the sync
  reads the issue's current status and compares it against the level's ruler — the
  board rail when declared (0.39.0), else the Etapas/Colunas row order: a card already
  at or beyond the target is a silent no-op — a card the human moved ahead is never
  pulled back — and a status outside the ruler is never transitioned (the milestone is
  commented instead). The multi-hop walker already embedded this on the long path; it
  now guards the direct hop too. This is what makes real-time board movement safe
  against racing a human on the board.

### Changed
- **The QA unit now has an automatic-transition ceiling: the development column.** The
  Story (or standalone task) is auto-moved at most to the `Trabalho iniciado (Story)`
  target and **stays there after the cycle delivers** — the "ready for QA" milestone
  becomes a comment on the Story instead of a transition, because the human still
  reviews the delivery and requests adjustments; advancing the card is their act, by
  the same rule that keeps the Epic untouched. The ceiling binds only automatic hooks:
  a phase verb (0.39.0) is the human's explicit order and crosses it —
  `--phase finish-dev` is exactly the act the ceiling waits for. Projects that relied
  on the Story transitioning on "ready for QA" now get a comment; mapping that trigger
  to the ceiling column itself restores a moving card. Reconciliation aligns sub-tasks
  to the real TASK state (In Progress → started, Done → done) and the Story up to the
  ceiling, under the same guard.
- `/keelson:init` seeds the four canonical milestone rows in the map skeleton (Story
  rows commented out when `issueType.feature` is null) and reminds that the row order
  is the fallback progression ruler when a level has no board rail; the merge rule adds
  any missing milestone row as a commented suggestion.

---

## [0.40.0] — 2026-07-29

Decision 4.61

### Added
- **`jira.epicPolicy` — Epics only where they group something.** Every SPEC used to
  project an Epic, even a small single-feature demand — a grouping card with exactly one
  child, polluting the roadmap (observed in a real dry-run: 1 FEAT-less SPEC, 2 tasks →
  Epic + implicit Story + 2 sub-tasks). With `epicPolicy: "multi-feature"`, the declared
  feature count in the SPEC decides the projection: **2+ FEATs** → full Epic ▸ Stories ▸
  sub-tasks (there is something to group); **0 or 1 FEAT** (the same case — a single
  feature) → **compact projection**: the single Story (implicit-Story mirror, or the one
  declared FEAT's Story) is the parentless root, sub-tasks nest under it — the same
  level-0 ▸ subtask shape standalone tasks already use. The signal is a product statement
  written in the SPEC and mechanically countable — never the AI inferring "this looks
  small". A task-count threshold was considered and rejected: task count is an engineering
  signal that fluctuates; feature count is a stable product one.
- **The persisted keys are the record of the chosen projection.** `**Jira**:` present =
  full projection; a Story key without `**Jira**:` = compact — no new field, and
  reconciliation respects the recorded projection instead of recomputing it. A compact
  SPEC that later gains a second FEAT is never re-parented: the new Story is created as a
  parentless sibling with a "relates to" link, and the mixed state is reported —
  creating an Epic and reorganizing is the Director's act in Jira. `issueType.feature:
  null` makes the compact root impossible → degrades to today's projection with a
  warning. Phase verbs adapt: the `epic` row is a silent no-op on a compact tree.
- `/keelson:init` now asks the `epicPolicy` question (closed options, default
  `"always"`), and the merge rule adds `"always"` to older fichas without the key —
  consumers that touch nothing see zero change.

---

## [0.39.0] — 2026-07-29

Decision 4.60

### Added
- **Phase verbs on `/keelson:jira-sync` — the human's imperative act on the board.**
  Creating issues was covered; moving them through the board was not — the sync only
  aligned Jira to the *artifact* state at automatic cycle milestones. Now
  `/keelson:jira-sync <target> --phase start-dev|finish-dev` first runs the normal
  idempotent reconciliation (the tree is guaranteed to exist), then walks the tree:
  `start-dev` moves Epic → Story → sub-tasks into the development columns (top-down),
  `finish-dev` completes the sub-tasks and moves the Story to the review column
  (bottom-up) — the board never shows a completed child under an unstarted parent.
- **Per-level targets in the project map.** The Etapas/Colunas table gains a `Nível`
  column (`epic` | `story` | `subtask`): a real board runs a different workflow per
  issue type (measured in the field: a 17-status Story rail over a 3-status sub-task
  rail), so one target per stage cannot project. A level with no row simply doesn't
  move — declared opt-out, not an error. Legacy maps keep working.
- **Board rail + multi-hop walker.** A new "Trilho do board" map section declares the
  ordered status rail per level. When no direct transition to the target exists, the
  sync walks the rail one status at a time, re-validating available transitions at
  every hop (`isAvailable`/`hasScreen`/`isConditional`), never regressing; a blocked
  hop stops where it is, comments, and reports the position reached. No rail section →
  direct-hop only, as before. `/keelson:init` measures and seeds the rails per level.

### Changed
- **Explicit verb beats `comment`.** The `transition` policy keeps governing the
  cycle's *automatic* hooks; a phase verb is the human's explicit order and moves cards
  under `comment` or `auto`. `off` stays a hard project policy: the verb warns and does
  nothing.
- **The Epic can now move — under double opt-in.** "Epic untouched — the roadmap
  belongs to the human" still binds every automatic hook, including reconciliation;
  the only path that moves an Epic is a phase verb (which *is* the human's act) plus a
  declared `epic` row in the map. `init` seeds that row commented out.

---

## [0.38.0] — 2026-07-29

Decision 4.59

### Added
- **Human-readable Jira descriptions — a single rendering recipe (§6.2 of the sync
  protocol).** Cards created by the Jira sync were arriving too thin for the humans who
  work from them — the feature is tested by a human QA analyst from the card, and the
  protocol only ever specified "summary/outcome" for the Epic, raw Given-When-Then ACs
  for the Story, and title-only sub-tasks. Now every issue type gets a leveled template,
  in Portuguese, plain markdown: the Epic carries context/objective, scope and the
  feature list; the **QA unit** (feature Story, implicit Story, standalone task) gets
  the richest card — business narrative in the SPEC's glossary terms, a "how to test"
  script with each AC translated into imperative numbered steps, the formal AC list for
  traceability, and out-of-scope notes; sub-tasks state their goal plus the ACs they
  cover. The description *projects* the SDD artifact — it never adds a claim the
  artifact doesn't support (the 4.58 rule). Honest-script rules, added after a field
  exercise rendering a real consumer SPEC: ACs with no reasonable manual path
  (atomicity, forged requests, ownership) are grouped under an "automated checks" line
  instead of becoming theater steps, and the feature's NFR criteria (dark mode,
  viewport, screen reader) join the story's test script rather than being orphaned —
  including verifiable NFRs that have no covering AC at all (idempotency,
  reversibility, auto-refresh), which the AC-based formula would silently drop. A
  second field exercise also hardened key persistence: the SPEC header carrying the
  same key on both `**Jira**:` and `**Jira Story**:` lines (found in the wild) is now
  treated as inconsistent persistence — the implicit Story is considered missing,
  probed for duplicates and recreated with a warning, never accepted as valid state.
- **Do-not-edit notice, marker footer and re-render policy.** Every generated
  description opens with a notice telling humans not to edit the text and to register a
  comment instead (sync never touches comments), and ends with
  `— gerado pelo keelson a partir de <repo-relative artifact path>` (spec numbers repeat
  across slugs; only the path disambiguates — FEATs anchor `#FEAT-NNN-XXX`). During
  reconciliation, a description that is empty or ends with the marker is re-rendered
  with the current template; a description without the marker was edited by a human and
  is never overwritten (preserved and counted in the warnings). `/keelson:jira-sync`
  gains the corresponding reconciliation step, a "Descrições" line in its output, and a
  `--refresh-descriptions` flag that force-re-renders pre-marker cards (the old thin
  descriptions) on explicit human request — cycle hooks never force.

---

## [0.37.0] — 2026-07-28

Decision 4.58

### Changed
- **`/keelson:tasks` now writes only what it verified — "verified, not deduced".**
  Consolidation of a four-finding cluster (three PLANs, same command) reported by the
  first automated maintainer message (4.54 mechanism). Two new rules under one named
  principle: (a) a file path cited in a TASK's "Escopo > Inclui" must be confirmed
  through the data chain (*who consumes the query/endpoint this change touches?*),
  never deduced from a similar-looking name — when unconfirmed, the TASK describes
  the consumer instead of guessing the path; (b) **reverse coverage**: every "Inclui"
  item carries at least one own, executable done-criterion — "tests for all of the
  above" doesn't count, and for items without an AC (contracts created in this wave
  to be read in a later one) the oracle is the item's own contract, exercised with
  non-null values.
- **`task-validator` enforces reverse coverage.** New ERROR in the scope checks: an
  "Inclui" item that no done-criterion references fails validation (generic criteria
  don't count as a reference; legacy `Done` TASKs are exempt). This honors the ladder
  pre-committed in 4.52: recurrence in the same area becomes a mechanical check, not
  a second prose rule.

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
