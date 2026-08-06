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

## [0.85.0] — 2026-08-06

Decisions 4.151–4.153 — deterministic work that the model used to re-derive in prose
on every cycle now runs as scripts with contracts and frozen regression suites; the
doctrine cites their output as fact and never duplicates the rule.

### Added
- **Six new scripts** (each with its own test suite, wired into pre-commit and CI):
  `ficha.sh` (single reader for `keelson.config.json` — dotted `--get`, legacy
  boolean `screenVerify` normalization, `plugin:` profile-path resolution; named
  degradation on exit 3), `next-id.sh` (the 4.86 single allocator plus per-plan task
  numbering and brief↔SPEC pairing check), `index-check.sh` (slug `INDEX.md` checker —
  tables vs files, `X/Y` tasks cell, status verbatim, capacity moved too early,
  history cap; WARNING/INFO only), `diff-facts.sh` (the executable anchor of the
  TESTING.md "inert diff" rule, plus report diff composition and the deploy-pendency
  check that previously shipped as a bash template with placeholders), `run-state.sh`
  (canonical writer for the wave-guard sentinel) and `ledger.sh` (session-ledger
  mechanics: sortable names, measured timestamps, closed type catalog, archive that
  preserves pending events).
- **`artifact-lint.sh` + `lint-contract.md`** (4.152): the mechanical subset of the
  three validators (header/enum checks, required sections, ID format, EARS/RFC 2119
  patterns, threshold counts, technology wordlist) is now computed and cited as fact.
  Severity comes in two classes — unambiguous facts keep the validator's severity,
  pattern-based checks are born WARNING and only the validator escalates; `Done`
  artifacts downgrade ERROR to `WARNING [legacy]`.
- **Two new graph checks** (4.153): `fr-sem-ac` (an FR no AC covers, inside the SPEC
  itself; ERROR with legacy relief, also in `--stage=plan`) and `plan-status-vs-tasks`
  (a PLAN marked Done while its tasks are still open; WARNING). `done-sem-closure`
  was deliberately **not** added — legacy Done-without-closure archives are modeled
  as clean, so that direction stays with the task-validator, which sees context.

### Changed
- The three validator skills were rewritten around "mechanical facts first": they run
  `artifact-lint.sh` (and `graph.sh`) and keep only judgment checks
  (spec-validator shrank from 176 to 82 lines).
- Commands now invoke the scripts instead of carrying the prose: ID allocation in
  `specify`/`plan`/`tasks`/`brief`, diff composition and ledger/run-state lifecycle in
  `auto`/`implement`/`report`, INDEX verification in `implement`/`rebuild-index` and
  the `status` skill, deploy-pendency in `implement`.
- `TESTING.md` ("inert diff"), `sdd-conventions.md` (ficha, run-state, ledger) and
  `index-contract.md` (allocator, INDEX checks) now name the canonical executors.

---

## [0.84.0] — 2026-08-06

Decision 4.150 — the Jira map file is configuration, never a ledger. Motivated by a
real consumer whose map had accumulated one issue-tree section per synced SPEC —
redundant with the SDD artifacts and Jira itself, and growing without bound.

### Added
- **Explicit config-only rule for the map** (§3 of the sync protocol): no sync hook
  appends execution records (created issue trees, per-SPEC sections, board state) to
  `jira.<PROJECT>.md`. Key persistence stays where §10 puts it — `**Jira**:` lines in
  the SDD artifacts plus one line in the slug INDEX — and live status lives in Jira.
  Legitimate writes remain config maintenance only (re-measured transition ids, rail,
  workflow notes — by `/keelson:init` or the human). A contaminated section is never
  updated or completed by the sync, even when its own text asks for it; falsifiable
  test: *map content that the next sync run would make stale is an execution record,
  not config*.
- **Ledger diagnostic in `/keelson:init`**: a map section outside the three-section
  contract that records execution now raises the warning
  `mapa com registro de execução — config, não ledger`, recommending pruning. The init
  never prunes by itself — the file belongs to the human.
- Troubleshooting entry on the wiki for the recognizable symptom (map file growing
  with issue listings).

---

## [0.83.0] — 2026-08-06

Decisions 4.146–4.149 — facts survive outside the model's context: re-anchoring
after compaction, a measured context window, mechanically proved synchronization,
and a countable promotion ladder for recurring lessons. Distilled from a benchmark
of affaan-m/ECC (2026-08-06).

### Added
- **Post-compaction re-anchor hook** (decision 4.146, `hooks/compact-anchor.sh`,
  SessionStart/`compact`). The instant the context window is compacted, the hook
  reads the on-disk state — active `run-state` files and the session-ledger event
  count — and re-injects it as context, instructing the session to re-derive wave
  state from the `retomada:` artifacts instead of trusting the compressed summary.
  Mirror only: it never decides or blocks, and stays silent when there is nothing
  in flight.
- **Context-window telemetry hook** (decision 4.148, `hooks/window-marker.sh`,
  Stop). On every Stop it appends `<ts> janela=<tokens>` (input + cache of the last
  assistant message) to `thoughts/local/session-window.log` — keelson projects
  only, constant cost, never blocks. The closing report's duration line gains an
  optional `janela pico ~<N>k tokens` tail: measured from the log or omitted,
  never estimated (`report-contract.md` owns the rule); the delivery moves the log
  into `reported-*/` alongside the ledger.
- **Command/agent synchronization is now a mechanical fact** (decision 4.147,
  `scripts/check-sync.sh` + `scripts/tests/sync/`). The "3 places" rule is proved
  in both directions on pre-commit and CI: command ⇔ README table row, `†` marker ⇔
  `disable-model-invocation`, human-only commands present in the consumer block
  note, agent ⇔ `name:`/heading/§5 table. A command missing its method-guide
  section degrades to a declared WARNING (two known gaps: `init`,
  `verify-handoff`), never an invented error.
- **Promotion ladder for recurring lessons** (decision 4.149,
  `docs/_meta/learning-log.md` — owner). The existing `reincidencia:` counter
  becomes the trigger: first recurrence still reformulates the rule; from the
  second on, the proposal must include a designed mechanical check or autocheck —
  or declare why the class cannot be mechanized, making "text again" an explicit
  Director decision. The maintainer queue returns second-recurrence proposals that
  carry neither.

### Changed
- `CLAUDE.md` sync rules now point at their mechanical proof (`check-sync.sh`);
  the pre-commit quality guard and the CI workflow run the new check and suite.

## [0.82.0] — 2026-08-06

Decisions 4.142–4.145 — the cycle closes both ways: a delivery convergence pass,
a budget for pending uncertainty, and escalation questions readable on their own.
Distilled from a benchmark of github/spec-kit (2026-08-06).

### Added
- **Gate 4 now asks the inverse question** (decision 4.142,
  `guidelines/core/CODE-REVIEW.md`). Every new or changed behavior in the diff
  must have a declared parent — an AC/criterion that requires it, a direct
  technical need of one, or a declared scout within the Charter Art. 6
  conditions. Behavior with no parent is an `unrequested` finding, routed as
  out-of-scope signal to the Tech Lead; it either becomes a recorded assumption
  or leaves the diff — silent permanence is the failure. AC-driven review proves
  the requested exists; this check proves the unrequested doesn't.
- **Delivery convergence pass: the whole SPEC against the final code**
  (decision 4.143, `guidelines/core/CODE-REVIEW.md` owns the rule;
  `agents/code-reviewer.md` gains a convergence mode; wired into
  `/keelson:auto` delivery and `/keelson:integrate`). The cycle proves by parts
  (tests per task, review per wave, behavior per feature); this pass proves the
  whole: each gap is typed `missing` / `partial` / `contradicts` / `unrequested`
  with the FR/AC/DEC it cites, anchored on `graph.sh` structural facts. Gaps are
  fixed before push or parked as explicit questions — never pushed silently. A
  green pass is recorded in the INDEX with the SHA and reused by
  `/keelson:integrate` while the diff since then is inert (same pattern as
  mutation testing, 4.122). The delivery report gains a convergence line
  (`docs/_meta/conventions/report-contract.md`).
- **Pending `[confirmar]` markers get a budget: at most 3 per SPEC**
  (decision 4.144, `commands/specify.md`; new WARNING in
  `skills/spec-validator/SKILL.md`, Draft/Review only). Candidates beyond the
  cap are ranked scope > security/privacy > UX > technical detail; the cut ones
  become `[assumido]` assumptions with the chosen default declared in place. A
  real pending item changes the outcome; a preference with a reasonable industry
  default doesn't spend the budget.
- **Escalation questions must be answerable from their own block**
  (decision 4.145, `agents/po.md` — the escalation contract owner). The test:
  the Director decides reading only the escalation block — a real question in
  the Director's language ending in `?` (a label or requirement ID is not a
  question), one "why it matters" line about the product consequence, one
  decision per question, and accepting the default costs one word.

---

## [0.81.1] — 2026-08-06

Decision 4.141 — fixes the 4.42 anti-renudge valve under parallel dispatch.

### Fixed
- **`agent-guard` anti-renudge valve now works for parallel spawns**
  (decision 4.141, `hooks/agent-guard.sh`). The blocked-call marker was a
  single-slot file holding only the last fingerprint, so two legitimate generic
  spawns blocked in the same turn overwrote each other and neither retry passed —
  the promise "repeat the call and this warning won't repeat" only held for a
  solitary call. The marker is now an append-only window of recent fingerprints
  (checked in full before denying, truncated off the hot path), so interleaved and
  parallel blocks no longer cancel each other's retry. Bash 3.2 and graceful
  fallback preserved; the legacy single-slot marker is cleaned up on first write.

---

## [0.81.0] — 2026-08-06

Decisions 4.138–4.140

### Changed
- **TASK generation cross-checks `lessons.md` and addresses inherited criteria**
  (decision 4.138, `commands/tasks.md`). `guidelines/project/lessons.md` becomes an
  input of the scribe, and a lesson that names a task's target files (or the pattern
  they embody) turns into a verifiable Done criterion — never recommended reading. An
  inherited spelled-out criterion (a requirement/NFR/lesson quoted in full) gets an
  address: it names the file+action that fulfil it and that file joins the task's
  Escopo > Inclui — otherwise the criterion becomes its own TASK in the same wave.
- **Scope-predicate mutation criteria close by count, never by list** (decision
  4.139). Item (c) of decision 4.107 reformulated: every method whose WHERE carries
  the scope needs a second-instance scenario whose mutation fails the test — N
  methods in scope, N proofs, plus one case per predicate branch on reads; a named
  method is a non-exhaustive illustration, never the full list.
- **Gate findings travel to the next dispatch as criteria** (decision 4.140,
  `commands/implement.md`). A pending item inherited from a previous gate finding is
  edited into the receiving TASK's Done criteria before dispatch — never prose in the
  Contexto field — with the same yardstick as the originating finding; and the
  per-FEAT gate-9 package now carries the wave's gate 7/8 findings, reconciling the
  pre-code verification script against them before the `qa` dispatch (steps
  invalidated by later corrections are rewritten; steps missing the external proof a
  correction required gain the missing count command).
- **Both command files distilled back under the 300-line ceiling** (per decision
  4.135): `commands/tasks.md` 300→298 and `commands/implement.md` 326→295 with all
  five patches inside. Sibling rules were fused, `implement.md` dropped the Input
  section that duplicated the frontmatter (`--guidelines` moved to the argument-hint)
  and now points at `core/CODE-REVIEW.md` for the gates 1–7 yardstick instead of
  replicating the list. No rule was dropped. No re-init needed — consumers only
  update the plugin.

---

## [0.80.0] — 2026-08-06

Decisions 4.136–4.137

### Changed
- **Escalations and DECs now carry the concrete cost of the branch not taken**
  (decision 4.136). The escalation contract (`agents/po.md`, inherited by every role
  that escalates) adds a third mandatory element to proposal + default: one clause
  stating what is lost or broken if the Director refuses the proposal — that fact goes
  *in* the escalation, never after it as justification. A balanced either/or with no
  recommendation is the same defect as an escalation with no default: a withheld
  opinion. When a recommendation genuinely cannot be formed, the escalation says so and
  names what would settle it. On the PLAN side, a DEC discards an alternative by naming
  its concrete cost, never by adjective ("more complex"); the DEC template shows the
  expected shape and the `plan-validator` warns on adjective-only discards (Draft/Review
  PLANs only — the existing back-catalog is exempt, same grace as the `Reopen if` rule).
- **Triage routes by the cost of being plausibly wrong, never by diff size**
  (decision 4.137, `commands/triage.md`). A one-line change to what the system promises
  — an id shape, a payload key, an API default — goes through the full cycle no matter
  how small it looks, because every consumer breaks with it; a large but mechanical
  change whose diff is self-evidently right or wrong is not promoted for volume.
  Looking trivial does not survive blast radius: when in doubt about who consumes what
  changed, promote.

---

## [0.79.0] — 2026-08-06

Decisions 4.130–4.135

### Added
- **The close-of-session report now has a literal canonical skeleton with a single owner**
  (`docs/_meta/conventions/report-contract.md`, decision 4.130), emitted by the
  `/keelson:auto` delivery, the on-demand mode close and `/keelson:report`. A mandatory
  line is a blank to fill (missing input → the gap is named on the line, never the line
  omitted); a conditional section either exists with its ready-to-forward copy-paste
  block or doesn't exist — prose summaries no longer substitute for either. Born from a
  real consumer delivery that shipped without the duration line, diff composition,
  tracker line and maintainer-message blocks. Mirrored to the wiki as
  `Contrato-do-relatorio`.
- **New graph check `status-vs-closure`** (decision 4.131): a TASK whose closure is
  filled (`Data conclusão`/`Commit SHA`) while the header `Status:` is not `Done` is
  flagged as WARNING — the field every reader trusts, left stale for 7 waves in the
  field case, now has a mechanical watcher. New fixture + suite case (28/28 green).
- **`permissao_ambiente` joins the closed enum of handoff causes** (decision 4.133):
  a platform/permission classifier denying an action is a named cause with its own
  probe row — and a ceiling: the second identical denial proves the cause; retrying
  is anti-pattern (real case: six attempts against the same block).

### Changed
- **Gate 3 without `quality.lint` degrades declaredly** (decision 4.132): the reviewer
  reports `lint: not configured` and falls back to profile-guided reading — never an
  improvised per-reviewer ruler, never silence.
- **Gates that mutate files run in an isolated worktree** (decision 4.134, consumer
  proposal LRN-045): the working tree is an exclusive resource between concurrent
  mutating gates; restoring afterwards is not enough.
- **Developer self-check before reporting a retry** (decision 4.135, consumer proposal
  LRN-046): comments introduced in the retry that narrate the round/finding fail the
  delete-test by definition and are removed before Done — a rule that already existed
  verbatim now has a mechanical checkpoint instead of a second wording.
- Five further consumer proposals (LRN-043/044, recurrences of LRN-015/LRN-034,
  LRN-047) are registered in the proposal inbox with a favorable verdict, **held**:
  applying them requires compensatory distillation of `tasks.md` (at the 300-line
  ceiling) and `implement.md` (above it) — its own release batch.

---

## [0.78.1] — 2026-08-06

Decision 4.129

### Fixed
- **Invoking a keelson command now counts, explicitly, as the user asking for the
  team (4.129).** Some harness surfaces inject a system policy like "don't use the
  Agent tool unless the user asks", and consumer sessions receiving `/keelson:auto`
  were escalating to ask permission to use the team's subagents — the 4.85 escalation
  working as designed, but on a conflict that isn't genuine. The consumer block now
  states that invoking a `/keelson:*` command **is** the explicit request for the
  subagents of that command's contract, so the policy is satisfied by the invocation
  itself and the question disappears. 4.85 stays intact for genuine conflicts.
  **Re-run `/keelson:init` in consumer projects** to refresh the injected block.

---

## [0.78.0] — 2026-08-05

Decisions 4.125–4.128 — the epic becomes operable without human memory. Motivated by a
direct field report: a team being onboarded kept getting lost right after
`/keelson:specify-epic`, because resuming an epic required remembering which slice was
next and how to compose the `/keelson:auto` command.

### Added
- **`/keelson:continue <slug>` — the single resume door (4.127, human-only).** Derives
  the state from **committed** artifacts only (epic queue, TASK closures, brief
  statuses — never `thoughts/local/`, which is per-clone), shows a "you are here" map
  and proposes exactly one next step with a default: resume an interrupted wave,
  dispatch the next slice, resume a forge waiting on product answers, or point at
  `/keelson:integrate` when the queue is done. Nothing runs without confirmation —
  pointing at the slug is the human act; it just no longer requires memory.
- **Living queue in the epic BRIEF (4.125).** Each slice row carries state
  (`pendente` · `em ciclo` · `aguardando-produto` · `entregue`), written by the child
  cycle's milestones (kickoff marks `em ciclo`, delivery marks `entregue`); the epic
  itself moves `Emitido → em execução → concluído`. The queue is a curated record,
  never a second source of truth — divergence resolves by the child artifacts.
- **Epics wiki page (`Fluxo-de-epicos`)** — an operator's guide from product document
  to PR, written so a developer can run the whole flow without a tutor; linked from
  the sidebar and the FAQ.

### Changed
- **One branch per epic, synced at slice boundaries (4.126, refines 4.119).** The
  branch strategy is confirmed with the decomposition and recorded in the epic BRIEF
  (`**Branch**:` + `**Estratégia**:`, default `unica`): slices stack on the epic's
  branch, each building on the previous one. Every slice boundary syncs with main —
  merge, never rebase — on **both** sides: at slice close the full suite runs
  **post-merge** and red is a failed gate (no push with a broken sync); at the next
  slice's kickoff a cheap re-check runs with the human present. 4.119's ban now
  targets *undeclared* branch reuse; deliberate, recorded sharing is the epic default.
  Final PR and merge remain human.
- **Forged BRIEF is a first-class input to `/keelson:specify-epic` (4.128).** The PM
  receives the whole BRIEF: code facts inform the slicing and seed the MAP, sealed
  assumptions travel to the slices that use them, and pending product questions are
  distributed — a `[bloqueia-núcleo]` Q-ID marks its slice `aguardando-produto` in the
  queue so `continue` won't propose it until answers arrive. The forge also gained the
  matching exit: an epic revealed mid-interview hands off to `specify-epic` instead of
  `auto`, closing the routing gap that only existed at the door.

Re-run `/keelson:init` in consumer projects to refresh the human-only command note in
the injected block.

---

## [0.77.0] — 2026-08-05

Decision 4.124

### Changed
- **SDD artifacts cited outside their slug now travel with their relative path,
  never the bare ID (4.124).** Artifact numbering is per slug, so the same `PLAN-002`
  exists in as many slugs as the repo has — a field report caught a session-closing
  resume command (`/keelson:implement PLAN-002`) that matched **9 files** when pasted
  into a fresh session. Doctrine now lives in `sdd-conventions.md`: anything that
  leaves the slug — next-command lines, resume commands, reports, bulletins,
  escalations — cites the real file path (`docs/<slug>/plans/PLAN-MMM-<name>.md`);
  the short ID stays canonical inside the slug's own artifacts. The next-command
  templates in `specify`, `plan`, `tasks`, `implement` and `triage` were teaching the
  bare-ID habit and now print the path. On the input side, a bare ID matching files
  in more than one slug makes the command stop and list the candidates with paths
  instead of picking one. No re-init needed — the consumer block is unchanged.

---

## [0.76.0] — 2026-08-05

Decision 4.123

### Added
- **Guided setup for the mutation gate: `/keelson:mutation-setup` (4.123).** 4.121/4.122
  assume a consumer who knows how to assemble the mutation command — tool, config, diff
  scope, threshold. Direct report from the field, same day: *"I don't know how to
  configure mutation"*. An opt-in field nobody knows how to fill is a dead gate. The new
  human-only command detects the stack from the ficha, proposes the canonical tool
  (Infection · Stryker · mutmut · PIT · cargo-mutants) and installs it with explicit
  confirmation (a project dependency never lands silently), generates the tool config
  from what the ficha already knows (`codePaths`, `quality.test`), composes the command
  diff-scoped and **without a threshold** (first adoption is informative — a minimum
  score is measured over 1–2 real deliveries, by the human, never guessed at setup),
  proves the whole pipeline with a one-file sample run before writing anything (a
  phantom command is worse than an empty field), and writes `quality.mutation`
  merge-preserving. Committing the setup remains the human's act. `/keelson:init` now
  points at the command when it detects no tool, instead of silently leaving `null`.
  Consumer block note updated — **re-run `/keelson:init` in consumer projects**.

---

## [0.75.1] — 2026-08-05

Decision 4.122 — same-day amendment of 4.121.

### Changed
- **The mutation gate now fires in the default flow (4.122).** 4.121 hung mutation
  testing only on `/keelson:integrate` — but the default flow (`/keelson:auto`)
  delivers with a push and no PR, so a consumer who never runs integrate had the gate
  installed and never fired. The auto close now runs `quality.mutation` too (delivery
  pre-check, before PO acceptance; same rules — exit-code verdict, declared absence,
  inert diff waives). A green run is recorded in the slug's INDEX with the SHA it ran
  on, and integrate skips the repeat with a declared waiver only when the diff from
  that SHA to HEAD is inert (the same mechanical anchor as the inert-diff rule) — a
  mark without a SHA, or any code change since, means it runs again: verified, not
  deduced (4.58).

---

## [0.75.0] — 2026-08-05

Decision 4.121

### Added
- **Mutation testing proves the suite at delivery (4.121).** Until now, the only
  defense against tautological tests was the "assertions that prove" rule, enforced by
  *review* in gate 1 — an evaluator reading the test. A green suite of weak assertions
  passed every gate. Mutation testing closes that: mutate production code and prove the
  suite fails — the Charter's "generator ≠ evaluator" rule applied to the suite itself.
  New opt-in `quality.mutation` field in the project sheet (default `null`): the value
  is the consumer's literal command — scope (e.g. diff-only) and threshold (e.g. minimum
  score) are the consumer's calibration inside that command; the engine stays agnostic
  and reads only the exit code, like `quality.test`. Runs exclusively in
  `/keelson:integrate` after the full suite goes green (never per TASK/wave — mutation
  is expensive; gate 2 is already the fine net); a failure stops the delivery like a red
  test. Absence is declared (`mutation: not configured (opt-in)`), never silent; an
  inert diff waives it together with the suite. No doctrine-level score target exists
  (anti-Goodhart): surviving mutants are reported as a signal for reviewers — assertion
  quality remains gate 1's ruler. `/keelson:init` detects common tools (Infection,
  Stryker, mutmut, PIT, cargo-mutants) in the project manifests and offers the field;
  existing language profiles are untouched. Owner of the ruler:
  `guidelines/core/TESTING.md`, "Mutação: a suíte também está sob prova".

---

## [0.74.1] — 2026-08-05

Decision 4.120 — corollary of 4.119, observed live in the same measured session.

### Fixed
- **SDD artifacts never enter a developer commit (4.120).** Wave developers swept their
  own TASK `.md` (untracked, because the forge had never committed) into three real
  `feat` commits — a defensible reading of the staging rule, which only barred untracked
  files "from another scope". The improvised salvage is worse than the symptom: it
  commits the pre-closure version of the artifact (the closure SHA still doesn't contain
  the closure), mixes authorship into the diff composition the PO accepts, and saves 3
  of 20 files. The developer contract now draws the boundary explicitly: a developer
  commit contains only the code and tests the developer authored — `{docsRoot}/**` never
  enters, in any state, not even the task's own `.md`; an untracked TASK file is a
  symptom of an uncommitted milestone (4.119), to be reported, never swept.

---

## [0.74.0] — 2026-08-04

Decision 4.119

### Changed
- **SDD artifacts are committed at the milestone that closes them (4.119).** A real
  cycle reached implementation with the entire forge output outside git — BRIEF, SPEC,
  PLAN, 20 TASKs untracked, closures and INDEX dirty — while code commits flowed
  normally: no forge command committed, the paperwork commit only happened at delivery
  ("sweep at the end"), and the closure commit was conditional on parallel mode. Now the
  work branch is born at kickoff (one per demand — same epic never reuses another
  demand's branch, which was mixing leftovers between deliveries), each cycle stage
  closes with a `docs(<slug>): …` commit (SPEC with BRIEF, PLAN, TASKs after the
  consolidated round; in guided, after the checkpoint OK), and the TASK closure commit
  (`chore(<slug>): close TASK-MMM-XXX`) runs in every orchestration mode — so the SHA
  cited in a closure finally contains the closure itself. Standalone commands outside
  the cycle still never commit (the trail belongs to the human). Delivery keeps
  acceptance and push, but stops being the only save point — maximum loss is one
  milestone. Owner: `sdd-conventions.md`, "Commit por marco".

---

## [0.73.1] — 2026-08-04

Decisions 4.117–4.118 — field corollaries of the forge batch, both observed live in the
same measured session.

### Fixed
- **Correction rewrites preserve every edge the fix does not target (4.117).** The first
  real consolidated correction package (16 adjustments) rewrote a TASK in full — as
  4.112 mandates — and dropped the coverage of an AC no adjustment touched; the delta
  revalidation caught it, but prevention is cheaper than the extra lap. The scribe now
  checks, before writing, that the original file's edge fields and criterion-cited ACs
  survive the rewrite.
- **Waiting on a subagent is never polling (4.118).** Third sleep-loop occurrence in one
  session (two graph polls during TASK correction, then a 2.1-min poll on a wave
  developer's commit during implementation). General rule in the shared conventions:
  subagent results arrive by awaited return or by harness notification — the main
  session never probes filesystem/graph/commits in a loop; `graph-contract.md` §4.1
  becomes a declared instance of the rule.

---

## [0.73.0] — 2026-08-04

Decision 4.116

### Changed
- **Pre-code TASK review is one consolidated round (4.116).** In the formal cycle, the
  pre-code `qa` pass joins the same parallel round as `task-validator` + `tracker-sync`
  (one turn, three dispatches — the harness runs independent dispatches concurrently);
  findings are triaged once, product questions go to the `po` in a single batch, form
  findings plus the PO's rewrites become one consolidated correction package to the
  scribe (full rewrite per 4.112, awaited per 4.114), followed by one delta-scoped
  revalidation. Leftover ERRORs escalate — never a silent second lap. Live telemetry
  from the same measured session (already on 0.71.0 doctrine): validator → fix → QA →
  PO ran as three serial correction laps, ~35 min where one sufficed. Standalone
  `/keelson:tasks` is unchanged.

---

## [0.72.0] — 2026-08-04

Decisions 4.112–4.115

### Changed
- **`scribe` writes whole documents in one pass (4.112).** One `Write` per file with the
  full document composed up front; `Edit` is for post-read touch-ups, never the writing
  method. Correction packages (PO/validator adjustments) are applied by rewriting each
  affected file in a single `Write` — never one `Edit` per adjustment. Telemetry from a
  real forge session: a ~1,000-line PLAN took 28.6 min (1 write + 25 edits) and a SPEC
  absorbed a 56-adjustment package as 69 serial edits, each a full model turn.
- **Forge gates run in parallel after the scribe (4.113).** `/keelson:specify` dispatches
  `spec-validator`, `product-analyst` and `tracker-sync` in the same round once the
  scribe is done (merit critique no longer waits for — or is suppressed by — form
  errors); `/keelson:tasks` pairs `task-validator` with the tracker sync after the graph
  is clean. The `po` verdict stays sequential (it consumes form + critique). Tracker sync
  remains best-effort and never holds the critical path alone; the serialized chain cost
  ~25 wall-clock minutes in the measured session.
- **Graph-error correction gets an owned protocol (4.114).** New §4.1 in
  `graph-contract.md`: the main session runs `graph.sh` and hands the scribe the literal
  ERROR list (never "run the graph until clean" — the scribe has no shell); the
  correction delta is awaited, never backgrounded and polled; a numbering hole is not a
  defect and existing files are never renumbered (mass renumbering broke references and
  left 9 undeletable stubs in the field); file removal/renames belong to the main
  session. `commands/tasks.md` distilled back to its 300-line cap in the same batch.
- **`spec-validator` warns at epic size (4.115).** More than 30 FRs → WARNING suggesting
  `/keelson:specify-epic` while slicing is still cheap. Never an ERROR — slicing is a
  product decision; the measured session forged a 50-FR, 51-AC SPEC as a single demand.

---

## [0.71.0] — 2026-08-04

Decisions 4.105–4.111

### Added
- **`scripts/check-agents.sh` — MCP parity guard for the agent cast (4.105).** Every
  `mcp__<server>` cited in an agent's body must be granted in that agent's own `tools:`
  frontmatter (server, wildcard or specific-tool form). An explicit `tools:` list never
  inherits MCP tools, so a missing grant structurally disables the role in every
  invocation. Frozen-fixture suite in `scripts/tests/agents-mcp/` (including a case that
  runs the check on the real cast), wired into pre-commit and CI; `check-release.sh` now
  runs `bash -n` on every suite runner (`scripts/tests/*/run.sh`).
- **Consumer proposal inbox (4.111).** `docs/_meta/proposal-inbox.md` tracks every
  `PROPOSTA_PLUGIN` arriving from consumer ledgers: registered on arrival (before the
  verdict, origin abstracted per 4.72), closed by the batch that applies or declines it,
  recurrences pointing at the previous line. Born with this batch's 8 proposals
  registered and closed. Motivated by two proven recurrences caused by the missing lane —
  a correct proposal sat unapplied for 12 days, and a structural defect stayed a project
  workaround until a later session rediscovered it from scratch.

### Changed
- **`/keelson:tasks`: the edge between same-wave sibling tasks has a named owner
  (4.106).** Two tasks whose result only completes combined — same shared data consumer,
  or one creating the entry point the other exposes — declare the edge at decomposition:
  one task creates and names the symbol/entry point, the closing task carries the item
  in its own "Escopo > Inclui". Both real episodes (divergent spellings of a shared key;
  a listing shipped without the click into its sibling's detail screen) were caught
  outside every gate — only decomposition sees both tasks at once.
- **`/keelson:tasks`: done-criteria must resist gaming (4.107).** Three fixation tests:
  literals (service names, credentials, convention symbols) verified against the real
  source before being written; structural invariants anchored by symbol in a fail-closed
  guard, never by path patterns (a path-matching grep is satisfied by relocation); scope
  predicates (tenant/owner) born with a two-parent fixture and a gate-1 mutation
  criterion instead of being discovered by gate 8 after the code exists. Hierarchical
  gate-9 scripts must include a step that crosses the container boundary. The command
  file was distilled back under its 300-line cap (314 → 300, prose-only compression;
  embedded templates unchanged).
- **`/keelson:plan`: API surface and schema verified against the real source (4.108).**
  New mandatory principle 9: walk each new entity's construction invariants and confirm
  a route satisfies them before they are needed (a missing upload-first endpoint made a
  MUST unrealizable via API in a real PLAN); column types are read from the real
  schema/migrations, never assumed from domain convention.
- **Review closure covers every subject the source requirement names (4.109).** A
  finding derived from a multi-subject MUST ("for each A, B and C") is closed against
  the source FR/AC text — not just the subjects the finding happened to cite, which
  leaves the uncited subject with contract data and no consumer, unflagged.
- **Missing-proof findings count toward the retry cap (4.110).** "The reviewer already
  believes the code is right, only the proof is missing" is not an exception category:
  unproven behavior is unverified behavior, and the party mid-retry has the incentive to
  classify findings as mechanical. Genuinely mechanical closures go in the escalation
  proposal (with an apply-and-close default), never as a reason to skip escalating.

### Fixed
- **The `qa` agent can actually drive the browser it is told to drive (4.105).** The
  4.49 migration to Playwright MCP updated the `qa` body and the screen-verify skill but
  not the frontmatter `tools:` list — so every screen gate 9 degraded to a handoff seed
  regardless of environment, and redispatching was (correctly) blocked twice by the
  agent-guard. `tools:` now includes `mcp__playwright__*`. Found via a real consumer
  postmortem — the second occurrence; the first had been recorded as a project
  workaround and never escalated (see 4.111).

---

## [0.70.1] — 2026-08-04

Decision 4.103 (description-cap correction)

### Fixed
- **`scribe` and `tracker-sync` frontmatter descriptions trimmed under the 350-char
  agent cap** (desc-guard caught them at 449/484 right after 0.70.0): over the cap the
  always-loaded plugin budget inflates on every consumer session. Trigger terms and the
  invoker list stay first; the full detail lives in each agent's body.

---

## [0.70.0] — 2026-08-04

Decisions 4.103, 4.104

### Added
- **`scribe` agent — SDD authorship in its own window (4.103).** The writing of
  SPEC/PLAN/TASKs no longer happens in the main session: `/keelson:specify`, `plan`
  and `tasks` dispatch the new out-of-cast tool agent with the input paths and the
  command's own form stages as the contract; it returns a structured summary (INDEX
  inputs, assumptions, doubts) instead of the full content. Measured driver: ~55% of a
  real cycle's window growth came from inline authorship. Validation, product critique,
  PO approval and Status promotion stay with the main session.
- **`tracker-sync` agent — Jira hooks leave the main window (4.103).** All protocol
  hooks (specify, tasks, wave dispatch, closure, delivery reconciliation — and
  mid-session `/keelson:jira-sync`) dispatch a tool agent that reads the protocol
  sections, absorbs the connector payloads, writes only the designated key lines and
  returns the canonical tracker summary plus degradation events for the ledger.
- **Slug MAP — living code-territory mirror (4.104).** Optional `docs/<slug>/MAP.md`
  with dated, anchored entries (`- [date · origin] fact — file:line @ "hint"`): seeded
  by `/keelson:specify-epic` from the decomposition exploration, delta-appended at every
  closure in the slug (the exploration memo drains into it before removal), consumed as
  first exploration input under the "verified, not deduced" rule. Single-owner contract
  in `docs/_meta/conventions/map-contract.md`; INDEX template gains an optional pointer
  line; the consumer block gains the read trigger (**re-run `/keelson:init`**).
- **`scripts/map-check.sh` + frozen-fixture suite (4.104).** Sibling engine to
  `graph.sh` (bash 3.2 + POSIX awk + git, read-only): `map-forma`, `map-ancora`,
  `map-frescor` (anchored file committed after the entry date → `possivelmente-stale`)
  as WARNING and `map-teto` as INFO — never ERROR. Suite builds deterministic git repos
  per fixture; wired into pre-commit and CI.

### Changed
- **Two-layer subagent reports (4.103).** An agent's return is now only its contract
  YAML (text fields 1–3 lines); narrative belongs to the durable artifact (TASK
  closure, ledger, INDEX, commit). Findings stay complete on the actionable
  (file:line + reason + action), lean everywhere else. Owner: `sdd-conventions.md`.
- **Review/security stop-guards go silent during a formal cycle (4.103).** With
  `run-state` at `em_andamento` the wave orchestration already owns the gates; the Stop
  hooks are the free-session safety net (measured: 33 renudges in one real cycle).
- **Rereading is a declared exception (4.103, reinforcing 4.35).** Files already in the
  window are re-read by section only; profile load is always sectioned.

---

## [0.69.1] — 2026-08-04

Decision 4.102 (folder-name correction)

### Changed
- **Suggested product-document folder renamed `origem/` → `origin/`.** The sibling
  folders in the slug tree are all English (`specs/`, `plans/`, `tasks/`, `briefs/`,
  `handoffs/`, `legacy/`) — the house convention is English folders, Portuguese fields —
  and the original name broke that pattern. Cosmetic by construction: the folder is a
  suggestion, nothing mechanical globs it, and no consumer had adopted it yet (renamed
  minutes after 0.69.0).

---

## [0.69.0] — 2026-08-04

Decision 4.102

### Added
- **The BRIEF forge — `/keelson:brief` (4.102).** A human-only, optional pre-cycle
  stage: the product area's document (PRD, demand doc, e-mail — path or pasted) is
  inventoried against the sections the SPEC will demand (problem · outcome · metric
  **with measurement source** · personas/anti-persona · scope IN/OUT · premises **with
  evidence seals** · ACs · risks), never classified by "document type". Each gap is
  answered at the cheapest source: the **code first** (code-scout → exploration memo the
  specify already consumes), then the human **one question at a time**, and what only
  the product area can answer becomes a **formal Q-ID pending** — never a blocker.
  Three exits always: BRIEF `pronto` (+ copy-paste handoff to run `/keelson:auto` in a
  clean session), keep talking, or `aguardando-produto` (pending planted in the INDEX
  active risks). **Reentrant by state on disk**: the BRIEF is the state, the session is
  disposable — resume maps answers to Q-IDs, promotes seals only on real evidence and
  re-analyzes only the delta; the fresh-clone test gates `pronto`. No new artifact
  type: additive sections on the paired BRIEF contract, NNN allocated by the single
  allocator and inherited by the SPEC. `/keelson:auto` gains the sister route to reuse
  a forged BRIEF without re-assembling; `/keelson:refine` keeps raw-idea polishing with
  a reciprocal boundary line; triage and the auto kickoff **suggest** the forge on raw
  structured documents (objective shape trigger — never a block); a reopening mode
  turns a product doc v2 into an interpretation diff; pending questions mirror as a
  comment on the origin issue when one exists (never a new card pre-SPEC), and resume
  pulls answers via `--from`. Graph engine untouched by construction. **Consumer block
  changed** (human-only commands note) — re-run `/keelson:init` on consumers.

---

## [0.68.0] — 2026-08-04

Decisions 4.100–4.101

### Added
- **A value premise escalates as a formal question to product (4.100).** Named instance
  of the PO's escalation criterion 1 (the list stays taxative): a value premise sealed
  `crença`/`anedota` holding up the demand's core is result-changing ambiguity. The
  escalation ships via the Diretor as a formal question to the product area — proposal
  = the smallest test that falsifies the premise (pass/fail criterion set **before**
  running; recipe owned by `value-test-protocol.md`, read only on trigger), default =
  proceed with the risk declared. The cycle detects and formalizes the evidence gap;
  its owner resolves it — no discovery commands enter keelson.
- **Structured production intake (4.101).** A new triage step fires only when the
  demand reports a production defect: the two tier-deciding questions (who/how many
  affected · data at risk) come before any severity; the objective ruler (🔴/🟠/🟡)
  and the structured fields (severity, impact, how to reproduce, evidence) are born in
  the routed artifact and feed the QA card for free. Two or more critical signals →
  a **major incident is recognized, never commanded**: the fix routes as an express
  demand and the Diretor receives the resolution checklist as *his* pending (symptom
  absent for a declared window · mitigation identified · no data left in a bad state ·
  owed communication sent — resolved ≠ mitigated). Ruler distilled per 4.72 (thresholds
  are declared defaults); the postmortem names the production-incident episode.

---

## [0.67.0] — 2026-08-04

Decisions 4.96–4.99

### Added
- **Evidence seals on SPEC premises (4.96).** Every §8 premise now carries, besides its
  origin (`[assumido]`/`[confirmar]`), a seal declaring what backs it: `crença` (belief,
  nothing observed) · `anedota` (1–2 reports) · `entrevistas` (pattern heard from 3+
  sources) · `medido` (production/experiment number). The seal never blocks — a central
  requirement resting on belief becomes explicit matter for the product-analyst critique
  and the PO resolution against the brief. Scale owned by the common conventions;
  spec-validator warns on a missing seal in Draft/Review only, so the existing archive
  stays quiet. Distilled from RENATA v0.5.0 (MIT © Eric Luque / AInsteins); the
  deliberate exclusions from that source are recorded in decision 4.96.
- **DECs declare their reopening condition (4.97).** New template line
  `Reabrir se: <observable condition | nunca — reason>` — the other half of the
  trade-off every DEC already documents. Two declared reaches: conditions observable in
  a diff are watched by gate 5 (a diff satisfying one becomes a finding citing the DEC —
  reopening is declared, never silently patched around); world conditions ride the
  existing irreversible-DEC propagation into the INDEX. plan-validator warns on the
  missing line in Draft/Review only.
- **Optional anti-persona line in SPEC §2 (4.98).** "Who this is NOT for" — a
  scope-discipline tool the product-analyst uses as reference when present; never
  required, never validated.
- **The success metric closes the loop (4.99).** SPEC §1.3 now declares its
  **measurement source** (`instrumentação` — an event/query the system will emit — or
  `externa` — tool + owner of the number). The PLAN's DoD derives a metric item with a
  valve so externally-owned metrics never make the DoD unsatisfiable; instrumentable
  sources become component work and gate 9 shows the number exists. Delivery plants the
  verdict pending in the INDEX active risks; the next cycle in the slug measures it
  itself when the ficha's means allow, or ships a ready copy-paste question to the
  product area (via the Diretor) in the report — never blocking, never forgetting.
  Building on top of an unverdicted capability is treated as critical ambiguity; a ❌
  verdict names the capability a sunset candidate (deciding is a product act). New
  graph check `metrica-sem-veredito` — the catalog's first INFO severity — reminds
  until the verdict exists; born with its fixture, suite 27/27 green, and SPECs without
  the source line (pre-4.99 archive) are excluded by construction.

---

## [0.66.0] — 2026-08-03

Decisions 4.92–4.95

### Changed
- **Closing a wave now takes an inventory against the artifacts, not against the
  session's memory (4.92).** A real 14-hour, 8-wave cycle shipped three process
  reworks with one cause: one task forgotten in each of two waves, and the
  review+security round run three times on one half of the stack and never on the
  other — only the Stop hook kept three blocking findings off the main branch. Wave
  close-out now confronts two named sources: the `### Wave N` checklist the task
  breakdown already generates (every listed task dispatched and Done — a forgotten
  task reopens the wave now, not at delivery) and the wave's own review round (a wave
  without its round does not close).
- **A fixed verification command must prove it exercises something (4.93).** A
  ready-criterion command ran green because a test group excluded the entire class it
  filtered on — the artifact was honored to the letter and nothing flagged it. The
  command is now executed at fixation time and the evidence of a non-empty set enters
  the criterion (N>0 tests executed; a predicate that excludes is fixed with a datum
  it rejects; a captured baseline proves it is not empty).
- **A finding's Solution names the condition, never just an instance of it (4.93).**
  A corrective action written as a list of error codes missed one and the same gate
  failed twice; the review doctrine now requires the condition ("every transport
  error code"), with closed enumerations only alongside the test that proves them
  complete.
- **The retry delta is reviewed as a diff in its own right (4.94).** Three
  regressions were born inside correction deltas and escaped delta-scoped re-review.
  Round N+1 now answers two questions — "did the finding close?" and "what does this
  delta break?" — applying gates 1–7 to the delta where it touches them, with the
  mechanical checks (lint, typecheck, relevant suite) always re-run. Refines the 4.88
  convergence rule.

### Fixed
- **The learning ledger writes serially (4.95).** Two concurrent `agile-coach` runs
  allocated the same `LRN` id. The id is now allocated at write time (re-read the
  ledger, take max+1) and serial invocation is part of the agent's contract — no
  invoker dispatches two `agile-coach` in parallel.

No consumer block change — no `/keelson:init` re-run needed for this batch (the 4.91
re-run still applies if pending).

---

## [0.65.1] — 2026-08-03

Decision 4.91

### Fixed
- **The consumer block no longer talks the cycle out of committing.** Two phrases
  born with the on-demand mode read as universal rules once inside the consumer's
  `CLAUDE.md` — "commit only at the Director's request" (4.75) and a close-out bullet
  scoped "on-demand **or cycle**" ending in "the commit is yours" (4.76). In a real
  consumer run the session obeyed them mid-cycle: it opened the wave branch and
  stopped committing per task, even though the cycle doctrine never changed (the
  `developer` commits each TASK, the closure commits per task, autonomy ends at the
  push — 4.41). Both phrases now carry their scope inside the sentence itself, and
  the close-out states the contract per mode: on-demand → the commit is the
  Director's; cycle → the branch arrives committed task by task (and pushed by
  `/keelson:auto`) — the Director's acts are review, PR and merge. **Re-run
  `/keelson:init` in consumer projects to refresh the block.**

---

## [0.65.0] — 2026-08-03

Decision 4.90

### Added
- **Gates now run at the granularity of what they prove — not uniformly per task.**
  Tests stay per task: they are the fine-grained net that lets the next wave build on
  proven ground. Independent review (gates 1–7) and security (gate 8) run **once per
  wave**, over the wave's accumulated diff with a task→files map in the context
  package — the wave was already the cycle's integration unit (merge dry-run, wave
  suite), reviewing per task re-read the same surroundings N times, and security
  actually *gains* from the integrated view (a new writer in one task plus a relaxed
  guard in another is exactly what isolated reviews miss). Findings are routed to the
  originating task; retries follow the 4.88 convergence rule; a vulnerability is
  still an immediate rejection and never waits beyond its own wave.
- **Behaviour (gate 9) is proven per feature/story, not per task** — in the first
  wave where the FEAT completes, when the end-to-end flow actually exists; proving
  "half a feature" per task duplicated gate 2 or proved nothing. A SPEC without
  FEATs gets one QA round against the PLAN's DoD in the final validation. The
  verification is recorded in the SPEC itself (a `**Verificação (gate 9)**:` line
  under the FEAT heading — free-form content, presence is the contract).
- **New graph check `feat-sem-verificacao`** (born with its fixture, suite 25/25):
  a FEAT whose declaring tasks are all Done with no verification line is an ERROR;
  a SPEC already `Done` (cycle closed before 4.90) degrades to `WARNING [legacy]`;
  an unparseable task silences the check in the safe direction. The SPEC node now
  carries `status=` and FEAT nodes carry `verif=` in the TSV (expected files
  refrozen deliberately).

### Changed
- Task closure declares where each consolidated gate ran (`wave N` · `FEAT-X` ·
  `DoD`) — consolidation is always declared, never silent (the 4.85 rule applied to
  granularity); the task-validator accepts these states as valid, not as pending.
  The on-demand mode is untouched: one change, one round. The consumer block does
  not change — no re-init needed for this batch.

---

## [0.64.0] — 2026-08-03

Decision 4.89

### Added
- **Gate-round orchestration rule: parallel by default, one context package.** Field
  data from the two ~1h45 sessions showed two silent costs beyond the re-gate loop:
  reviewers running one at a time for no reason (the parallel rule lived only in
  `/keelson:implement` and `/keelson:review` — the on-demand mode, where both slow
  sessions ran, had no rule), and each reviewer re-reading the same ficha, profile,
  anchor and diff the orchestrator already had (300–700KB agent transcripts that are
  mostly context rediscovery, not reasoning). Now owned by
  `guidelines/core/CODE-REVIEW.md` and binding for every invoker: applicable gates
  (7 · 8 · 9 are mutually independent) are dispatched **in the same turn**, sequence
  being a declared exception; and the invoker builds **one context package** —
  resolved diff + SHA, literal acceptance criteria from the anchor, the ficha slices
  (`quality.*`, `sensitiveGlobs`), the profile section to read, plus the previous
  verdict + delta on a re-gate (4.88) — delivered identically to every reviewer.

### Changed
- Guardrails on the package, so speed never costs quality: it is **factual, never
  evaluative** (the orchestrator's opinion of the diff stays out — reviewer
  independence is what gives the gate its value), and it never replaces doctrine —
  each reviewer keeps reading its own rulebook at runtime (4.20). The distilled
  briefings already in `/keelson:implement` and `/keelson:review` are now declared
  instances of the general rule, pointing at the owner.

---

## [0.63.0] — 2026-08-03

Decision 4.88

### Added
- **Re-gate convergence rule: a post-verdict fix converges or escalates — it never
  restarts the review.** Two consecutive real-world sessions spent ~1h45 each on
  changes worth a few dozen lines, and the time went to a review loop: each fix
  changed the diff, the Stop hooks correctly re-fired, the next round re-read the
  whole diff and found something more marginal — until the final rounds were arguing
  only about comments the process itself had produced. The rule, owned by
  `guidelines/core/CODE-REVIEW.md` and binding for every invoker (cycle, standalone
  review, on-demand mode): re-review is scoped to the **delta** of the fix (approved
  code stays approved unless the delta touches it); **one retry per gate**, then the
  second failure escalates to the human with state + proposal + default instead of a
  silent third round (a persistent security finding escalates as a blocker — it is
  never worked around); a fix whose delta is inert (comments/docs only, the 4.84
  mechanical test) re-checks with the same reviewer and does not reopen the
  behavioural gates; and the story of what a fix round changed lives in the gate
  report and the artifact history — **never in code comments**, where it talks to
  today's reviewer instead of tomorrow's reader and gets (rightly) rejected on the
  next round.
- New troubleshooting entry: "a small change is taking hours in review rounds" —
  what the loop looks like and how the convergence rule breaks it.

### Changed
- `review-guard` and `security-guard` messages now name the delta-scoped path, so a
  session facing a re-fired hook knows a full re-review is not what is being asked
  (message prose only — no logic change). The comment floor/ceiling (4.31–4.33) is
  untouched: the durable *why* still belongs in code; killing comments outright was
  considered and rejected.

---

## [0.62.0] — 2026-08-02

Decision 4.87

### Added
- **A standalone brief that spans several slugs now has a defined home.** The first
  real-world standalone change crossed four slugs and, with no placement rule, no
  brief was written at all — the board card only appeared after the code, pushed by
  the jira-guard. The rule: a cross-cutting change keeps **one** brief (the unit is
  the change, not the slug), living in the **dominant slug** — falsifiable test:
  *if this grew into a cycle, which slug would own the SPEC?* In practice, the slug
  that owns the code realizing the change (the shared component/mechanism), not the
  screens receiving it; a genuine tie is broken by declaring the choice in the
  brief's interpretation. Each other touched slug gets a one-line pointer in its
  INDEX's recent-history section — a reference, never a copy. The brief's TASKs stay
  in the brief's slug: the `**Brief**:` anchor never crosses slugs (the graph works
  per slug directory, and a cross-slug anchor failing as `ref-quebrada` is now by
  design). The skeleton's `**Slug**:` line gains a short opt-in form naming the
  other touched slugs; the graph extractor does not read that line, so the engine
  is untouched.

### Changed
- If the card-after-the-code pattern recurs on a multi-slug change now that the
  placement rule exists, the planned response is a mechanical **brief-guard** (a
  Stop hook in the jira-guard mold: non-trivial change with neither a brief nor an
  SDD artifact → demand the file). Recorded in the decision as the escalation path,
  not shipped in this release.

---

## [0.61.0] — 2026-08-02

Decision 4.86

### Added
- **Standalone brief: day-to-day work gets a written task before the code.** A bugfix
  or small improvement with no applicable SPEC/PLAN is born as a standalone brief
  (`briefs/BRIEF-MMM-*-avulso.md`) — request as stated, interpretation, acceptance
  criterion — written in the on-demand mode's first turn (4.75) or routed by
  `/keelson:triage`. Splittable work anchors TASKs on the brief (`**Brief**:` instead
  of `**Pertence a**:`); a single diff needs no TASK — the brief is the unit and
  carries the closure fields. Falsifiable routing rule: changing what the system
  promises, or a decomposition that would need a technical decision (a DEC), is a
  cycle, never a standalone.
- **The tracker card exists while the work happens, not after.** With `jira.enabled`
  and `issueType.standalone` set (the leg shipped in 4.28 that never had a producer),
  the brief becomes a Story on the board **before coding starts**, and its TASKs
  become sub-tasks of that Story. New ficha field `jira.standaloneParent`: the key of
  a grouping Epic (created once by the human) that parents those Stories; `null` →
  parentless Story — both valid.
- **Pull route.** `/keelson:triage --from=<KEY>` (or citing a key in the on-demand
  mode) turns an existing human-written card into the brief: the card's description
  is the classification input, the key lands on the brief's `**Jira**:` line (link
  semantics), and no duplicate card is ever created.
- **The graph learns the standalone anchor.** New node (standalone BRIEF), new edge
  (`task-brief`), new checks (`brief-sem-criterio` WARNING, `task-ancora-dupla`
  ERROR); `ref-quebrada` and `pertence-vs-arquivo` cover the new anchor. Two new
  fixtures; suite grows to 24 cases, all green. Artifact numbering becomes a single
  per-slug allocator (max of all numbered artifacts + 1), making BRIEF filename
  collisions impossible by construction — per-type density was never a contract.

### Changed
- Re-run `/keelson:init` on consumers (the managed block and the ficha changed;
  merge-preserving).

---

## [0.60.0] — 2026-08-02

Decision 4.85

### Changed
- **Contract conflicts now escalate instead of being silently arbitrated.** Field
  postmortem from the first real free-form session on a consumer: a harness directive
  restricting subagents clashed with the on-demand delegation contract (4.75) and the
  session resolved it silently in the harness's favor — the human who configures both
  sides never learned there was a conflict. The consumer block now requires declaring
  **who writes the code** in the first turn, and any session/harness policy conflicting
  with the contract escalates to the human with a proposal and a default — the PO's
  escalation-by-exception rule (4.37), now applied to the Tech Lead itself.
- **The closing report declares the gate that did NOT run.** The block's closing rule
  was one-way ("gates run, and by whom"), so a report could read "Gates ✅ · the commit
  is yours" while review and security had not run yet — emitted before Stop hooks could
  block the turn. The closing rule is now symmetric and aligned with `/keelson:report`:
  every applicable gate carries a declared state — run (and by whom) · n/a (reason) ·
  **"not run — reason", never omitted** — and a close with a pending gate declares
  itself partial and does not invite a commit.
- Re-run `/keelson:init` on consumers (the managed block changed; merge-preserving).

---

## [0.59.0] — 2026-08-02

Decision 4.84

### Added
- **Inert diff waives the test suite.** The suite exists to prove code: when no file in
  the diff can change the behavior it proves — docs-only, SDD artifacts, static assets —
  the run is waived at every execution point (developer baseline and final run, gate 2,
  end of wave, DoD check, `/keelson:integrate`). The rule has a single owner
  (`guidelines/core/TESTING.md`, "Diff inerte") and three guard-rails: the check is
  mechanical and anchored (`git diff --name-only <base>...HEAD` against the project's
  `codePaths` and test trees, never an impression); anything the runtime or runner loads
  (source, tests, fixtures, dependency manifests, runtime config, build scripts) still
  counts as code — when in doubt, run; and the waiver is always a declared state in the
  report, never silence.

---

## [0.58.0] — 2026-08-02

Decision 4.83

### Added
- **The mechanical part of the plugin now proves itself.** The repo's `pre-commit` hook
  gains a quality guard: `bash -n` on every staged script, the graph regression suite
  when `scripts/graph.sh` or its fixtures change, and release checks when
  `.claude-plugin/`, `CHANGELOG.md`, `README.md` or `publish-wiki.sh` change — commits
  that touch none of it pay nothing (`KEELSON_SKIP_TESTS=1` is the conscious escape).
- **`scripts/check-release.sh`**: the release rules that were doctrine-only become a
  machine — version synchronized across the three places, current version present in
  the CHANGELOG (rule 4.48), no phantom wiki mirrors, `bash -n` across all scripts.
  All violations listed at once; `--root` makes it testable against synthetic trees.
- **CI (`.github/workflows/test.yml`)**: every push/PR runs the graph suite and the
  release checks on `ubuntu-latest` — the safety net for whatever slips past the local
  hook, and the Linux portability proof a macOS workstation cannot give.

### Fixed
- The `pre-commit` main-top guard (4.63) was restructured as a function: its
  "not applicable" early exits (detached HEAD, non-main branch, no remote) no longer
  skip the quality guard that now follows it.

---

## [0.57.0] — 2026-08-02

Decision 4.82

### Added
- **The SDD artifact graph becomes a mechanical fact.** `scripts/graph.sh` (bash 3.2 +
  POSIX awk, zero new dependencies, read-only) extracts every typed relation between
  SPECs, PLANs and TASKs into a deterministic TSV, computes the structural check
  catalog — dependency cycles, broken references, duplicate IDs (the parallel-session
  hazard of decision 4.63), incoherent waves, FR/AC coverage, FRs missing from the §7
  mapping, derived FEAT sets, Depende/Bloqueia symmetry, stale TASK-INDEX — and renders
  Mermaid diagrams (tasks by wave; FR→COMP). The rulebook has a single owner,
  `docs/_meta/conventions/graph-contract.md`, mirrored to the wiki.
- **A durable regression suite** (`scripts/tests/graph/`): synthetic slugs with planted
  defects, frozen expected outputs and a 21-case runner proving zero false positives on
  valid fixtures, byte-for-byte determinism and read-only behavior. A check does not
  enter the catalog without a fixture.

### Changed
- **Validators now cite computed facts instead of re-deriving structure.** The
  task-validator's linkage/dependency/coverage steps and the plan-validator's
  component-graph step run graph.sh and quote its findings; only semantic checks remain
  theirs. Calibration stays with the validator (protocol §1/§3). Degradation is by
  result — any run without contract-valid output falls back to reading, declared with
  the named cause — and unparseable edges block asserting absence-of-defect for that
  artifact (mixed coverage).
- **Edge fields gain canonical syntax** in the generator templates (ID lists or
  `nenhuma`); bugfix TASKs declare the violated AC in a dedicated `AC violado` field;
  the AC `(cobre …)` annotation is a full-ID list scoped to a single FEAT. Legacy
  artifacts never fail on form: empty fields read as `nenhuma`, prose degrades to a
  `nao-parseavel` warning — and any absence check fed by an unparseable field degrades
  with it (`[parse]`) — while wave/coverage findings on `Done` artifacts downgrade to
  `[legacy]` warnings.
- `/keelson:tasks` verifies cycles and waves mechanically before its validation gate;
  `/keelson:status` renders the dependency or FR→COMP Mermaid when asked about
  ordering.

---

## [0.56.0] — 2026-07-31

Decision 4.81

### Added
- **A user wiki, with its source in this repository.** The
  [wiki](https://github.com/fernandopetry/keelson/wiki) answers the question neither the
  README (the package's English shop window) nor the method guide (reference for people
  already inside the repo) was written for: *I installed it, now what?* It ships pages for
  install and update, first steps, concepts, the ficha field by field, troubleshooting and an
  FAQ — in Portuguese, the language of the doctrine.
- **The wiki is a generated artifact, never a source.** Pages live in `docs/wiki/`; files that
  already own their text (method guide, Quality Charter, INDEX contract, commit convention,
  handoff protocol) are **mirrored, not rewritten**, so no rule gains a second owner. Content
  goes through a Pull Request like any other file — a wiki nobody can review is the failure
  mode this plugin exists to fix.
- **`scripts/publish-wiki.sh`** — copies the pages, rewrites links (published target → wiki
  page, everything else → GitHub blob), removes only pages it generated itself (a
  hand-written page on the wiki survives) and pushes. `--dry-run` to preview, `--check` to
  fail when the published wiki is stale. A wiki that was never initialized is reported with
  the fix, never worked around: the `.wiki.git` repository only exists after the first page is
  created through the web UI.
- **`.github/workflows/publish-wiki.yml`** — republishes on every push to `main` that touches
  the sources. Publishing is mechanical; forgetting it is what makes documentation rot.

---

## [0.55.0] — 2026-07-31

Decision 4.80

### Added
- **Commit messages have an owner, and the type is a closed list.** The rule used to be a
  sentence — "the project's convention; defaults to Conventional Commits" — with no list of
  types, no handling of breaking changes and nowhere to look it up. It now lives in
  `docs/_meta/conventions/commit-convention.md`: eleven canonical types, the test for picking
  one (*does whoever uses the system notice a difference?*), the `fix` vs `refactor` line, and
  **breaking changes declared rather than inferred** (`type(scope)!:` or a `BREAKING CHANGE:`
  footer). An invented type is a defect, not creativity — changelog generators drop it and
  message linters reject it, so the commit vanishes from the release notes precisely when it
  matters.
- **`/keelson:init` detects your release automation** — `semantic-release`, `release-please`,
  `standard-version`, `commitlint`, `git-cliff`, `python-semantic-release` — and records it in
  the new `commit` block of the ficha, alongside the convention your history actually uses. A
  project with its own convention keeps it: keelson follows the house rather than converting
  it. Non-canonical types found in the history are reported with their canonical equivalent,
  as information — never as a rewrite.
- **Where the type starts to carry weight**: with automation declared, `feat` means minor and
  `fix` means patch, and an unmarked breaking change publishes a minor where a major was due.
  The developer agent now escalates a genuine `feat`-or-`fix` doubt instead of guessing.

### Changed
- **Keelson feeds release automation; it does not operate it.** Publishing a release is the
  Director's act, in the same class as opening a PR, merging and deploying — it involves
  credentials, branch protection and tags that live outside the repository, and the right tool
  varies by stack. So no agent was added for this, and nothing is installed in your repository:
  the plugin guarantees the one thing only it can, which is that the commits it writes are
  consumable by whichever tool you choose. The README documents the usual routes per stack.

---

## [0.54.1] — 2026-07-31

Decision 4.79 (revised)

### Changed
- **The tracker keys moved behind the commit type**, from
  `PROJ-12 PROJ-34 PROJ-56 feat(scope): …` (as shipped in 0.54.0) to
  `feat(scope): PROJ-12 PROJ-34 PROJ-56 …`. Jira matches an issue key **anywhere** in the
  message, so opening the title with it gained nothing on the tracker side — while the first
  position of a commit convention anchors real tooling: release and changelog generators that
  derive the version from the type, message linters, and log filters anchored at the start.
  Keelson ships to many projects, and breaking that anchor would fail **silently** in any
  consumer relying on release automation. The cost is losing the keys' alignment in column one
  of `git log --oneline`.

---

## [0.54.0] — 2026-07-31

Decision 4.79

### Added
- **Commit titles now open with the tracker keys.** With `jira.enabled`, every commit the
  cycle produces is prefixed with the keys involved, broadest to narrowest —
  `PROJ-12 PROJ-34 PROJ-56 feat(<slug>): …` — before the project's own commit convention, which
  is prefixed rather than replaced. The repository history finally says which demand each
  commit belongs to, and Jira links the work to the issue without waiting for a pull request.
  Keys come from where the cycle already stores them: the epic on the spec header, the story
  under its feature heading, the sub-task in the task's closure.
  - Bounded on purpose: a cross-cutting task lists only its primary feature (secondary ones
    are already linked in Jira), and a wave or delivery commit touching more than three
    stories carries just the epic.
  - Commits that are not demand work — doctrine and tooling patches — stay unprefixed.
  - A missing key is dropped from the prefix and the commit proceeds; with no key resolved at
    all the commit looks exactly as it does today. Keys are never invented, and a commit never
    waits on Jira.
  - Projects using a strict Conventional Commits parser (commitlint, semantic-release) need to
    configure it for the prefix; without `jira.enabled` nothing changes at all.

---

## [0.53.0] — 2026-07-31

Decision 4.78

### Changed
- **Generated QA cards keep the acceptance criterion's Given-When-Then instead of
  paraphrasing it.** Teams used to BDD read `Given/When/Then` as native vocabulary, and the
  previous recipe threw that away by rewriting every criterion as imperative prose — then
  repeated the same content in a separate formal list. The criterion is now **copied
  verbatim** into the scenario (rewriting it would let claims drift from what the artefact
  supports); what still gets translated into business language is the requirement itself,
  never the criterion.
- **Each scenario now carries a `How to reproduce` line with concrete values.** An
  acceptance criterion is declarative by design — *"Given a competence whose first day falls
  on a Wednesday"* says what to prove and not how to get there, and that gap is precisely
  where a tester stops and asks. The card now names the literal date to set, the record to
  create, the profile to log in as. Restating the abstract condition as if it were a step is
  called out as the failure, not accepted as a variation.
- **The separate "Acceptance criteria" section is gone** — the criterion lives inside its
  scenario. The card gets **shorter** than before: two sections merged into one, not a third
  one added.
- **One scenario per criterion makes coverage visible.** A criterion with no scenario and no
  place on the automated-checks line now stands out, where a bare list of IDs hid it — a real
  card had been silently missing two. The form check gained the matching item, plus one that
  catches a reproduction line with no concrete value.
- **An accepted risk that shows up on screen now belongs in "Out of scope".** It is exactly
  what a good-faith tester files as a bug, so the spec's risk section became a legitimate
  source for the card alongside the scope section.

---

## [0.52.0] — 2026-07-31

Decision 4.77

### Added
- **Literal skeletons for generated Jira descriptions.** The three issue roles (Epic ·
  QA unit · sub-task) now ship as copyable markdown blocks with exact headings in exact
  order, replacing prose that described what each section should contain. Prose about form
  turned out to be paraphrasable: real cards came out with invented sections and without
  **How to test** — the one section that justifies the card existing — while the acceptance
  criteria were reduced to bare IDs pointing back at the spec.
- **Form check before the issue is sent.** Every rendered description is verified against
  its skeleton: all headings present and in order with none added, *How to test* carrying at
  least one scenario with numbered steps, each acceptance criterion shown with its text and
  not only its ID, and no line referring the reader to a repo artefact. It re-renders once on
  failure, then creates the issue anyway with the gap named in the warning — a thin card is
  bad, a missing card is worse (it breaks sub-task parenting and idempotency), and
  best-effort stays inviolable. It checks form, not merit: whether the card stands on its
  own, not whether the script tests well.

### Changed
- **Two writing rules now name the failures observed in the field.** A reference to an
  artefact never substitutes for content — an ID always carries its text, and the part of a
  requirement or assumption that matters to the test becomes a sentence in the narrative or a
  step in the script. And a known edge case is a step, not a remark: a boundary rule the spec
  names goes into *How to test* as its own scenario with the concrete value in the setup.
  What does not become a step does not get tested.

---

## [0.51.0] — 2026-07-31

Decision 4.76

### Added
- **Session ledger — the closing report is written as it happens, not remembered.** Every
  event from a closed catalogue (`gate` with who implemented and who reviewed · decisions
  taken on the Director's behalf · out-of-scope findings · parked work · tracker
  degradation · timing marks) is written to `thoughts/local/session-ledger/` the moment it
  occurs, one file per event. The final report is assembled by reading that folder instead
  of re-reading a session whose context was compressed — so a detail that no longer fits in
  the window still reaches you. Parallel waves in worktrees are safe by construction (no
  shared append). The ledger is never a gate: missing or partial, the report ships with the
  gap named.
- **Every change now closes with a report — automatically.** On-demand mode (0.50.0) used
  to deliver a change with no closure at all; it now ends with the same shape as the cycle's
  delivery: diff composition, gates and who ran them, decisions made for you, what's out of
  scope or pending, tracker state, and what's waiting on you.
- **`/keelson:report`** — human-only safety net that rebuilds the closing report from the
  ledger, the branch diff and the INDEX, for a resumed session or a report lost in the
  scroll. It does not re-read the session (that's `/keelson:postmortem`, a different
  question), does not commit, and never turns an unrecorded gate into an approved one.
- **Reconnection section for a degraded tracker.** Any command whose Jira sync degraded now
  emits a copy-paste block naming where the connector dropped, what it returned literally,
  what was left behind, and the exact `/keelson:jira-sync` command to run once the MCP is
  back — `--dry-run` first, `--phase` only when a board move was actually pending and never
  under `transition: off`.

### Changed
- **Connector availability is execution state in both directions.** A proof that the
  Atlassian connector is up already held for the whole run; a **drop mid-run** now does too.
  Previously, a connector that was proven healthy at kickoff and died halfway made every
  later hook fail on its own, each failure swallowed as best-effort and none of them
  reaching the report. Per-operation failures with a responding connector remain warnings,
  not a drop. Best-effort still never blocks — it just no longer stays quiet.

---

## [0.50.0] — 2026-07-31

Decision 4.75

### Added
- **On-demand mode: the team serves free-form sessions without the full cycle.** First
  real round after 4.73 showed the gap: in a session with no keelson command invoked,
  a point code change ran with none of the plugin's protections — the main session
  swept the codebase inline and implemented the change itself. Free-form doctrine now
  has a third state between "full cycle" and "inline": a localized code change with no
  product decision is delegated to the `developer` (short distilled brief: what,
  where, acceptance criterion), the diff goes through the `code-reviewer` with the
  standalone ruler (4.36), and `security-engineer`/`qa` fire on the same triggers as
  the cycle (sensitive change · observable behavior). No auto-commit — committing is
  the Director's ask. Invoking one agent never pulls the whole cycle: each agent
  returns its task and stops; orchestration always stays with the main session. Only
  trivial non-behavioral fixes (comment/doc typo) may be done inline, declared.

### Changed
- **`code-scout` adoption stops relying on its description alone** (closes 4.73's
  observation — organic adoption did not happen in the first real round). The trigger
  now lives in the consumer's CLAUDE block — the only keelson surface always present
  in a free-form session — and as a cue in the exploratory commands (`triage`,
  `specify`, `plan`, `review`): broad sweeps are delegated, point lookups stay inline.
- **Executor descriptions declare the new invoker**: `developer`, `code-reviewer`,
  `qa`, `security-engineer` and `code-scout` now list the on-demand mode / free-form
  session among their invokers.

Re-run `/keelson:init` on consumer projects to receive the updated CLAUDE block.

---

## [0.49.1] — 2026-07-31

Decision 4.74

### Changed
- **Merge dry-run before integrating wave worktrees (teams mode).** At the end of a
  parallel wave, each task worktree's branch is now dry-run-merged into the wave branch
  (`git merge-tree --write-tree`, git ≥ 2.38; fallback `git merge --no-commit
  --no-ff` followed by `git merge --abort`) before any real merge starts. No real merge begins while a
  conflicted dry-run sits in the queue: a conflict anywhere means nothing gets
  integrated, and the report to the Director lists the conflicting worktrees and paths
  with the wave branch still clean — previously the conflict only surfaced during the
  real merge, mid-integration. The post-conflict rule is unchanged (pause, report,
  manual resolution); no SEQUENTIAL_FORCED criterion is relaxed.

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
