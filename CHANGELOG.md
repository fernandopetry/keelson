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

Every versioned entry carries a machine-readable `Re-init: required | none` line right below
its heading (§4.189): `required` means the release changed the injected CLAUDE block or the
ficha (`keelson.config.json`) contract, so consumers must re-run `/keelson:init` after
updating. `scripts/update.sh` reads these lines to tell the consumer whether the jump they
just made needs a re-init. Markers up to `0.94.0` were backfilled on 2026-08-12 from entry
prose and maintainer records; when the two conflicted, `required` won (a redundant init is
merge-preserving and harmless — a wrong `none` is not).

## [Unreleased]

## [0.138.0] — 2026-08-30

Re-init: required

Decision 4.314 — session home for cycle-transient files (slice 1 of the
session-folder mini-brief; re-init refreshes the injected block, which
referenced the old ledger path).

### Added

- **Session home**: each session's cycle-transient files now live in one
  folder per session — `thoughts/local/sessions/<yyyymmdd-hhmmss>-<sid8>/`
  — holding `run-state-<slug>.md`, `ledger/` (+ `reported-*/` inside),
  `window.log` + its offset, `tools/` (4.184) and `backups/`, plus a
  `session.meta` manifest (full session id, start time, state, slugs
  touched). New canonical resolver `scripts/session-dir.sh`
  (`dir`/`ledger-dir`/`window-log`, `--create`, `--slug`) owns the path
  rule; with no session id everything falls back to the legacy
  `thoughts/local/` paths unchanged.
- **Test suites for previously uncovered hooks**: `window-marker`,
  `compact-anchor`, `review-guard` and `security-guard` gained
  characterization suites (green before the migration; the new-layout
  cases were born red to prove they bite), wired into pre-commit and CI
  alongside the new `session-dir` suite.

### Changed

- **Writers** (`run-state.sh`, `ledger.sh`, `window-marker` hook) write
  only to the session home; **readers** (`context-cost.sh`, the
  `wave-guard`/`review-guard`/`security-guard`/`compact-anchor` hooks and
  the scripts themselves) accept both layouts — a run, ledger or window
  log started before the update stays operable by the same session, and
  ledger `list`/`count`/`archive` aggregate both homes (each archives
  `reported-*/` inside itself).
- **Ownership becomes structural**: through the scripts, a session only
  reaches its own home (the 4.251 textual refusal remains for legacy
  files); cross-session visibility — third-party ownership warnings —
  stays with the hooks, which scan both homes.
- Exploration memos intentionally stay at
  `thoughts/local/exploration-<slug>.md` (they cross sessions by design;
  they move with the session-handover slice), and
  `thoughts/screen-verify/` / `thoughts/e2e/` are config-pointed tool
  homes and do not move.

## [0.137.2] — 2026-08-30

Re-init: none

Decision 4.313 — closes the loop on forge telemetry analysis.

### Fixed

- **`/keelson:postmortem`**: the BRIEF's `Cronologia` (telemetry tails —
  `correções`/`classes`/`janelas`, 4.275/4.311) and `Estimativa` section
  are now an enumerated evidence source in Step 1. A postmortem run
  outside the original session (slug/branch target) previously lost the
  measured forge numbers — exactly the ones that decide the 4.312
  deferred-scaffold trigger; expensive forge rework is a candidate row
  under the existing `retrabalho de processo` nature. Missing numbers
  stay omitted, never estimated.

## [0.137.1] — 2026-08-30

Re-init: none

Decision 4.312 — partial absorption of an external forge benchmark
(the Director's second opinion). Two refinements land; the deterministic
task-scaffold idea is deferred with a declared telemetry trigger; the
semantic-compiler core is refused with recorded reasons (it inverts
"markdown is the source", 4.82, and makes evaluators write corrections,
breaking generator ≠ evaluator).

### Changed

- **Correction-package anchors**: each fix now leads with the ID of the
  element it targets (FR/AC/NFR/DEC/COMP/TASK — validator reports already
  carry it) ahead of the section heading + literal excerpt; the ID is the
  stable half of the anchor when another fix in the same package shifts
  the text. Prose-only defects still anchor textually (4.312, refining
  4.309).
- **`/keelson:auto`**: the PLAN-stage `code-scout` reconnaissance is now
  dispatched during the SPEC promotion/INDEX/commit window instead of
  after it — the territory it maps is the code, which stage closure does
  not touch; `/keelson:plan` reuses a delivered reconnaissance instead of
  re-dispatching (4.312).

Re-init: none

Decisions 4.309–4.311 — forge-speed batch, from a measured consumer session
(~4h33 of artifact phase before the first line of code; the single largest
block was a ~37-minute SPEC correction window that rewrote a ~900-line
document to apply 19 localized fixes).

### Added

- **`/keelson:tasks`**: fan-out route for large decompositions (predicted
  >8 tasks): one scribe returns a frozen manifest (IDs, waves, edges,
  AC×gate distribution) without writing files, then 2–3 scribes write
  disjoint literal file lists in parallel; `TASK-MMM-INDEX.md` becomes the
  main session's to derive from the manifest, and the existing mechanical
  proofs (`graph.sh --check` + task-validator) guarantee global consistency
  in both routes (4.310). Small decompositions keep the single-window route.
- **Forge telemetry — window cost**: the per-stage telemetry tail in the
  BRIEF's `Cronologia` gains a `janelas` field (minutes measured by the
  main session's clock between dispatch and return of each scribe window,
  lines via `wc -l` over the returned artifact paths — never self-reported),
  and the report's `Forja` line transcribes it per stage. Measured or
  omitted, never estimated; never a trigger (4.311). This is the field
  instrument that will prove — or refute — the effect of 4.309/4.310.

### Changed

- **`scribe` correction packages**: a localized package (≤ ~20 fixes, no
  section renumbering/restructuring) is now applied as a batch of surgical
  `Edit`s in a single turn, reading only the sections the package anchors
  cite — instead of rewriting the whole file (4.309 revises 4.112 on this
  branch; 4.112 still owns first-draft writing and structural packages).
  Every fix in a package now travels with an anchor (section heading +
  literal excerpt) supplied by the invoker; a fix without an anchor
  demotes the package to the structural mode. `edge-diff.sh` proves edge
  preservation (4.117) in both modes, and the one-round consolidation rule
  (4.116) is explicitly untouched — the branch changes how a package is
  applied, never how many rounds are allowed.

Re-init: none

Decisions 4.307–4.308 — field-intake batch from a consumer postmortem
(0.132.0, plan closeout): three pathways of the same family — "name the
condition, not the instances; verify before prescribing" — each patched in
its own owner, plus `data_inicio` capture moved to the dispatch step.

### Changed

- **`/keelson:implement`**: a consolidated retry item that merges findings
  from distinct dedicated gates (8/9/10/11) now names the CONDITION the
  mechanism describes, with a closing grep — instances cited by each gate
  are non-exhaustive illustration (4.307; field case: gates cited 3 of 4
  truncatable enumerations of the same method, the retry closed exactly
  those 3 with a mutant each, and the 4th — the largest — reproduced the
  defect after "closure").
- **`/keelson:implement`**: `data_inicio` is captured by the orchestrator
  BEFORE dispatching a task's first execution — the developer's report
  becomes reinforcement, never the only source; a retry does not recapture
  a lost instant (4.308; field case: both sources failed together for 3
  rounds and the field closed with an honest "not measured" placeholder
  that the closure gate cannot see).
- **`product-designer` (gate 11)**: the "verify before prescribing" rule
  (4.230) now also covers state echo/mirror corrections — every writer of
  the mirrored state is located by grep and named in the fix before it is
  written; without the writer list the finding degrades to a suggestion
  (4.307; field case: 1 of 2 writers named, and the patch produced a worse
  defect than the original).
- **`/keelson:tasks`**: new anti-circumvention test (h) — a merged file
  cited as template/exemplar outside the Criteria has its prescribed
  literal checked against the template's real content, and the template
  itself is checked against active lessons before becoming a copy
  instruction (4.307; field cases: a binding contradicted by the template
  cited in the same sentence, and templates that already carried the
  documented defect).

## [0.135.0] — 2026-08-30

Re-init: none

Decision 4.304 (post-batch notes) — the eval bench gains its pruning
instrument and delivers its first triangular verdict. Full-phase cost:
US$58.97 across 6 rounds (one round self-invalidated by the plant discipline
and was discarded as evidence — by design).

### Added

- **Minimal-rule control arm** (`evals/decomposicao-comportamento/arms/
  REGUA-MINIMA.md`): a format-only ruleset with zero decomposition
  principles, measuring rule-vs-model-default per axis — the proof
  instrument behind "prune only with evidence". First triangular result
  (old rule n=4 · no rule n=4 · current rule n=8): the 0.130.0 rule scored
  **below no-rule at all** on 2 of 3 axes; the frozen-interface and
  behavior-cut rules convert 3/4→8/8 and 1/4→7/8 (they earn their keep);
  the measurement rule's decomposition half becomes a pruning candidate
  with a declared reopening trigger — recorded, not cut.

### Fixed

- **Plant sabotage is now deterministic**: layer-slicing could accidentally
  fuse the open interface into a single "service" task, letting the plant
  pass one axis and invalidating the whole round (the positive-control
  discipline caught it and discarded the round). Read and write are now
  distinct layers in the plant ruleset.

## [0.134.1] — 2026-08-30

Re-init: none

Decision 4.306 — the structural-pruning backlog item from 4.300 closes without
execution: both command files sit well under the governing 500-line ceiling
(4.217), and the named extraction candidate measured 1–2 physical lines with
real risk attached (a 4th copy of an already-owned rule, and a silent break of
eval case #1, which slices that exact section). What the investigation did
find gets fixed here.

### Fixed

- **`agile-coach` no longer enforces revoked ceilings**: its patch-budget rule
  taught "command ≤ 300, agent ≤ 220, skill ≤ 250" — a live copy of the rule
  that 4.217 superseded with a single 500-line ceiling. The budget line now
  cites the owner; the ≤10-line patch budget and the zero-balance-at-ceiling
  rule are unchanged.
- **`/keelson:tasks` points at the lint-fact owner**: the lint facts named in
  the criterion-hardening rules now carry the path to
  `conventions/lint-contract.md` (the rule lived in three owners with no
  pointer between two of them).

## [0.134.0] — 2026-08-30

Re-init: none

Decision 4.305 — cause is attributed before instructions get edited. The
process-learning flow gains a closed root-cause catalog and, most
importantly, the exit that was missing: "no instruction would have prevented
this" is now a legitimate outcome, so failures stop turning into prompt
bloat by default.

### Added

- **Closed root-cause catalog on `causa_raiz:`** — `instrucao_ausente ·
  instrucao_ambigua · instrucao_nao_chegou · verificador_furado ·
  ferramenta_ambiente · especificacao · raciocinio_pontual`, each value with
  a prescribed exit. It refines only the "verification" side of the 4.69
  axis (model-blame stays banned — reasoning-class failures still never
  become rules); consumers never widen the catalog, a new value enters
  through the owner (the maintainer learning-log header), mirroring the
  handoff-cause precedent.

### Changed

- **`agile-coach` attributes before it patches**: step 3 now classifies the
  cause first, and only the three instructional causes proceed to an
  instruction patch — a broken checker gets its check fixed (never more
  text), tool/environment failures route to tooling, wrong task boundaries
  route to the plan-gap flow, and one-off reasoning failures are discarded.
  A ledger entry without a catalog value is malformed and is not written.
- **`/field-intake` verdicts name the cause** for process-failure reports,
  or the delivery declares itself partial — non-instructional causes no
  longer produce new doctrine text.

## [0.133.0] — 2026-08-30

Re-init: none

Decision 4.304 — a behavior-eval layer for the maintainer: doctrine changes
can now be A/B-measured on versioned, re-runnable cases instead of settled by
judgment alone. Advisory by design; the mechanical guard suites stay the
blocking layer.

### Added

- **`evals/` layer + `scripts/eval-run.sh`**: versioned eval cases in the
  `claude plugin eval` format (prompt + llm/file_exists/regex graders), run
  today by a self-contained runner over hermetic `claude -p` sessions
  (`--strict-mcp-config`, one throwaway workspace per run). Doctrine arms are
  selected by `git:<ref>`/`file:` source; the per-axis verdict is
  **advisory** — intra-arm variance yields HOLD, never a silent average — and
  a plant control that gets approved (or returns no valid verdict)
  invalidates the whole round. Runs on the Director's demand or before a
  doctrine batch of a covered class; never in pre-commit/CI. Ships with a
  deterministic test suite (fake executor, 12 assertions) wired into
  pre-commit.
- **Case #1 — `evals/decomposicao-comportamento`**: the 4.301 synthetic bench
  (decoy PLAN with an unfrozen internal interface, an unmeasured numeric risk
  and a layer-cut temptation) rebuilt as a re-runnable artifact. Its first
  real round (n=1, sonnet) reproduced the original bench's pattern — the
  0.131.0 rule wins the measurement-task axis, ties elsewhere, plant detected
  on all three axes — at US$5.71 / ~17 min / 12 calls.

### Changed

- The 4.260 "no formal trigger" deferral of LLM behavior evals is superseded,
  and the maintainer authoring ruler now names three evaluation layers
  (script suites · behavior evals · field rounds) — both amended as declared
  divergences (Director's act, 4.209 precedent).

## [0.132.0] — 2026-08-29

Re-init: none

Decisions 4.302–4.303 — absorbing the field postmortem of the session that
motivated 0.130.0. Its central finding: every rule violated there already
existed in the installed package, correctly written and cited at the point of
use — so each fix lands as an executable line in the dispatcher's hand, never
more adjacent prose. Two of its five mechanisms were already fixed hours
earlier (0.130.0's agent-guard and wave-guard).

### Changed

- **Inherited gate criteria prescribe the CONDITION, with countable closure**
  ("every per-item write inside the loop", "N volume axes → N volume pairs in
  the proof") — a named instance is a non-exhaustive illustration. Third
  occurrence of the instance-list-vs-countable-closure class; a loop with two
  or more volume axes must be proven on each axis (in the field, the
  prescription named 2 of 4 writes and the next gate measured exactly the cost
  the criterion's own justification had predicted).
- **Retry items are dispatched with the proof PAIR**: the mutant that kills
  the defect and the proof that the legitimate/boundary case survives the fix.
  A briefing with one-sided mutants breeds the benign-side regression inside
  the correction — the two-axes rule now reaches the developer at dispatch,
  not only the reviewer at re-review.
- **The gate-round briefing declares the write surface**: a gate whose proof
  creates or mutates files (measurement harness, mutants) works in an isolated
  worktree — never in the tree the parallel gates of the same round are
  reading (in the field, a measurement harness broke the build under two
  parallel gates).
- **Empty-channel redispatch requires proof of death**: a silent teammate may
  be working, delivered-but-lost, or dead — all look identical. One follow-up
  through the channel plus a process check come first; an unreported role is
  redispatched once, with the duplication declared (in the field, two
  redispatched reviewers duplicated finished reviews).
- **A named teammate is a persistent process**: measured field experiment —
  all 10 named dispatches left living processes after delivering (~10% CPU/RAM
  until a manual kill), while the 4 anonymous dispatches of the same session
  exited on their own. Session teardown after a teams run checks the process
  table; a live process after delivery is not proof of work. The
  troubleshooting wiki page follows.

## [0.131.0] — 2026-08-29

Re-init: none

Decisions 4.300–4.301 — task decomposition is re-founded for AI execution:
the governed unit becomes the smallest end-to-end verifiable behavior, seams
between tasks are only allowed on frozen contracts, and wave composition can
be refined between waves. Motivated by six recurring internal-boundary defect
batches and external research (MSR Sharp Tools, Anthropic C-compiler, OpenAI
Symphony, arXiv runtime decomposition, MSR E3, METR); validated on a desk
re-slicing of the real field plan before shipping (8 layer-cut tasks / 6 waves
→ 3 behaviors + 1 measurement, with every observed seam defect gone by
construction).

### Changed

- **Decomposition principles get a declared precedence** (`/keelson:tasks`,
  Step 1): behavior provable at its own closure > independence > size. The
  governed unit is the behavior; technical decomposition below it belongs to
  the developer at execution time, not to the plan.
- **Seams only on frozen contracts.** An interface both halves would still
  negotiate is never split across tasks — merge the halves or freeze the
  contract first (PLAN DEC, decided schema, external API). The former edge
  protocol (4.106/4.164) is explicitly rescoped to the unavoidable residual,
  by the maintainer's decision — the primary route is not creating the seam.
- **Vertical slicing hardened**: the behavior's entry point (route, command,
  screen) belongs to the task itself — a later "wiring task" is layer-cutting;
  a behavior larger than the size ceiling splits into smaller behaviors, never
  into technical slices.
- **Size semantics redefined without touching the enum**: `medium` = complete
  end-to-end behavior, ~2–8 h; the real ceiling is the developer's reliable
  execution horizon, not the context window. The estimate contract now points
  at the single owner and declares the calibration discontinuity.
- **Waves can be refined between waves** (`/keelson:implement` §3.6): with the
  facts of a closed wave, not-yet-started waves may be recomposed via the
  plan-gap rite; the wave total never changes and dispatched tasks are never
  re-sliced.
- **A measured TRISK no longer forces a sequential wave**: a TRISK with an
  unmeasured number becomes a measurement task (type `chore`) scheduled before
  the implementation tasks; once measured, the sequential-forcing condition no
  longer applies by itself.
- **Forced-sequential waves now leave a durable trace**: new `wave_sequencial`
  ledger event recording the forcing condition and its family (shared resource
  vs. dependency/risk) — the measurement series that decision 4.157 requires
  before any scheduler change.
- **Partial decomposition (`--only`) gets its missing caveat**: coverage
  errors for components outside the cut are the reported gap, not a blocker;
  every other error still blocks. The graph engine is untouched.

## [0.130.0] — 2026-08-29

Re-init: none

Decisions 4.297–4.299 — field evidence from a real consumer session (a resumed,
compacted cycle dispatched every role with an instance name, converting them into
teammates and losing the implicit return channel) turns the anonymous-dispatch
rule into a mechanical guard and makes the ownership guard teammate-aware.

### Added

- **The agent-guard now enforces anonymous role dispatch (4.293).** Spawning a
  cast agent (`keelson:*`) with an instance `name` is denied once, through the
  existing fingerprint valve: with Agent Teams enabled in the environment, a
  named subagent becomes a teammate and the role's implicit return disappears.
  The denial explains the fix (drop `name`) and the deliberate-teams route
  (`--force-mode=teams` → repeat the call and it passes). A missing or renamed
  payload field fails open — never a false positive. Ships with its own test
  suite, wired into the pre-commit hook and CI.
- **The wave guard recognizes descent (4.298).** A subagent or teammate used to
  read its own lead's run-state as "someone else's run" (literal session-id
  comparison) and burn turns proving non-action. The guard now walks its own
  PPID ancestry: a process invoked with `--parent-session-id <owner>` belongs to
  the owner's team, and that run silently leaves the check — per file, so the
  teammate's own runs are still enforced. A `ps` failure degrades to the current
  ownership warning, never to silence. Ships with its own test suite (the
  captured field sample became the fixture), wired into pre-commit and CI.

### Changed

- **Teams mode: the return instruction travels in the dispatch prompt (4.299).**
  An agent's "your final text is the return" contract evaporates on teammate
  conversion — in the field, three gates finished without ever calling
  `SendMessage`. The mode's owner doc now requires the lead to end every teams
  dispatch prompt with the literal order to report the contract YAML via
  `SendMessage` before going idle; an idle teammate without a report gets one
  follow-up through the same channel, and a still-silent role is declared
  unreported (a gate without a verdict is a gate that did not run — never
  invented). Files are not a return channel: temp-dir handoffs are unreliable
  under sandboxing (per-process overlay, observed in the field).
- The remaining ownership asymmetry (security/review guard nudges and the
  run-state writer still compare session ids literally) is declared with a
  reopening trigger, and the 4.295 hardening trigger is updated: invocation
  arguments now have a captured sample; PPID topology still does not.

## [0.129.0] — 2026-08-28

Re-init: none

Decisions 4.295–4.296 — the two teams-mode gaps declared in 4.294 now degrade
loudly instead of silently. The impact map reshaped the design: the signal is the
caller's orchestration enum, never an environment variable (which errs both ways),
and the untested hook stayed untouched.

### Added

- **The stale-background guard's advice covers teammates.** The guard's ownership
  attribution (PPID ancestry) cannot discriminate an Agent Teams teammate's
  process, which may show up as "yours" or "undetermined". The advisory text now
  instructs the case unconditionally — check live teammates before killing a PID;
  a teammate's process is ended by the teammate or the human, never by this
  report. Hardening is deferred until a real `ps` table from a teams session is
  captured and becomes a suite fixture. (4.295)
- **Per-role cost coverage is declared by the caller.** `context-cost.sh` gains a
  `--teams` flag (valid only with `--compose`): when the cycle ran in
  `AGENT_TEAMS`, the closing report's per-role ranking carries a `cobertura:`
  line stating it covers only Task dispatches — teammate work is outside the
  measurement. The flag comes from the invoker that knows the orchestration enum,
  never from an environment variable; the line only qualifies an existing
  ranking, never invents one. `/keelson:report` does not pass the flag (it cannot
  know the mode of a cycle it did not conduct). (4.296)

## [0.128.0] — 2026-08-28

Re-init: none

Decisions 4.292–4.294 — field report: with the experimental Agent Teams feature enabled
in the environment, a consumer session saw read-only roles converted into teammates,
concluded they "couldn't return anything" and proposed granting them Bash. This batch
makes the cycle deterministic under that flag and names the teams-mode return channel.

### Added

- **Teams-mode return channel named in the teams-mode owner.** A teammate has no
  implicit return to its caller: every dispatched role reports to the lead via
  `SendMessage`, carrying the same per-agent output contract — the transport changes,
  never the format. The harness injects `SendMessage` into teammates even with a
  read-only `tools:` list, so a missing tool is never a diagnosis for granting
  `Write`/`Edit`/`Bash` to an evaluator "so it can reply". (4.292)
- **Dispatch is by type, never by instance name.** With
  `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in the environment, a *named* subagent
  launches as a teammate in any interactive session — even without
  `--force-mode=teams`, and invisibly outside tmux (in-process display). Cycle roles
  are now dispatched anonymously (`subagent_type` only), so the env var alone never
  converts the cycle; teams stays opt-in via the flag. Headless (`-p`/Agent SDK)
  sessions never convert. (4.293)
- **The cycle runs in the lead session, never from inside a teammate.** Run-state
  ownership and the wave-guard belong to the conducting session, and the feature
  itself documents that in-process teammates cannot spawn background subagents. Two
  gaps in teams mode are declared without mitigation this batch (fixing the guards is
  its own batch): the stale-background guard and per-role telemetry may degrade —
  reports name the gap, never estimate it. (4.294)

## [0.127.0] — 2026-08-28

Re-init: none

Decisions 4.284–4.291 — nine field proposals absorbed from a consumer postmortem (a
full SDD cycle whose two escaped defects shared one signature: the proof shared its
premise with the target) plus two proposals from an earlier session that had never
reached the queue.

### Added

- **Two new contour-resistance tests at criterion fixation.** (f) A round-trip
  criterion (a channel one half writes and the other reads — cookie, token, session)
  never installs the primitive under proof in the test arrange: the arrange restores
  only the channel, and a MUST naming N subjects requires the mutant that dies per
  subject. (g) A requirement combining two predicates through a uniqueness
  comparative ("distinct from", "unique") names a literal-value or count assertion
  for the distinction predicate — "contains"/"not empty" proves only the other half:
  collapsing branches into one default, or swapping two values, stays green. (4.284)
- **Claims about an external system's payload shape require a captured sample.** In
  the SPEC, such a claim enters as fact only with a sample anchor (saved response,
  integration dump, gate-9 capture) — without one it is born `[assumido]`. In task
  generation, a fixture reproducing an external payload is checked against a real
  captured sample, never against the SPEC/PLAN prose describing it — otherwise
  generator and evaluator share the same belief and the gate turns green over the
  error. (4.285)
- **Coverage now also closes front-to-back.** An FR listed in "Realiza (FRs)" has its
  AC set derived from the SPEC text and checked against the wave's distribution —
  never enumerated from memory; a missing AC requires an explicit exclusion line. The
  existence check is already mechanical (`ac-sem-task`); what only the generator sees
  is the layer: a sibling task's mention counts only when its layer is the one
  enforcing the AC. (4.286)
- **Race-condition walkthrough steps target the call without a UI gate.** A
  single-trigger screen's out-of-order AC exercises the fire-and-forget call — never
  the primary call that the same task's loading guard already serializes, which makes
  a two-primary-calls script structurally unreachable. (4.287)
- **Cross-wave invariant handoffs declare their addressee.** Either `task criterion`
  (the next wave has the file/contract to satisfy it, and it enters the dispatch) or
  `reviewer measurement` (only the gate's own tooling produces the number; the result
  becomes a question for the Director, never a task rejection). (4.288)
- **Fixing a "reacted to the wrong trigger" state verifies the untouched axis too.**
  When the state depends on two independent axes, the re-gate's "what does this delta
  break?" includes pushing the axis the fix did not touch to its extreme — the space
  has two mirrored failure sides by construction. (4.289)
- **The review round presumes a standing anchor.** Every dispatched gate captures
  HEAD + status of the diff's files at its own start and re-checks before its
  verdict — divergence discards the verdict; and the orchestrator treats the SHA
  under review as frozen: no new commit enters the working tree while a verdict is in
  flight, or the gate is re-dispatched with the new anchor declared. The proposed
  sentinel + hook mechanism is deferred with a declared trigger. (4.290)
- **`verificado` in the behavior gate is derived from the task's own walkthrough.**
  Each scripted step gets a result (executed | inherited from a covering gate | n/a
  with reason) — evidence from another gate proves only the steps it covers; without
  the rest confronted, the value is `consolidado`. The task template's enum is now in
  sync with the report contract (placeholder written with angle brackets so the
  `task-done-gate-aberto` lint keeps its teeth). (4.291)

Re-init: none

Decisions 4.282/4.283 — last two absorptions from the consumer field batch: a
non-regression criterion written as "the test doesn't change" certified a broken
public message with a green suite, and the canonical pathspec commit silently undid a
partial stage, pulling a sibling task's hunks into the commit.

### Added

- **A non-regression criterion declares the complete observable value, never "the
  test doesn't change".** Freezing the test artifact freezes nothing: a fragment
  assertion stays green while the public value is rewritten. The criterion declares
  the complete value and proves it with the mutant (change the production value → the
  test goes red); and in a branch where the file was born, `git diff main...HEAD` is
  inert — the non-regression diff anchors on the commit that delivered the behavior.
  Refines the baseline rule in `/keelson:tasks`. (4.282)
- **Pathspec limit: same-file isolation uses the verified index.** `git commit --
  <file>` commits the working-tree state and undoes a partial stage (`git add -p`) —
  with two tasks in one file, the sibling's hunks come along. Primary route: don't
  share the file within a wave (sequencing is a decomposition decision). For the
  residual case, a narrow exception with a double pre-commit check, both in the
  report: `git diff --cached --stat` (no other file staged) + `git diff --cached --
  <file>` (staged = exactly your hunks), then commit without pathspec. Owner:
  `sdd-conventions.md`; the developer agent carries the half-line pointer. (4.283)

## [0.125.0] — 2026-08-27

Re-init: none

Decisions 4.278–4.281 — four gate-rule holes proven in the same consumer field batch:
a new refusal guard left its 4th caller as a production dead end, two correct
measurements of the same code diverged with no declared base composition, an
equivalence test stayed green for 6 waves because it ran on the neutral axis, and an
on-demand tweak almost inverted a default that was the first listed mitigation of a
live risk.

### Added

- **A change that starts refusing an existing operation closes by enumerating its
  real callers.** Trigger is the contract change (an operation that used to complete
  and now can refuse), never the mere presence of a guard: coverage derives from a
  grep for the callers (method/route/use case) — never the remembered screen list —
  and each caller declares its response to the refusal (handles and reoffers, passes
  explicit confirmation, or n/a), with a countable close (N callers, N declared
  responses). Extends the multi-subject block in `core/CODE-REVIEW.md`; explicitly
  demarcated from SECURITY's "guard at the sink" (writers of sensitive data vs.
  callers of a refusable operation). (4.278)
- **Cost measurement declares the base composition, not just volume.** With
  short-circuit branches, cost depends on data distribution: declare N per entity and
  the proportion that decides the branches, and measure the case that does NOT
  short-circuit. Qualifies the cited measurement in the gate-10 rulebook
  (`core/PERFORMANCE.md`, complement to 4.178) — never a benchmark requirement;
  "by inspection" stays a legitimate outcome. (4.279)
- **Equivalence between two calculation paths is proven on the non-neutral axis.**
  The test lives in the dimension where the distinguishing factor is non-neutral
  (fraction ≠ 1, weight ≠ 1); the neutral dimension is the control. The axis choice is
  proven by mutation at fixation: neutralizing the factor at the source must fail the
  test. New bullet in `core/TESTING.md` "assertions that prove". (4.280)
- **The on-demand route confronts a changed default with the slug's living
  artifacts.** A value cited as a RISK/TRISK mitigation is a control, not a UX
  preference: changing it is a SPEC revision (FR/AC/RISK updated in the same commit,
  residual risk signed off), never a screen tweak — and "nobody uses the option" is
  usually salience, fixed by perception with zero risk. New falsifiable rule in the
  standalone-brief contract; the injected block is unchanged. (4.281)

### Fixed

- `core/CODE-REVIEW.md` debt line now points at its owner: debt lives in a source
  artifact (brief/PLAN) mirrored into the INDEX by regeneration (4.179), never
  INDEX-only. The `code-reviewer` header counted "9 quality gates" and named only
  gates 8–9 as delegated — corrected to 11 and 8–11 (post-4.155/4.218 sediment).

## [0.124.0] — 2026-08-27

Re-init: none

Decisions 4.276/4.277 — a consumer's lessons ledger surfaced two holes in the behavior
gate, both proven in the field: screen verification ran while a developer was still
writing to the same tree (every "verified" item reflected an instant, not a commit),
and a UI bugfix passed verification with Tab while the reported bug lived in the mouse
click — the gesture divergence *was* the bug.

### Added

- **Behavior gate runs on frozen code — stability joins identity.** The code-identity
  rule (decision 4.30) proves the process serves the right copy; nothing covered the
  same copy being **written during** the exercise. The `qa` agent and the screen-verify
  skill now capture `git rev-parse HEAD` + `git status --porcelain` (at the exercise
  root) when the functional exercise starts and again when it ends: a change appearing
  **during** the exercise in a file under verification is concurrent work — the gate
  stops and reports PARCIAL with both captures as evidence, never a green of the
  moment. Pre-existing state — the shared wave tree, the uncommitted diff of an
  on-demand change — is the declared baseline, never a finding. (4.276)
- **Repro and screen verification use the user's literal gesture.** When the AC, the
  report or the symptom names a gesture (click, Tab/blur, theme toggle), that literal
  gesture is what proves; the sibling gesture joins only when the event path diverges
  per gesture or the AC equates them — a trigger, never a catalog. Forced state (an
  injected CSS class, a script-set value) never replaces the real UI mechanism.
  Applied to the bugfix red-repro rule (`/keelson:tasks`) and the `qa` functional
  exercise. (4.277)

## [0.123.0] — 2026-08-27

Re-init: none

Decision 4.275 — every forge run (specify → plan → tasks) seemed to end with a round of
review fixes, but the impression was not measurable: keelson tracked duration, tokens
per role and human interventions, yet nothing counted artifact-correction rounds or
aggregated validator findings by class. Without those two numbers, changing the writing
commands would be guesswork — the house rule is measure first, mechanize on recurrence.

### Added

- **Forge telemetry: correction rounds and finding classes become measured numbers.**
  Validator reports now aggregate errors and warnings by check id (new `Classes:` line
  in the report summary — a transcription input, never a trigger); the BRIEF's
  `Cronologia` line for each forge stage carries a measured tail
  (`correções: N · classes: …`) with the timestamp kept as the first field, so the
  duration line and the Jira worklog window keep reading the same mark; and the closing
  report gains a conditional `Forja` line transcribed from it. Telemetry rules apply:
  measured or omitted, never estimated — and never a trigger: the number exists so the
  maintainer can distill recurring finding classes into writing criteria, never to stop
  or reroute a cycle. Writing-side mechanisms (pre-dispatch lint, lessons feeding
  SPEC/PLAN writers, a countable scribe self-check) stay deferred until measured forges
  show a recurring class.

## [0.122.0] — 2026-08-27

Re-init: none

Decision 4.274 — the postmortem command produced valuable analysis but its trigger was
100% pull and human-only: nothing in the flow ever suggested running it, so users who
don't know or forget the command simply lose the analysis (and the durable `PM-*.md`
file the maintainer could harvest from the consumer repo even without a hand-off).

### Added

- **The closing report suggests `/keelson:postmortem` when the session had
  difficulties.** A new conditional line in the canonical closing-report skeleton
  (`report-contract.md` §2) appears only when the session saw retries, failed gates or
  human corrections, names those signals, and asks the human to type the command —
  healthy sessions never see the line, and it never invokes the command itself (it is
  human-only). The trigger is the Tech Lead's judgment of the session it lived, never a
  parser over the ledger; coverage is declared partial by design. Reaches
  `/keelson:auto`, the on-demand mode and `/keelson:report`; the standalone
  `/keelson:implement` report template and the consumer block's minimal close stay out,
  declared.

### Fixed

- **The `ledger.sh` usage header lists `intervencao` again** — the header's type
  catalogue had drifted from the enforced enum since the type was added; the runtime
  check was always correct.

## [0.121.1] — 2026-08-27

Re-init: none

Decision 4.273 — final triage of the PR #2 / benchmark queue: four cheap, real fixes
applied (proposed by an external contributor in PR #2, credited), three proposals
declined with a documented reopening trigger.

### Fixed

- **Validator skill descriptions no longer carry an unresolved config token.** The
  `{docsRoot}` placeholder sat in the frontmatter description — where the harness never
  interpolates and which drives skill activation. Removed from the three validators;
  descriptions now also fit under the 250-char cap the harness enforces on listing.
- **Every hook declares an explicit 30s timeout.** The harness default is 600s per
  command hook and the Stop event chains 8 scripts, so one hung hook could hold session
  shutdown for 10 minutes. The constant is measurement-backed: worst hook measures 0.12s
  on the fallback path.
- **The developer reads from the briefing first.** TASK/PLAN/SPEC load by section, only
  for what the briefing does not cover (the existing load rule now reaches the agent);
  a full read is the declared exception when the briefing is not enough. Field data
  showed 126 turns with 10 full re-reads on a 6-file diff.
- **Plugin manifests carry the metadata the plugin browser renders** — `author.url` and
  the marketplace entry `category`, both verified against the official plugin docs
  before entering.

## [0.121.0] — 2026-08-27

Re-init: required

Decision 4.272 — the top-priority gap from a consumer's three-arm benchmark: changing
an agent's model tier required forking the plugin, since `model:` lives only in agent
frontmatter that `/keelson:update` overwrites. Proposed and implemented by an external
contributor in PR #3, merged preserving authorship, with maintainer fixes on top in
the same batch.

### Added

- **Optional `models` block in the ficha: per-agent model tier, born with its reader.**
  `keelson.config.json` gains `"models": {}`, mapping an agent's `name:` (no `keelson:`
  prefix) to a harness model alias (e.g. `opus`, `sonnet`, `haiku` — the valid set
  belongs to the harness). Dispatch rule with a single owner in `sdd-conventions.md`,
  cited by the injected block and the implement/review/merge/auto commands: every spawn
  reads `bash "…/scripts/ficha.sh" <root> --get models.<agent>` and passes a non-empty
  result as the spawn's `model:`; an empty result — or an absent/unreadable ficha —
  dispatches without `model:` and the agent's frontmatter holds (4.70: downgrading an
  evaluator is a declared project decision, never a dispatcher's guess). `/keelson:init`
  lists the block in Etapa 4 and leaves it `{}` unless the human asks for a deviation.
- **The init self-check proves the block.** New conditional `models-validos` item: a key
  that names no agent of the installed package is a failure; an alias outside the known
  set degrades to a warning (a newer harness tier may exist). Three new self-check suite
  cases prove ok/failure/warning; the ficha suite proves the read, the hyphenated key
  and the absent-key path.

### Fixed

- **The wiki no longer misstates the model defaults.** The new `models` section claimed
  "generators on sonnet, evaluators on opus" — `qa` is an evaluator on sonnet. The
  default is each agent's own frontmatter; the false classification is gone and the
  section moved to match its position in the example JSON.

## [0.120.1] — 2026-08-27

Re-init: none

Decision 4.271 — a consumer's close-out postmortem reported three misfires of the same
kind with the stale-background guard: the nudge offers one cheap signal for a binary
decision (working vs. stuck, mine vs. someone else's) and did not warn when that signal
fails to discriminate the hard case. Detection criteria and ownership attribution
(4.206) are untouched — only the advice text changed.

### Changed

- **The stale-background guard's advice now covers the cases its signal cannot decide.**
  Three fixes to the nudge text: the "is it really working?" bullet states that
  Task-dispatched subagents are outside the growing-output heuristic — their output file
  mirrors the transcript, not an incremental stream, so a flat size proves nothing; proof
  there is effect on the target or the harness notification (a healthy gate had been
  killed over this). The "indeterminate owner" verdict now instructs the discriminator
  that exists — check the process cwd against this session's scratchpad UUID (portable
  command per platform) before treating the process as yours; an orphaned PPID chain
  neither proves nor rules out ownership. And "kill it" now names the whole process
  tree: descendants do not carry the shell mark, so they survive the parent invisibly to
  future sweeps — confirm by a fresh process list, never by the freed port alone.

## [0.120.0] — 2026-08-26

Re-init: none

Decisions 4.264–4.266 — correctness batch from a consumer's instrumented three-arm
benchmark over the same work item (field report absorbed via the maintainer inbox):
gate 8 approved the same code one arm rejected, a headless init returned with the
profile agent still running, and `gates.review: false` did not do what the docs said.

### Added

- **Gate 8 approvals now carry a countable inventory.** An APROVADO with no findings
  must enumerate, in the new `conferido` field of the security report, each checklist
  category applicable to the round's diff with the surface actually checked
  (`file:line` or a count) — scoped to the diff, never the whole repository. A blanket
  "no vulnerabilities" report is invalid and the cycle rejects it. The rule lives in
  `guidelines/core/SECURITY.md` (which the `security-engineer` already reads at
  runtime); the inventory is a fact that accompanies the verdict, never a number that
  decides it (4.264).

### Fixed

- **`/keelson:init` can no longer finish with a ghost profile.** The `staff-engineer`
  invocation is blocking by contract: the profile path only enters the ficha after the
  file provably exists on disk (`test -f`), and the report now opens with an adoption
  verdict — `Adoção: completa` only when the self-check has no failure; otherwise
  `incompleta` with the exact pending action. A declined profile generation is a
  declared state, not a failure (4.265).
- **Docs no longer claim `gates.review` disables the cycle's code review.** The key
  (and `gates.reviewThreshold`) only parametrize the out-of-cycle Stop-hook nudge
  (`review-guard`); gates 1–7 always run in the cycle. The ficha wiki page, the init's
  gate list and the troubleshooting page now say so; behavior is unchanged and the
  ficha template was deliberately left untouched (4.266).

## [0.119.0] — 2026-08-26

Re-init: required

Decision 4.263 — first external contribution by pull request (PR #1, by Tiego
Torelli): the command was proposed against 0.114.0 and could not be merged (decision/
version/section collisions with the current main, plus execution defects), so this
batch re-implements the approved design from the current main with corrections,
crediting the proposal. It closes the gap decision 4.235 left open: the
semantic-reconciliation rule existed, but had no executor.

### Added

- **`/keelson:merge` — merge one or more branches into the current working branch,
  one merge commit per branch.** New human-only command that processes branches in
  sequence: for each one, runs the textual-conflict dry-run (`git merge-tree
  --write-tree`, reusing the 4.74 mechanism; the git < 2.38 fallback always aborts the
  trial merge, including on conflict), the mandatory semantic reconciliation (reusing
  the 4.235 rule — symbols diverging between the parents plus new consumers on the
  other side, even without a textual conflict) and the project suite over the staged
  merge. A clean branch (no conflict, no reconciliation finding, green suite) closes
  its merge commit directly, with no agent dispatched; a conflict, reconciliation
  finding or broken test dispatches the `developer` scoped to just the triggered
  files (standalone mode, no commit) and the `code-reviewer` audits only that
  resolution's diff (gates 1–7, plus gate 8 via `security-engineer` on sensitive
  areas) — never the whole branch diff. Only then does that branch's own merge commit
  close before the next branch starts. A failing suite or gate after one retry aborts
  that branch's merge and stops the queue there — already-merged branches keep their
  commits, the rest are never attempted, and the final output always declares the
  exact working-tree state (including `MERGE_HEAD`). This is a declared exception to
  "no command merges" in `docs/_meta/conventions/sdd-conventions.md`: push, merging
  into the remote main branch, PR and deploy remain exclusively human.

### Changed

- `docs/_meta/conventions/commit-convention.md` now declares the two-parent merge
  commit exception (standard git format, no `type(scope)` prefix) — the rule owner,
  not the new command, carries it; the pathspec-commit rule (4.163) in
  `sdd-conventions.md` gained the matching exception (git refuses a partial commit
  during a merge).
- `developer`, `code-reviewer` and `security-engineer` agent descriptions list
  `/keelson:merge` as an invoker; the injected CLAUDE block gained the human-only
  command's note (hence `Re-init: required`).
- Every remaining statement of the human-merge boundary was aligned with the declared
  exception: `guidelines/core/WORKFLOW.md` (the rule's embedded second owner, read at
  runtime), the injected block's cycle bullet, the method guide's §5 intro and the
  wiki's own pages (FAQ, epic flow, concepts, first steps, home) now scope the human
  act to "merge into the main branch" — a stale copy of the old absolute rule could
  make an agent refuse the new command.

## [0.118.0] — 2026-08-26

Re-init: none

Decision 4.262 — Director's raw idea refined via idea-forge: real adoptions start with
`jira.enabled: false`, and turning Jira on later had no discoverable door short of
re-running the whole init; a board whose types or workflow changed kept dead IDs,
because merge-preserving preserves instead of re-measuring.

### Added

- **`/keelson:init jira` — scoped run for the Jira integration**: with an existing
  ficha, runs only the Jira step (guided discovery of types, workflow and map
  scaffolding, all by ID) plus the Jira slice of the self-check — no stack detection,
  no profile resolution. Without the argument nothing changes; without a ficha it
  stops cleanly and points to the full init. The scope is a human door: commands that
  find an incomplete ficha mid-cycle keep using incremental config, never the init.
- **Re-measure mode**: when the `jira` block is already configured, the scoped run
  re-discovers types and workflow on the live board and compares them with what is
  stored — dead type/status IDs, new statuses missing from the board rail, reordered
  workflows surface as report warnings and commented map suggestions. Nothing is
  overwritten: the ficha stays authoritative and the human confirms every change.

### Changed

- `/keelson:jira-sync` with the integration disabled now points to `/keelson:init
  jira` as the way to enable it.
- The method guide gained the init's own section (§3.25) — it was the only command
  without one — so the mirrored wiki now documents the command and its new scope.
- README (Commands table and Jira section) and the wiki's FAQ, troubleshooting
  ("the board changed") and ficha reference document the new door.

## [0.117.1] — 2026-08-26

Re-init: none

Decision 4.260 — Director's concern after the 4.254 batch, refined via idea-forge: the
existing per-engine suites are synthetic-minimal by design, so regressions in
real-world artifact *shapes* passed green and only surfaced in the field.

### Added

- **Regression corpus for the mechanical engines** (`scripts/tests/corpus/`,
  maintainer tooling): a single realistic synthetic slug (SPEC with FEATs/NFRs and
  multi-line ACs, PLAN with DECs, 7 TASKs covering feature/bugfix/refactor/chore/
  transversal, an AC cited only on a continuation line, legacy parenthetical
  annotations, filled closures, a gate-9 script, coherent INDEXes) with the output of
  every read-only engine frozen (`graph.sh --check`/`--tsv`, `artifact-lint.sh`,
  `index-check.sh`). Runs on pre-commit whenever a covered engine or the corpus
  changes, and always in CI. Origin proof: the pre-4.254 engines fail this suite.
- **Written rule: a fixed engine bug is born with a fixture reproducing it plus a
  positive control** (the pre-fix engine must fail on it) — sibling of "a new check
  ships with a fixture", owned by `lint-contract.md` with a pointer in
  `graph-contract.md` §6. An expected-output diff in a batch requires justification in
  the decision — blind re-freezing is the named anti-pattern.

## [0.117.0] — 2026-08-26

Re-init: none

Decisions 4.254–4.259 — maintainer message from a consumer running 0.115.1 (ledger
LRN-070–075; classes LRN-031 and LRN-048 at recurrence 2): three parser bugs confirmed
by direct reading in this repo, plus five doctrine gaps from the same cycle. All eight
were registered in the proposal inbox before the verdict (4.111) and closed in this
batch.

### Fixed

- **AC cited on a continuation line now counts as coverage** (4.254). The TASK parser
  in `scripts/graph.sh` only extracted ACs from `- [ ]` lines in "Critérios de pronto",
  while the gate-9 section already scanned every line — an AC cited on the second line
  of a multi-line item produced a false `ac-sem-task` and a wrong owner in the INDEX.
  Both sections now scan every line; `artifact-lint.sh` (via the full-section
  accumulator) and `edge-diff.sh` mirror the same anchor, so the three parsers read the
  same universe. `graph-contract.md` and the canonical edge syntax in
  `commands/tasks.md` were rewritten accordingly.
- **`task-criterio-sem-ac` requires a well-formed AC ID** (4.254). The check used a
  loose `AC-` substring, so a criterion containing that literal inside a regex (e.g. a
  ban on SDD IDs) satisfied it without citing any AC. New fixture proves the false
  negative.
- **`NFR-…` no longer counts as `FR-…` in coverage cross-checks** (4.254). The FR
  extraction behind `plan-overlap-fr`/`task-overlap-fr` had no left boundary, so an NFR
  in `Realiza (FRs)` or in the covered list produced spurious overlaps (6 in the field
  case). Left boundary added at all three extraction points, proven by planted fixtures
  plus a positive control with the old code.

### Changed

- **Grep anchors must exclude comments to absolve** (4.255, recurrence 2 of the 4.161
  class). `\b`/`::`/`->`/`class `/`function ` bound the symbol but still match it inside
  a docblock, leaving the warning inert exactly where it mattered; now only
  `Reflection`, explicit exclusion (`-v`) and start-of-line-anchored patterns absolve
  `task-criterio-grep-nao-ancorado`. The doctrine in `commands/tasks.md` item (b) —
  which used to prescribe those anchors — and the suite's valid fixture moved to the
  new canonical form. Severity unchanged (WARNING; the task-validator still escalates).
- **Absence criteria run against the parent commit at fixation** (4.256). A criterion
  whose expected output is empty/0 must also run against the parent: non-empty output
  there means the ban is broader than the TASK's scope — a broken criterion, never
  inherited code to delete (field case: a "no SDD IDs" criterion born red against 10
  legitimate anchors per file later cost a legitimate new anchor).
- **Criterion×PLAN contradiction is now a validator ERROR** (4.257, recurrence 2 of the
  contradiction family 4.162/4.215/4.233 — 4th form). A criterion banning what the
  parent PLAN prescribes is checked by the `task-validator` (which holds the PLAN in
  context); an awk lint fact was declared unmechanizable (no canonical literal pair;
  textual semantic parsing is the 4.227 anti-pattern).
- **Requirements added to an in-flight TASK are born with criteria** (4.258). The
  generation rule "an Inclui item without a criterion is an item without proof" now
  explicitly reaches scope mutations during execution: the same Edit that adds the
  requirement adds its executable criterion (`commands/implement.md` §3.2).
- **Closure edits are anchored and must preserve committed headings** (4.259). §3.4.2
  item 1 now prescribes template-anchored Edits (never wide block replacement) plus an
  immediate `git diff` check: a removed heading line is a defect of the edit, to revert
  and redo (field case: a block substitution ate Escopo/Critérios/gate-9 sections of 7
  TASKs, 255→45 lines, unnoticed for 4 waves). The inline closure in
  `commands/auto.md` points at the same rule.

## [0.116.0] — 2026-08-25

Re-init: none

Decision 4.253 — field report from the Director (consumer sessions): duplicated logic
surviving multi-commit deliveries (a whole story). Same class as 4.207, which
operationalized the reuse search per wave but deliberately left the closing convergence
untouched; consumer version not yet confirmed, so the recurrence ladder does not advance —
the batch ships as a structural safety net by explicit Director decision.

### Added

- **Delivery-wide dedup pass in the closing convergence**. The `code-reviewer` in
  convergence mode now also applies gate 7's reuse surface (b) to the whole delivery:
  near-equivalent symbols/files **created** on the branch, compared against each other and
  against the documented canon. A duplication finding is never a gap and never blocks the
  close — it becomes a consolidation pendency with anchors on both sides, routed like
  `fora_de_escopo` (consolidation is new diff going forward; approved stays approved), and
  findings already routed by a wave do not reappear. The INDEX seal now carries the
  component (`dedup: aplicada | n/a — sem base`); a legacy seal without the marker only
  covers the SPEC component, so `/keelson:integrate` still runs the dedup pass when
  reusing it. Formal cycle with SPEC only; outside it, `/keelson:review` over the branch
  diff remains the manual lever. (`guidelines/core/CODE-REVIEW.md` ·
  `agents/code-reviewer.md` · `commands/auto.md` · `commands/integrate.md` · wiki
  `Conceitos`)

## [0.115.1] — 2026-08-25

Re-init: none

Decision 4.252 — closes the deferred item (i) of 4.251, triggered by the Director in the
same batch.

### Fixed

- **A third party's cycle no longer silences the free session's safety net**. The
  `review-guard` and `security-guard` stop hooks used to short-circuit on ANY in-progress
  run state; with parallel sessions on one checkout, session A's cycle muted session B's
  review/security nudges. The short-circuit now applies only when the run belongs to the
  reading session (`sessao:` equals the payload's `session_id`); unknown owner, legacy
  format or missing `session_id` keep the previous silence — a nudge is never reactivated
  on doubt. Proven by 8 synthetic scenarios with a positive control (no run → both nudge).

## [0.115.0] — 2026-08-25

Re-init: none

Decision 4.251 — field case, 4th manifestation of the same class in the consumer's ledger:
with several keelson sessions running in parallel on the same checkout, the wave guard
blocked one session's turn citing **another live session's** run state, and both offered
exits (continue / mark closed) were destructive — enter a third party's worktree, or erase
a live session's checkpoint mid-TASK. Run-state ownership is now modeled end to end.

### Added

- **`sessao:` field in the run-state canonical format** (owner: `sdd-conventions.md`,
  "Estado de run"). Written by `run-state.sh` from `RUN_STATE_SESSAO`, else
  `CLAUDE_CODE_SESSION_ID` (the same UUID hooks receive as `session_id` in their payload
  — one id space on both ends), else the honest `desconhecida`.
- **Third exit in the wave guard**: when a run's `sessao:` points at another session, the
  block message stops offering continue/close and instructs instead — do not touch the
  file, inventory (run-state mtime, `git status` of the worktree in `retomada:`, live peer
  sessions) and escalate to the human. The "no stamina-based stops" rule gains the
  ownership caveat in its owner (`commands/auto.md`) and in the degraded message path.
- **Writer-side refusal**: `run-state.sh init`/`wave-done`/`close`/`remove` exit 2 on an
  in-progress run owned by a different session when both ids are known; any unknown side
  degrades to the previous warning behavior (never a blind block); `FORCE=1` takes
  ownership deliberately. Suite grown to 23 cases with a session-controlled environment.

### Changed

- **`compact-anchor` mirrors `sessao:`** and conditions its resume instruction: a run
  owned by another session is inventoried and escalated, never resumed — closing the
  post-compaction side door to the same destructive exit.
- **Wave-guard nudge window is now per reading session** (fingerprint composed with the
  reader's `session_id`): session A's nudge no longer swallows the one owed to session B
  over the same run. Known one-time effect: each active run re-nudges once right after
  this update.
- **Wiki (Solução de problemas)**: new section — the block cites a cycle that is not this
  session's — explaining the third exit and that taking over an orphaned run is always a
  deliberate act.

---

## [0.114.0] — 2026-08-24

Re-init: none

Decisions 4.249/4.250 — field case: a consumer proposed "anchor-only comments" and the
three real examples behind the proposal turned out to violate the current rule (process
narrative shipped in comments, one docblock larger than the code it explained). The
proposal was declined — the defect was enforcement, not the rule — and the batch closes
the two enforcement leaks it exposed.

### Changed

- **A suggested comment removal never dies in the report** (4.249). It still never opens
  a review round and never counts as a failure — but now it is always applied before
  delivery: with a retry open for another finding it rides along (unchanged); without
  one, the closing route of each mode applies it (cycle: one dispatch per wave at wave
  end; standalone review: the existing correction batch; on-demand: the same round).
  Application cuts exactly the listed `file:line` items — never a self-directed sweep,
  never a rewrite — with a one-line contestation as a legitimate outcome and the count
  (`N suggested → N applied / N contested`) declared in the wave bulletin.
- **The Art. 7 comment test now closes countably at both points where it runs** (4.250).
  The gate-7 report carries an inventory of comments the diff introduces/alters
  (`comentarios_diff`: N, and the axis of each rejected one — provenance narrative,
  temporal comparison, paraphrase/ritual, block larger than the code), always a
  reviewer-judged fact that never flips the gate status by itself; the developer report
  declares `autocheck_comentarios` (introduced · removed by the autocheck). No textual
  parser of code is involved — the anti-pattern stays banned.
- **Wiki (Conceitos)**: one plain-language sentence — a comment that fails review is
  removed before delivery, without an extra review round.

---

## [0.113.1] — 2026-08-24

Re-init: required

Decision 4.247 — wording fix on the day-old 4.246 lever, before any field round:
"applies in a free session" could be read by a session that just ran `/keelson:auto`
as "this session is not free", silently disabling the lever in its most common
scenario — final adjustments right after a cycle delivers. That misreading risk was
hypothesis 2 of the 4.246 impact map; it materialized as a Director question the
same day. Re-init required: the injected block changed.

### Changed

- **The lever's scope now names the post-cycle case** (4.247). The injected block and
  the method-guide mirror say the declaration applies *outside a running command —
  including right after a cycle delivers in the same session, when the session is
  free again*. While a command runs, nothing changes (its contract still governs,
  4.129).
- **FAQ explains the post-`auto` scenario in plain language** (4.247): a new entry
  ("I finished a `/keelson:auto` and just want some final tweaks — will I fall into
  the cycle again?") aimed at readers new to keelson, with a mermaid flow diagram
  (rendered by the GitHub wiki) showing when a request goes through the running
  cycle, the on-demand door, or promotion with a stated reason.
- **Own wiki pages now have an authoring rule** (4.247, maintainer-side): the target
  reader is someone who started using keelson recently — simple language, no internal
  vocabulary, and a mermaid diagram alongside the text when a flow or branching
  decision benefits from one. Mirrors keep their owners' text untouched.

---

## [0.113.0] — 2026-08-24

Re-init: required

Decision 4.246 — field feedback from a consumer: "I ask for a simple adjustment
mid-development and the system spins up SPEC, plan and tasks; I just wanted a free
mode to ask for something direct." The capability already existed (on-demand mode,
4.75/4.86; direct-action routing; the trivial test, 4.205) — what was missing was a
lever the Director could pull and discover: routing was the model's silent judgment.
Re-init required: the injected block changed.

### Added

- **Declared punctual intent picks the door** (4.246). When the Director states the
  intent alongside the request in natural language ("quick fix", "no cycle", "direct
  change" — examples, not rigid keywords), the session enters on-demand mode by
  default instead of re-judging the route. The declaration picks the *door*, never
  waives the *promotion*: the existing falsifiable rule (changed promise, technical
  decision between alternatives, the layer-boundary test) still promotes to the full
  cycle — and the promotion is always announced with its reason before proceeding,
  never decided silently. Scope: free sessions — invoking a `/keelson:*` command
  remains the explicit request for that command's contract (4.129), so `/keelson:auto`
  still runs the cycle. Rule owner: the injected block's on-demand bullet; the
  method guide §5 mirror was updated in the same batch.
- **Wiki teaches the lever**: a new FAQ entry ("I asked for a simple adjustment and
  keelson opened a SPEC — how do I avoid that?") separates the two axes (size never
  decides the route; declared intent picks the default door), and Getting-started /
  Concepts carry the phrases.

---

## [0.112.0] — 2026-08-22

Re-init: none

Decision 4.245 — the Director asked how to cut comment volume in generated code
without losing effectiveness. The rule (Charter Art. 7 delete test, floor and
ceiling) was already right; what leaked was *where* it ran — the developer's
pre-report self-check covered only narrative comments, and a gate-7 "suggested
removal" had no consumer in the implement loop, so it died in the review report.
Constraint honoured: no new step, no new round, no loop. Injected block and ficha
contract untouched.

### Changed

- **Developer self-check now runs the full Art. 7 delete test** (4.245). Before every
  report, the developer re-reads each comment it introduced and asks whether deleting
  it loses information the code does not give back: no → delete it (paraphrase,
  signature repeated in prose, ritual file header, docblock restating a native type);
  yes → it stays (DEC/FR anchor, workaround with its removal condition, invariant,
  path already tried). The floor travels in the same sentence as the ceiling, so the
  check cannot over-delete. Previously the self-check caught only narrative comments
  (provenance, temporal comparison — 4.135/4.185).
- **Gate-7 "suggested removal" rides along, never opens a round** (4.245). A comment
  the reviewer flags as redundant is still a suggestion, never a failure — and now it
  has a destination: when the originating TASK goes to retry because of *another*
  finding, the suggested removals join the retry dispatch and the developer applies
  them with the fix (inert delta, same-reviewer re-check, 4.88). Without a retry it
  stays a suggestion in the report. Rule owner: `core/CODE-REVIEW.md` severity
  calibration; `/keelson:implement` references it; the `code-reviewer` report
  template says so in a one-line comment on `acoes_sugeridas`.
- **Profile outline §3 gains a concrete anchor for ritual comments** (4.245). Generated
  profiles are told what "ritual" means in a typed language — a docstring/JSDoc/docblock
  that repeats an already-typed signature — and what still carries information
  (collection shape, generics for the static analyser, exceptions the caller handles).
  Applies to profiles the `staff-engineer` generates; embedded PHP profiles already
  state it.

---

## [0.111.0] — 2026-08-21

Re-init: none

Decisions 4.241–4.244 — batch motivated by the Director's analysis of the AI-native
SDLC landscape: the four gaps between what the article describes and what keelson
already does, applied within keelson's scope (up to the PR). Injected block and ficha
contract untouched.

### Added

- **Plans now consult other slugs' irreversible decisions** (4.241). `/keelson:plan`'s
  context step sweeps the `## Decisões irreversíveis` block of every other slug's
  INDEX (heading-only extraction; absence declared per slug, never silence). A foreign
  irreversible DEC never halts the flow: a conflict becomes a citation + justification
  in the PLAN's new §Aderência field, cited by path and in prose only — never as a
  graph edge. The scribe package carries the extracted list inline.
- **Project invariants file** (4.242). New opt-in consumer artifact
  `guidelines/project/invariants.md` — product/architecture restrictions that must
  hold in any demand and were never born from a PLAN. Rule owner:
  `guidelines/core/ARCHITECTURE.md` (falsifiable one-bullet format; the Director
  writes it, keelson reads it). Read conditionally by `/keelson:plan` (a design that
  violates one halts and reports) and by review gate 6 (absent file → declared `n/a`,
  never silent approval).
- **Maturity snapshot in the `/keelson:init` report** (4.243). A literal skeleton
  block states, per assurance layer (test, lint, boot, screen, e2e, mutation,
  invariants), what its absence means for the autonomy the Director grants. Every
  line is anchored in a read ficha field or self-check line (`não medido` otherwise);
  informational only — opt-ins stay opt-ins, nothing blocks.
- **Human interventions are now a counted report line** (4.244). The session ledger's
  closed catalog gains the `intervencao` event type (an effective Director response
  mid-cycle: a veto, an answered escalation, a returned handoff — `decisao` events,
  autonomy exercised on the Director's behalf, never count). `ledger.sh` validates the
  type (regression suite extended, 12 green cases) and the closure report skeleton
  gains a mandatory `**Intervenções humanas**` line composed from `ledger.sh count`
  before archiving, with its degradation prescribed inline.

## [0.110.0] — 2026-08-20

Re-init: none

Decision 4.240 — field report from a consumer session: a new page built "from the
legacy queries" shipped a user-facing domain term chosen between competing synonyms
with no DEC, no question to the Director and no artifact line — the agent's own root
cause: an incomplete legacy reading that became a promise. First occurrence of the
class at the terminology surface (family 4.58/4.238, "verified, not deduced").
Injected block and ficha contract untouched.

### Added

- **Inherited domain terms carry provenance** (4.240). When a demand is based on a
  legacy artifact (code, queries, screens), `/keelson:specify`'s Ubiquitous Language
  principle now requires each user-facing domain term to enter the glossary with the
  anchor of the source that uses it (`file:line` or query identifier); a term the
  source does not decide — competing synonyms, partial reading — is a product choice
  and becomes a §8 premise (`[confirmar]` within the 4.144 budget, or `[assumido]`
  with the chosen default declared), never a silent model default. Falsifiable test:
  "who chose this word?" is answered by an anchor or a premise — "nobody" is the
  defect. Mechanical check deferred with the 4.149 ladder (recurrence promotes it to
  the spec-validator).

## [0.109.0] — 2026-08-20

Re-init: none

Decision 4.239 — context-cost observability requested by the Director (high token
consumption reported by consumers, with quality explicitly non-negotiable). The
closure report gains a measured per-role token ranking; an external lossy-compression
proxy was evaluated and refused (compressed diffs/logs corrupt the literal evidence
the gates consume). Injected block and ficha contract untouched.

### Added

- **Context cost per role in the closure report** (4.239, extending 4.148). The
  `window-marker` Stop hook now also extracts one `agente=<type> tokens=<N>` line per
  completed subagent from the transcript **delta** since the last Stop (offset file
  `thoughts/local/.window-offset.<cksum>`; unparseable lines are silently skipped —
  telemetry degrades, never invents). The new read-only `scripts/context-cost.sh`
  composes the log into peak window + a descending per-role ranking (regression suite
  `scripts/tests/context-cost/`, registered in pre-commit and CI). The report
  contract gains the **Custo por papel** line — measured or omitted, never estimated —
  and `/keelson:auto`'s Delivery fills it from the script's literal output (item 6.5).
  Cost is never a stop trigger (4.23/4.24): the number exists to aim future
  context-diet work, not to change cycle behavior.
- **OTEL note in `/keelson:init`'s report** (4.239). The init report now mentions the
  Claude Code OTEL export (`CLAUDE_CODE_ENABLE_TELEMETRY=1` + OTLP endpoint) for
  consumers who want exact per-model token/cost numbers. Informational only — keelson
  never writes harness config; enabling it is the Director's act.

### Changed

- The ledger-closing step of `/keelson:auto` (item 10) still moves
  `session-window.log` to `reported-*/`, and now explicitly **keeps** the
  `.window-offset.*` file — it is a read pointer, not a measurement; deleting it
  would repopulate the fresh log with already-reported agents.

## [0.108.0] — 2026-08-19

Re-init: none

Decisions 4.235–4.238 — field batch from a consumer handoff review requested by the
Director: four lessons abstracted from real incidents (semantic merge defects, a
credential echoed by `source .env`, a stale pending list, an unverified conflict
claim) become doctrine. Injected block and ficha contract untouched.

### Added

- **A clean merge is not a correct merge** (4.235). Whenever two lines of work
  reconverge (slice boundary syncing with main, sibling slice branches chaining,
  integrated worktrees), the doctrine now requires listing the constants/sentinels
  whose values differ between the parents and sweeping the other side's new consumers
  before trusting the result — 3-way merge resolves by line, never by meaning (field
  case: 4 defects that only existed in the merge of individually green slices). The
  merge result is a new diff that runs the suite and the boundary gates. Owner:
  `sdd-conventions.md`; the epics wiki page explains it to consumers.
- **Env-file credentials are read by a parser, never by the shell** (4.236).
  `guidelines/core/SECURITY.md` gains the vulnerability row (`source`/`export` of an
  env file turns it into a script and parse failures echo the secret — real incident:
  password in plain text in a subagent transcript) and the matching checklist item;
  the logging category now states that agent/tool output that touched a credential
  (subagent return, ledger event, closure, report) **is a log** for the "never log
  secrets" rule. `TESTING.md`'s E2E sensitive-output rule (4.169) becomes an instance
  pointing at that category.
- **A re-presented list is a measured list** (4.237). Any state/pending summary shown
  to the Director checks each pending item against its durable source before
  re-presenting it; unchecked items are marked `não medido`, never shown as current
  (field case: 3 already-resolved items billed by the same review). Owner:
  `sdd-conventions.md`; the report contract's "Medido, nunca estimado" rule and the
  `status` skill cite it, and `status` now runs `index-check.sh` **before** composing
  the summary.
- **A conflict claim against a prior directive is verified, never deduced** (4.238).
  The PO's escalation criterion 4 now requires the directive's anchor (BRIEF, INDEX
  irreversible decisions, prior report, ledger `decisao` event) quoted in ≤1 line at
  the tail of the block — with the mandatory degradation "escalate anyway, declaring
  `âncora não localizada`" so the rule can never suppress a legitimate escalation.
  Optional `ancora:` field in the escalation schema (only for `criterio: diretriz`).

---

## [0.107.1] — 2026-08-19

Re-init: none

Decision 4.234 — telemetry worklogs stop double-counting. Field case (Director's
report with the real tracker worklog in hand): per-stage hooks logged correct slices,
then the delivery hook logged a kickoff→end worklog — the sum of every stage — so any
Jira time aggregation counted ~2× the real time. The ambiguity came from 4.196's
"measured slice" wording at the closing hook.

### Fixed

- **Worklog window is always the delta between marks** (§17 of the jira-sync
  protocol): slice start = the most recent of the last cycle-clock mark and the end of
  the last published telemetry worklog (this also covers per-wave closures, which have
  no mark of their own). On routes with intermediate marks the kickoff→end window is
  never a worklog — the cycle total already lives in the closing counters comment and
  in the report's `Duração` line, and stays only there. Kickoff→end as a worklog
  remains correct solely on routes without intermediate marks (standalone brief,
  on-demand mode — 4.196 untouched).
- **Degraded hooks keep their coverage**: a slice whose hook failed mid-cycle (pending
  `tracker` ledger event) is re-published as its **own** worklog by the delivery
  reconciliation — recovering coverage never widens the closing worklog's window.
- Pointer clarifiers on the delivery hook of `/keelson:auto` (item c) and on the
  `Telemetria:` line of the report contract; the troubleshooting wiki gains the
  recognizable symptom ("a worklog summing the whole cycle") with the manual fix.

## [0.107.0] — 2026-08-18

Re-init: none

Decisions 4.228–4.233 — second field batch from the same consumer cycle: the six
`PROPOSTA_PLUGIN` findings recorded in the consumer's learning-log (LRN-066..069 plus
the LRN-034/LRN-056 recurrences) become doctrine and lint. Injected block and ficha
contract untouched.

### Added

- **Parallel-wave declaration is checked, not remembered** (4.228). Before declaring a
  wave parallel, the implement step 1 crosses the candidate TASKs' `Escopo > Inclui`
  against the shared-registry file list (DI container, route files, manifests) — 2+
  TASKs citing the same registry file force sequential, even when territory disjunction
  suggests otherwise (field case: 3 violations in one session with the lesson written
  twice by its own author).
- **New-file names are verified like paths and schemas** (4.229). The tasks generator
  confronts a new file's name/prefix with the active profile's naming convention before
  writing it (field case: 2 components born with the design-system-reserved prefix).
- **Gate 11 alignment prescriptions are summed before written** (4.230). A correction
  prescribing padding/margin/width to equalize coordinates is verified by arithmetic
  (both tracks summed); without readable track values it degrades to `sugestao`.
- **Wave-end inventory gains the tracker axis** (4.231). With `jira.enabled`, the
  ledger must hold this wave's `tracker` events for the dispatch and closure hooks;
  blocking is on the act of dispatching, never the external result (field case: 6 waves
  with zero dispatches, the whole tree stuck in "To do" until delivery reconciliation).
- **Scope-mutation accounting gets the right denominator plus a lint fact** (4.232).
  The countable closure now counts every method that touches the scoped table (with or
  without a predicate today) — a write method with no predicate is a missing proof, not
  out of scope (field case: real write-IDOR reached gate 8 unseen). New WARNING
  `task-mutacao-sem-contagem` enforces the countable form; number-vs-code stays with
  gate 8.
- **Security tests carrying a suite group become a lint fact by name** (4.233). New
  WARNING `task-prova-seguranca-com-grupo`: a security-test file in `Inclui`
  (`*Permission*Test`/`*Security*Test`/`*Guard*Test`, declared best-effort) whose
  verification command uses `--group <tag>` with no prohibition in the TASK — the
  inherited-boilerplate case 4.215 cannot see; suppressed when 4.215 already fires.
  Both new checks ship with fixtures and validator escalation rules.

## [0.106.0] — 2026-08-18

Re-init: none

Decisions 4.225–4.227 — field batch from a consumer transcript analysis (a ~7h30 `/auto`
cycle with ~22 fix commits): the three actionable causes become doctrine. None of them
touches the injected block or the ficha contract.

### Added

- **SPEC symmetry: what is written must be read back** (4.225). `specify.md` gains
  principle 10: an FR that introduces a new persistable field/state is incomplete
  without a read counterpart — some FR/AC in the same SPEC names where the saved value
  reappears (reload, query payload, display); a read AC on the same FR satisfies. The
  `spec-validator` gains the matching semantic WARNING (sibling of 4.198, same declared
  boundary against the graph's `fr-sem-ac`). Field case: a value specced only on the
  write side produced 4–5 chained fixes.
- **Gate proof must live in the default suite selection** (4.226). Gate 1 gains a
  falsifiability check: the group/tag/marker of every new test is confronted with the
  default runner configuration's exclusions — an excluded proof exists and passes in
  isolation but never runs where the team looks (4th occurrence of the class in the
  same consumer project; 4.149 ladder). The `developer` gains the mirrored autocheck
  before reporting, with countable evidence in the existing `verificacao.final` field.
  Written as a property of the test, not of the run — the gate 2 scoped-run rule and
  the TASK-criterion owners (4.161/4.215) stay untouched and are pointed to, not copied.
- **Textual guards are born as countable inventories, never language parsers** (4.227).
  `TESTING.md` "Asserções que provam" gains a 6th bullet: a guard proving a property of
  source code by text scanning declares its universe (allowlist/inventory with countable
  closure), carries a positive control (4.186) and degrades to a warning when it cannot
  parse — trying to recognize every form of the language is fail-open by construction
  (field case: 3 gate rounds teaching SQL idioms to a regex until the oracle became an
  allowlist).

## [0.105.0] — 2026-08-17

Re-init: none

Decision 4.224 — the `/keelson:auto` kickoff now estimates every demand. The 4.223
deferral ("auto consumes estimates once the calibration has a real base") was circular,
as the Director pointed out the same day: the base only forms if the cycle estimates,
and standalone `/keelson:estimate` calls are too rare to feed it.

### Changed

- The auto kickoff (step 0.5, new item 6.6, between tracker root and branch) invokes
  the `estimator` agent and writes the `## Estimativa` section into the BRIEF on every
  file-backed route — no confirmation asked (it is a record, not a decision).
  Best-effort and never a gate: "not estimable" or an agent failure lets the cycle
  proceed without the section, declared in one half-line in the report. A demand
  already sized in the same session via `/keelson:estimate` has its block reused, never
  re-estimated.
- With this, every closed cycle automatically produces one estimated-vs-actual
  calibration line in `guidelines/project/estimates.md` — the "no historical base"
  cold-start resolves itself. No new ficha key: the behavior is built into auto
  (an opt-out is only born if the cost hurts in the field, with real data).

No re-init: the ficha and the injected block are untouched. Watch with 4.223: if
kickoff estimates (made before the SPEC) err systematically more than interviewed
`/keelson:estimate` ones, that data decides whether kickoff should estimate after
specify — a future decision made with measurement, never before it.

---

## [0.104.0] — 2026-08-17

Re-init: required

Decision 4.223 — demands can now be sized before the cycle. Director's pain: with
several demands queued, there was no way to compare their sizes to decide order and
allocation — the real dimension only appeared after specify→plan→tasks, too late to
prioritize. The cycle already produced the measure a posteriori (waves, task count and
dominant size in `TASK-MMM-INDEX`; measured duration per phase); this release
anticipates it.

### Added

- `/keelson:estimate` — sizes a demand without running anything: predicted
  `~N waves · ~N tasks` (small/medium mix, same semantics `tasks.md` already defines)
  plus a time range per phase — interview, artifact writing (specify+plan+tasks),
  implementation, and gates (including expected re-gates). Read-only: creates no SDD
  artifact and never routes.
- `estimator` agent — new single owner of the sizing competence, a team tool outside
  the role cast (like `code-scout`): it sizes, it never decides. The existing "does
  not estimate effort" limits of `pm`/`po`/`product-analyst` stay untouched.
- `docs/_meta/conventions/estimate-contract.md` — single owner of the scale, the
  output skeleton, the three inviolable rules (honest refusal: a vague request gets
  "not estimable" with the named gaps, never an invented number; estimates never
  occupy measured fields; dimension informs, never routes — 4.137 intact) and the
  calibration history.
- Estimated-vs-actual loop: when an estimated demand enters the cycle, the BRIEF
  carries an optional `## Estimativa` section (`index-contract.md`); the closing
  report confronts it with the real waves/tasks and the **measured** duration
  (conditional line in `report-contract.md`), and appends one calibration line to
  `guidelines/project/estimates.md` — which the estimator reads before every new
  estimate (fewer than 3 closed demands → it declares "no historical base").
- `jira.estimate` ficha key (default `false`) + sync protocol §18 — mirrors the
  estimate to the main issue as a structured comment (custom field when the project's
  field map defines `estimate`); never a worklog, best-effort, result declared in the
  closing report.

### Changed

- Wiki: new *Dimensionamento de demanda* concept, the `jira.estimate` row in the
  ficha reference, and a FAQ entry on why a small estimate never skips the cycle.

Re-init is required because the ficha contract gained the `jira.estimate` key.
Deferred with named triggers (4.182): a dimension column in the epic living queue
(trigger: 3+ estimated demands in one epic) and automatic consumption of the estimate
by `/keelson:auto` (trigger: a calibration file with a real historical base).

---

## [0.103.0] — 2026-08-17

Re-init: none

Lessons learned gained a lifecycle (decision 4.221). Field pain reported by the
Diretor: with several people working the same codebase, a bad lesson propagates as an
obligation to every reader, an opinion-born lesson enters with the same force as a
defect-born one, and a true lesson goes stale when the world changes — and with no
demotion channel, the ledger only grows.

### Added

- Lifecycle fields in the canonical lesson format (single owner:
  `guidelines/core/WORKFLOW.md`): **Validade** (a verifiable condition that keeps the
  lesson valid, or `indeterminada`), **Estado** (`ativa | em-observacao | revogada`)
  and **Contadores** (`confirmada · contestada`). Defect-born lessons are born active
  (the defect is the evidence — preserves the 4.138 mechanism); opinion-born ones start
  under observation and promote on first confirmation; a dedupe-update now counts as a
  confirmation event.
- The symmetric demotion ladder: a grounded contest — an active lesson blocked
  legitimate work and was worked around with a declared reason (`licao_contestada` in
  the developer's report; a silent workaround remains a 4.38 violation) — increments
  the counter: first contest reformulates the lesson (never duplicates), second revokes
  it into a one-line tombstone under `## Revogadas` (full content stays in git
  history, so the active section stays clean and recurrence stays detectable).
- `/keelson:lessons-audit` — audits an existing ledger: retrofits the lifecycle format
  (conservative: pre-ladder lessons enter active), measures provenance via git pickaxe
  per block (degrades to "indeterminada", never invents a date), applies fact-backed
  verdicts directly (a testable-and-false Validade) and judgment verdicts (sediment,
  no-op, duplicates — the 4.160 ruler) only with explicit confirmation; in doubt, the
  verdict is keep.

### Changed

- State now gates the force of a lesson: only `Estado: ativa` becomes a TASK criterion
  (`/keelson:tasks` cross-check, 4.138) or a gate-7 rule (`core/CODE-REVIEW.md`);
  under-observation is reading context, revoked has no force — previously every lesson
  bound every reader forever.
- The closing-report line "Lições da rodada" (`report-contract.md`) and the
  `/keelson:implement` closure also route `licao_contestada` with the ladder applied; a
  contested lesson left without its ladder registered declares the closure partial,
  same as an unrouted `licao_candidata`.

The injected CLAUDE block is untouched — the on-demand minimal close keeps routing
only `licao_candidata`; taking the contest channel into the block would cost a re-init
for every consumer and is deferred with a named trigger (decision 4.221).

---

## [0.102.1] — 2026-08-17

Re-init: required

Two field-reported doctrine fixes from a consumer postmortem (`aav-backoffice`,
LRN-063/LRN-064), both patch-scoped (no new capability).

### Fixed

- On-demand mode's `security-engineer` trigger (gate 8) now points at the same
  canonical topic list its `performance-engineer` sibling already anchored to (gate
  10) — "sensitive change" alone let a Tech Lead treat a `sensitiveGlobs` path match
  as sufficient to dispatch the gate, when only a diff that actually touches a listed
  topic (auth, injection, upload, personal data, crypto, session, endpoints, redirect,
  exec, deps) should. Field case: an accessibility-only diff (id/aria-*/focus) got
  dispatched to gate 8 purely on path, and the reviewer returned an approved, explicit
  false-positive (decision 4.219).
- Gate 6 ("Charter + active profile adherence") gained a reverse check: when a diff
  closes exactly the defect a project's profile documents as a still-live pitfall, the
  same commit now updates that paragraph — previously nothing forced this, and it only
  happened once because a reviewer read the section closely (decision 4.220).

## [0.102.0] — 2026-08-17

Re-init: required

Decision 4.218 — design/UX becomes a dedicated quality gate (gate 11), from the
Director's field observation that delivered screens didn't match backend rigor ("the
backend is high standard, the visual is so-so"). Quality Charter 0.5.1 → 0.6.0: new
Art. 10 ("the interface meets the same standard as the code that serves it") — the
constitution had articles for correctness, security and cost, and silence for the
surface users actually touch.

### Added

- `agents/product-designer.md`: a senior Product Designer runs gate 11 mirroring the
  gate 10 pattern (4.155) — ruler read at runtime, fired by a canonical
  interface-surface list in its description (screen/component, markup, styles/tokens,
  copy, form, navigation, UI states, rendered email), one run per wave in parallel with
  the review round, also in `/keelson:review` and on-demand mode. Verdict always
  declared (`n/a` outside the surface); `design_gate11` closure field and report
  column; deterministic delivery pre-check line (same ruler as gates 8/10). No ficha
  flag: the canonical trigger list is the proportionality lever (4.155 principle). The
  gate reviews by diff inspection; an existing screen capture (qa/screen-verify)
  arrives via the briefing — the evaluator stays read-only.
- `guidelines/core/DESIGN.md`: the gate 11 ruler — a closed catalog of amateur-pattern
  blockers (data views without empty/loading/error states, components reinventing
  patterns the product already has, actions without perceptible feedback, AA
  accessibility floor, spacing/typography off the project scale, raw values duplicating
  tokens, placeholder-as-label forms) with anti-taste calibration: findings beyond the
  catalog only count when anchored to an existing product pattern (canonical component,
  token, reference screen); speculative redesign is never a gate requirement.
- Quality Charter **Art. 10** (Charter 0.5.1 → 0.6.0).

### Changed

- Gate 9 (`qa`) demarcation — a declared, Director-approved revision of 4.202: the
  sibling-consistency measurement keeps its `suggestion` cap and now travels as input
  to gate 11's briefing, where pattern judgment happens against the closed catalog.
- All 7 embedded profiles: `charter: 0.6.0` plus an Art. 10 `n/a` header note (role
  without its own interface surface). The PROFILE-OUTLINE gains no UI section yet —
  deferred until the first real frontend profile (named trigger in 4.218).
- Gate wiring across the cycle: `implement.md` (§3.3 item 11, gate briefing, closure
  YAML, wave inventory, output table), `review.md` (classification, dispatch,
  re-review, output), `auto.md` (Step 4 and the delivery pre-check), `core/WORKFLOW.md`
  (gate catalog), `core/CODE-REVIEW.md` (boundary note and per-wave round), the
  injected CLAUDE block (cast, on-demand triggers, definition of done — hence the
  re-init), `sdd-conventions.md` (load map; read-only evaluator roster), method guide
  §5 and wiki `Conceitos.md`.
- `hooks/agent-guard.sh`: nudge regex extended to gates 10/11 and the deny-roster
  completed with `performance-engineer`/`product-designer` — closes a pre-existing
  gate 10 gap (lateral finding applied with the Director's approval).

---

## [0.101.0] — 2026-08-17

Re-init: none

Decisions 4.214–4.217 — field intake from a full `/keelson:auto` consumer cycle (~4h36):
the closing report was delivered as prose without the canonical skeleton's mechanical
lines (no `Duração`, no diff composition — the class that founded 4.130, recurring), a
TASK was again born with a verification command contradicting its own criteria (3rd
occurrence of the class), and INDEX history timestamps were reconstructed from memory.
Line ceiling for commands/agents/skills raised by Director's directive.

### Added

- `artifact-lint.sh`: new TASK check `task-comando-contradiz-criterio` (WARNING, 4.215) —
  a verification command using `--group <tag>` while another line of the same TASK
  forbids that same tag; tag equality required on both sides. Fixture pair (planted
  defect + non-false-positive) frozen in the regression suite (10 cases green);
  `task-validator` escalates to ERROR when the forbidden tag is a project lesson the
  command actually violates.
- `report-contract.md` §1: countable self-check before emitting (4.214) — on routes that
  emit the literal skeleton (`/keelson:auto`, `/keelson:report`), the composed report is
  checked against §2 filtered by route: N mandatory lines / N present by literal
  `**<Name>**:` marker; missing line → fill it (or name the gap) before sending.
  `commands/auto.md` carries the trigger.

### Changed

- `commands/tasks.md`: the lessons cross-check (4.138) now also covers lessons that
  classify a **type/class** of test or command without naming a file, and verifies the
  **literal command** of each criterion against the lesson — not just the prose citing
  it (4.215, the dammed LRN-056 patch).
- `index-contract.md` (INDEX update recipe, item 3): history entries are timestamped
  with a **measured** mark at event time (or reuse an already-measured mark from this
  run's Cronologia/ledger); an entry reconstructed from memory ships date-only, never an
  invented hour (4.216).
- Line ceiling for `commands/`, `agents/` and `skills/` raised from 300 to 500 lines,
  anchored on Anthropic's authoring guideline (<500 lines; 4.217, Director's directive) —
  the 4.160 pruning rules still apply to every edit.

---

## [0.100.7] — 2026-08-16

Re-init: none

Decision 4.212 — Anthropic's Agent Skills authoring best practices become a verifiable
ruler: new maintainer skill `skill-standards` (`.claude/skills/`, outside the package)
checks any created/edited skill/command/agent against a cached digest of the official
docs, re-fetched when older than 30 days. First adherence round ran over the whole
package this batch: 45 artifacts reviewed, 34 already adherent, 13 deviations fixed.

### Changed

- `skills/_shared/jira-sync-protocol.md` and `validator-protocol.md`: table of contents
  added at the top (files >100 lines); availability probe names `atlassianUserInfo` as
  the default with `getAccessibleAtlassianResources` as explicit fallback; time-anchored
  prose ("idêntico ao de hoje", "como hoje") replaced with behavior-anchored wording
  (also in `jira-sync-feat.md`).
- `skills/screen-verify`: "briefing" unified to "roteiro" (single term per concept).
- `agents/code-reviewer`: modified-files source gets a named default (developer report;
  fallback `git diff --name-only`). `agents/performance-engineer`: "categoria do
  catálogo" unified. `agents/product-analyst`: first-person phrasing removed.
- `commands/init.md`: embedded-profile enumeration replaced by runtime discovery of
  `guidelines/` (the hard-coded version list aged with every new profile).
  `commands/implement.md`: historical changelog clause cut from live closure-commit
  instruction. `commands/audit.md`: `osv-scanner` row marked as explicit escape hatch.
  `commands/guided.md`: "humano"/"Diretor" unified to "Diretor" for the acting role.

---

## [0.100.6] — 2026-08-16

Re-init: none

Decision 4.81 (wiki doctrine) — documentation-only batch: the project-sheet wiki page
becomes the exhaustive reference for `keelson.config.json` and `keelson.local.json`.

### Changed

- Wiki `Ficha-do-projeto`: the full-sheet snippet now includes `quality.e2e`;
  `gates.screenVerify.method` is documented (embedded `skill:screen-verify` default vs.
  project-owned method, plus the accepted boolean shorthand and its migration);
  every `jira` key present in the snippet now has an explanation row (`enabled`,
  `site`/`cloudId`, `projectKey`, the four `issueType.*` legs, `boardId`) and
  `mapFile` carries the config-never-ledger rule (4.150).
- Wiki `Ficha-do-projeto`: the `keelson.local.json` section becomes a field-by-field
  reference — realms catalogue (`description`, `baseUrl`, `login`, `defaultRealm`,
  `notes`), the versioned `keelson.local.example.json` pairing, the accepted legacy
  flat format, and the init self-check proofs (`.gitignore` coverage, no real password
  in the example). All examples are generic placeholders — no consumer data.

---

## [0.100.5] — 2026-08-16

Re-init: none

Decision 4.211 — invalid YAML frontmatter (unquoted value containing ": ") broke GitHub's
rendering of a skill file, and not for the first time; per the recurrence ladder the class
is now mechanically proven, not manually swept.

### Added

- `scripts/check-frontmatter.sh`: every `.md` opening with `---` must carry a parseable
  YAML block. Strict proof via python3+PyYAML; graceful heuristic fallback (with warning)
  when the parser is missing, mirroring the shellcheck pattern — CI always runs strict.
  Wired into three layers: pre-commit (any staged `.md` triggers a full sweep, blocking),
  CI (full sweep + regression suite `scripts/tests/frontmatter/`), and `check-release.sh`
  (a release cannot ship a `.md` GitHub will not render). Suite fixtures are excluded
  from the sweep — planted defects belong to the suite, not the repo.

---

## [0.100.4] — 2026-08-16

Re-init: required

Decision 4.210 — first real run of the internal harness audit (12 blind dual judges over
77 doctrine surfaces) applied: every dual-agreed finding was the same defect class —
restating a rule that already has a declared owner, or motivational no-op prose.

### Changed

- `agents/developer.md`, `agents/qa.md`, `commands/jira-sync.md`, `commands/implement.md`:
  inline restatements of commit-convention, Jira-protocol §9/§7.0/§15 and
  handoff-protocol §8.1 rules replaced by pointers to their owners — behavior contracts
  unchanged, one address per rule.
- `guidelines/core/ARCHITECTURE.md`: "Isolamento de efeito colateral" section removed
  (second copy of Quality Charter Art. 4). `guidelines/core/WORKFLOW.md`: "Exija
  elegância" section and persona phrasing removed (no-op under the 4.160 pruning tests).
- **Injected CLAUDE block** (`templates/CLAUDE.keelson-block.md`): round orchestration
  re-declaration replaced by a pointer to its single owner (CODE-REVIEW.md §Orquestração),
  and the gate-10 cost-surface list — which had drifted from the canonical
  `performance-engineer` list — now points at the canonical source. This changes the
  injected block: **re-run `/keelson:init` after updating**.
- `docs/_meta/method-guide.md`: per-command §3.x bodies reduced to a short summary plus a
  pointer to the canonical `commands/*.md` (frozen KEEP/CUT plan from the audit pilot);
  quickstart, §5 agents table and pointer headings untouched. The wiki mirror follows
  automatically.

---

## [0.100.3] — 2026-08-16

Re-init: none

Decision 4.209 — internal harness audit. A pilot with an external dual-judge audit
tool validated the mechanics but could not see `commands/`, `agents/` or the packaged
skills as surfaces; the repo now carries its own deterministic pointer check, activated
by maintainer decision ahead of its original field trigger (declared divergence).

### Added

- `scripts/check-refs.sh`: every package path cited in doctrine prose (backtick spans,
  plus `${CLAUDE_PLUGIN_ROOT}/` reads inside fences) must resolve to an existing file
  or directory. Precision-first: only known package roots are tested, consumer-side
  paths (`guidelines/project/**`, `docs/<slug>/…`) and placeholders never fire, and
  surfaces are enumerated via `git ls-files`. Report-only for now — manual run, not a
  routine commit gate; its regression suite (`scripts/tests/refs/`, planted-defect
  fixtures with frozen output) joins the pre-commit motor loop and CI like every suite.

---

## [0.100.2] — 2026-08-14

Re-init: none

Decision 4.207 — consumer field report: in a large feature, three near-identical
functions that could have been one survived the whole cycle. The Art. 3 rule already
forbade reimplementing what exists, but its search instruction pointed only at the
documented canon: an equivalent born two waves earlier was in nobody's diff and in
nobody's docs, and the closing convergence pass deliberately does not re-run gates 1–7.

### Changed

- Gate 7's Reuse/DRY bullet now names the three search surfaces explicitly: the round's
  own diff, the accumulated branch diff (equivalents born in earlier waves of the same
  PLAN; searched by name/signature over files created in the branch, `n/a` declared when
  no base branch is resolvable), and the documented canon. The finding always targets
  the current round's diff — the earlier equivalent is the canon to reuse, never
  retroactively reproved (`guidelines/core/CODE-REVIEW.md`).
- The developer looks for an existing equivalent — including one born in an earlier wave
  of the same PLAN — before creating a new helper/validation/conversion, as a pointer to
  the gate-7 rule (`agents/developer.md`).

---

## [0.100.1] — 2026-08-14

Re-init: none

Decision 4.206 — maintainer field report: with parallel claude sessions on the same
machine, the stale-background guard of session B nagged about session A's background
processes — its only filter was the Bash-tool shell mark in the command line, which
is machine-global, and the nudge's text tells the agent to kill what it flags, so one
session could take down another's legitimate work.

### Fixed

- `stale-background-guard` now attributes ownership by walking the PPID chain in the
  same `ps` table it already captures (4.206): a process is silenced **only** on
  positive proof it belongs to another live claude session (own session root
  identified AND the candidate's chain passes through a different claude process).
  Everything else keeps nagging — orphaned chains (reparented to init, the classic
  shape of the very incident that motivated the guard, now labeled
  `dono INDETERMINADO`), an unidentifiable own root, and a `ps` table that yields
  zero parsed rows (fail-closed nudge, never "clean"). The rule in one line:
  indeterminate never counts as "another session's" — the change can only shrink the
  flagged set, never create the expensive false negative. Skipped processes are
  counted in the report.

### Added

- Regression suite `scripts/tests/stale-bg/run.sh` (fake `ps` injected via PATH,
  self-PID test seam): first mechanical coverage of a hook's Python body — wired
  into CI and into the pre-commit gate when the hook or the suite changes.

## [0.100.0] — 2026-08-13

Re-init: required

Decisions 4.204–4.205 — consumer postmortem from the post-merge window of the same
field cycle as 0.97.0–0.99.0: the Tech Lead repeated, minutes after diagnosing it,
the very mechanism it had just proposed a fix for (apply the code fix a gate finding
asks for, never route the lesson it carries) — this time in on-demand mode, a surface
the formal cycle's closure (4.199) never reaches. Both fixes land in the injected
CLAUDE block, the only text that governs closings in both modes.

### Changed

- Closing report contract (`conventions/report-contract.md`, the declared owner of the
  full closing form) gains the mandatory line "Lições da rodada" (4.204): every
  `licao_candidata` returned by any gate of the round — including retry/convergence —
  leaves the closing with a recorded destination (`alvo: projeto` → the project's
  lessons file; `alvo: processo` → `agile-coach`). Applying the code fix a finding asks
  for is not routing the lesson it carries — two distinct acts; a closing with an
  unrouted lesson declares itself partial, same rule as a pending gate. The injected
  block's closing bullet carries the minimal version of the same rule, so on-demand
  mode — where the recurrence happened — is covered too. If the class recurs, the next
  patch must ship a mechanical autocheck (4.149 ladder), not a third prose rewording.
- The "trivial, no brief" exception of on-demand mode gains an operational pre-dispatch
  test (4.205), owned by `conventions/index-contract.md` next to the existing
  falsifiable rulers and mirrored in the injected block: does the diff introduce or
  propagate a field/contract across a layer or component boundary (new query/column,
  field crossing a service, new type on the consuming end)? Then it is not trivial,
  however small it looks: the standalone brief is written before the code, never
  retrofitted after review flags its absence.
- Wiki Primeiros-passos: the "trivial is blast radius, not size" rule now names the
  same layer-boundary test (4.205).

## [0.99.0] — 2026-08-13

Re-init: none

Decision 4.203 — absorption of an external benchmark (the public "gauntlet-loop"
pattern) at the Diretor's request: most of it already existed in keelson
(generator ≠ evaluator, clean-context critics, wave fan-out) and the uncapped
loop-until-win was rejected (it conflicts with the deliberate retry ceiling of
4.88/4.187); what remained was a real gap — UI demands had no place to anchor
"what it should look like".

### Added

- The BRIEF contract gains an optional additive section `## Referência visual`
  (4.203): for demands with a screen, the Diretor may anchor visual quality in a
  concrete reference that must pass three falsifiable tests — **named** (a specific
  thing, not a category), **fetchable** (can be opened, run or screenshotted) and
  **comparable** (side by side with the delivered screen allows judgement). The
  forge (`/keelson:brief`) offers to record it; no validator requires it.
- Gate 9 consumes the reference when present (4.203): the distilled gate briefing
  carries the literal reference line, and the QA compares the delivered screen
  against it with a **binary comparative verdict** (reaches / does not reach, each
  difference named from the snapshot — measured, not eyeballed), never a score.
  The reference replaces the sibling group as the exemplar of 4.202; severity stays
  capped at suggestion (binary is the form of the judgement, not its severity),
  unless an AC cites the reference. The reference is captured **outside the
  authenticated session** (reading material, never a login target — realm isolation
  of `screen-verify` preserved). Without a reference, 4.202 applies unchanged;
  without a screen gate, the comparison is declared `n/a`.

## [0.98.0] — 2026-08-13

Re-init: none

Decisions 4.201–4.202 — Diretor report with a screenshot from the same field cycle as
0.97.0: two visible UI defects survived every gate that actually looked at the screen,
because no rule made them defects.

### Added

- Gate 7 gains a copy-hygiene rule (4.201): an SDD artifact ID (`FR-`/`AC-`/`TASK-`/
  `DEC-`…) visible to the end user — in a label, message or template text — is leaked
  process residue, not copy, unless an AC explicitly requires displaying it (the gate-4
  declared-parent test is the discriminant, so traceability/admin screens stay
  legitimate). Comment anchors and E2E `@AC` tags remain the legitimate homes for IDs.
  A mechanical check is deliberately deferred (no package script reads consumer
  production code; second field occurrence triggers a WARNING-only check per the 4.149
  ladder).
- Gate 9 gains a structural-consistency criterion (4.202): sibling fields of the same
  visual group with divergent structure (label→control vs. label→text→control; default
  as placeholder vs. static text) are a finding — measured against the accessibility
  snapshot, comparing siblings within their own group (the group is the exemplar, never
  a design ideal), and capped at suggestion severity: it never fails the gate or
  consumes a retry on its own, unless it contradicts an AC.

## [0.97.0] — 2026-08-13

Re-init: none

Decisions 4.197–4.200 — consumer postmortem of a full autonomous `/keelson:auto` cycle
(proposal queue 4.111): four gate-mechanics gaps, each one a rule that existed in prose
but not at the checkpoint that could have enforced it.

### Added

- `spec-validator` gains a semantic check (WARNING, escalating to ERROR on class
  recurrence): an FR with prohibition/refusal wording covered only by ACs that prove
  downstream mitigation — blocking the *next* action instead of refusing the event
  itself — proves a weaker version of the FR. Indirect refusal ("returns 403",
  "remains unchanged") satisfies it (4.198).

### Changed

- The end-of-wave inventory (implement, step 3.6) now enumerates all three per-wave
  gates — reviewer always; security *and performance* when due — and requires actively
  matching the wave's diff against the performance-engineer's canonical trigger list; a
  cost trigger with no recorded gate-10 verdict reopens the wave (4.197). Recurrence
  promotes this to a mechanical check (standing trigger from 4.92).
- Task closure now fails when a non-null `licao_candidata` from any gate report
  (including retry/convergence rounds) is left without a registered destination —
  applying the code fix and routing the lesson are two distinct acts; the block is on
  the act of routing, with an inline fallback when the agile-coach is unavailable
  (4.199).
- `data_inicio`/`data_conclusao` in the consolidated task report and the developer
  report now carry the measurement instruction inline (wall clock via `date`, or the
  real commit timestamp as evidence) — never estimated from memory; inconsistent
  estimates had cost a wave its telemetry (4.200).

## [0.96.1] — 2026-08-13

Re-init: none

Decisions 4.195–4.196 — first field round of 0.96.0 (consumer postmortem + Diretor
report, proposal queue 4.111): scripts shipped without their executable bit, and active
telemetry could skip the worklog in total silence.

### Fixed

- Executable bit committed for all 32 package scripts (`scripts/*.sh`, including test
  suites) — the installed cache preserves the mode git has, so `100644` became a real
  `permission denied` in the field; the pre-commit/CI check now covers `scripts/` and
  `scripts/git-hooks/` alongside `hooks/` (second occurrence of the 4.180 class → the
  check widens, 4.195).
- `index-contract.md` ("Number allocation") now prescribes the `bash "…"` invocation
  form for `next-id.sh` — the form the six real callers already used, and the only one
  that doesn't depend on the executable bit (4.195).
- Telemetry can no longer fail silently (4.196): every route that posts the closing
  comment also posts the worklog (including on-demand mode and standalone briefs); the
  standalone brief now carries a measured `**Largada**:` mark (the duration source that
  route was missing); and the closing report gains a mandatory `Telemetria:` line when
  `jira.telemetry` is on — published, failed with reason, or not publishable, never
  omitted.

## [0.96.0] — 2026-08-12

Re-init: required

Decisions 4.190–4.194 — branch policy becomes configuration, and the tracker sees the
work from the first act:
the demand's root issue is born at kickoff, branch names can carry its key, and an
opt-in telemetry stream posts per-stage worklogs. Defaults preserve today's behavior —
consumers who change nothing feel nothing; re-init is required only to receive the new
ficha fields.

### Added

- `git` block in the ficha (`keelson.config.json`): `branchStrategy` (`"unica"` default ·
  `"por-fatia"`) sets the default the epic decomposition proposes — the BRIEF stays the
  single source read at runtime, and the Diretor can still override per epic (4.190).
- `por-fatia` merge precondition: `/keelson:continue` no longer proposes a slice whose
  declared dependency was delivered but not yet merged into main — it surfaces the merge
  pending instead (merge remains a human act) and offers an independent slice (4.190).
- Tracker root at kickoff (4.191): with `jira.enabled`, the formal-cycle kickoff creates
  **only the root node** typed by triage (Epic for epics, spec issue as an honest stub for
  regular demands, standalone for one-offs); the key is persisted in the BRIEF header and
  copied to the SPEC by the specify hook, which enriches the stub instead of creating.
  Connector down at kickoff → the command asks the Diretor for a manual key (link mode);
  declined → best-effort as always. `epicPolicy: multi-feature` keeps creating at the
  specify hook (declared exception).
- `git.branchNaming` (`"slug"` default · `"tracker-key"`): opt-in branch names
  `feat/<KEY>-<short-description>` using the root key from that kickoff; no key → declared
  fallback to the classic `feat/<slug>-…`, and a pushed branch is never renamed (4.192).
  Guarded mechanically: new `git-branch-config` item in `init-selfcheck.sh` (tracker-key
  requires `jira.enabled`; enum values proven) with suite fixtures.
- `jira.telemetry` (default `false`): each existing stage hook posts a **worklog** with the
  measured stage duration plus a one-line comment with the stage's quality counters (gate
  retries, escalations, red re-gates) on the main issue — aggregatable in Jira time
  reports; per-operator attribution requires a per-user connector (4.193). Best-effort
  inviolable; telemetry never moves cards. New §16/§17 in the Jira sync protocol.

### Changed

- `docs/_meta/conventions/` is shipped content: what commands read at runtime in the
  consumer counts toward the version bump — the criterion is who reads, not where it
  lives (4.194).

## [0.95.0] — 2026-08-12

Re-init: none

Decision 4.189 — "does this version require re-running `/keelson:init`?" used to live as
free prose per release (with varying wording) plus the maintainer's parallel records; this
batch's audit found versions that required a re-init without the phrase in their entry.
The answer is now a mechanical fact of the CHANGELOG, read by the updater.

### Added

- Every versioned CHANGELOG entry carries a canonical `Re-init: required | none` line
  below its heading — `required` means the release changed the injected CLAUDE block or
  the ficha contract. Backfilled across the whole history from entry prose ∪ maintainer
  records (`required` wins on conflict: a redundant init is idempotent; a wrong `none`
  is the silent failure this decision exists to prevent).
- `scripts/update.sh` scans the markers of the jump `(BEFORE, AFTER]` after updating —
  resolving the freshly installed tree in the CLI's versioned plugin cache — and reports
  whether any version requires `/keelson:init`, naming them. No evidence (missing marker,
  tree not found, unbounded interval) degrades to "undeterminable", never to "not needed".
  Note: the detection only operates from the *next* update on — the jump onto this
  version still runs the previous script.
- `scripts/check-release.sh` requires the marker on the current version's entry (scoped
  to the current entry only, so a forgotten historical marker cannot block unrelated
  commits).
- New regression suite `scripts/tests/release/run.sh` — the first safety net for
  `check-release.sh` and `update.sh` beyond `bash -n` — wired into pre-commit and CI.

### Changed

- `/keelson:update`'s report gains the re-init verdict line; the wiki's "after updating"
  section now points at the marker instead of the old free-prose convention.

---

## [0.94.0] — 2026-08-12

Re-init: none

Decisions 4.184–4.187 — a consumer postmortem (a "review-narrative sweep" that grew from
an estimated single mechanical check into 9 gate rounds across 180 files) taught four
rules: where disposable in-repo tooling lives, that the narrative class has two axes and
recurs at the moment of writing, that an evaluator's "0 occurrences" claim proves nothing
without a positive control, and that class sweeps need a declared round ceiling.

### Added

- Disposable tooling that must live inside the consumer's tree (e.g. proof scripts that
  run in the project's container) is born under `thoughts/local/tools/<purpose>/`, with
  ignore coverage proven at creation and removal declared at closure — never a new
  untracked directory in the tree (4.184, `sdd-conventions.md`).
- Mechanical absence claims by reviewers ("grep returned 0") now require a **positive
  control** in the same run — a pattern that must match — otherwise "clean" is
  indistinguishable from "the command never executed" (4.186, `CODE-REVIEW.md`).
- Class sweeps ("no instance of pattern X remains") get a **declared round ceiling**
  (default 2): a genuinely new axis found beyond it becomes declared debt or an explicit
  Director decision — plus the named cross-file orphan-pointer limitation of grep-based
  closure (4.187, `CODE-REVIEW.md`).

### Changed

- The developer's comment autocheck (4.135) now runs before **every** report (not only
  retries), tests by function ("does the sentence narrate where the change came from, or
  compare the code to a state the reader can't reach?") across both axes — provenance
  and temporal comparison — and mandates **cut, never rewrite** when removing provenance
  from an existing comment (4.185, `agents/developer.md`).

## [0.93.2] — 2026-08-12

Re-init: none

Decision 4.180 — an external diagnostic on a consumer project caught two plugin hooks
shipping without the execute bit: `window-marker.sh` failed silently on every `Stop`
(269 failures in 3 days) and `compact-anchor.sh` never ran on compaction. Both were
born via Write (mode 644) in the 4.146–4.149 batch; nothing mechanical checked the bit.

### Fixed

- `hooks/window-marker.sh` and `hooks/compact-anchor.sh` are executable again (mode
  committed to git, so every consumer gets the fix on the next `/keelson:update` —
  a local `chmod` on the plugin cache evaporates on update).

### Added

- Pre-commit and CI now block any `hooks/*.sh` whose index mode is not `100755` —
  hooks are invoked directly by the harness, so a missing bit fails silently; the
  check closes the class (any future hook created via Write), not just the instance.
- `init-selfcheck.sh` gains the `hooks-executaveis` item: `/keelson:init` detects a
  broken plugin cache on the consumer side, applies the indicated `chmod` as an
  immediate repair and recommends `/keelson:update` for the durable fix. New
  regression case in the suite; troubleshooting page documents the symptom.

---

## [0.93.1] — 2026-08-11

Re-init: none

Human re-review of the `backend/php.md` §10 lock-trap block added by 4.177, with every
claim checked against the official InnoDB documentation (8.4).

### Fixed

- `backend/php.md` §10: the gap-lock sentence was over-broad — it said a locking read
  **on a unique index** holds next-key/gap locks. Per the InnoDB docs, equality on the
  full unique key locks *only the record, not the gap*; next-key/gap locks apply to
  **range or prefix scans** (including the prefix of a composite `UNIQUE`) and
  non-unique indexes — which was the actual field case. The sentence now states the
  condition and the record-only exception. The other claims (outer locking clause does
  not reach nested subqueries; locks held until COMMIT; insert-intention × shared gap
  deadlock) were confirmed verbatim and stand unchanged.

## [0.93.0] — 2026-08-11

Re-init: none

Decisions 4.170–4.179. A 15-hour field session re-running the quality gates on an
advanced slice (4 gate-8 rounds on one concurrency bug, 8 escalations — all inside the
retry-ceiling contract) taught the doctrine six new rules and exposed one mechanical
defect and two open postmortem proposals (M1/M4).

### Added

- `core/CODE-REVIEW.md` (re-gate convergence): **class-wide findings close with the sweep
  as the deliverable** — literal command, swept range, empty final output, justified
  false positives, owned exclusions; the reviewer re-runs the command instead of trusting
  the report (4.173 — a real finding burned four rounds being fixed example-by-example).
- `core/CODE-REVIEW.md` (re-gate convergence): re-gates also ask **"did the proof get
  weaker?"** — deltas that flip the semantics of a proven case add a test beside the old
  one, and closure requires the neutralizing mutant to die on the delta **and** on the
  parent commit (4.174).
- `core/TESTING.md`: **correlated predicates require two mutants** — delete the predicate
  and delete the correlation, the latter only killable with a neighbor aggregate in the
  fixture; snapshot invariants get deliberately divergent parent/child builder defaults
  (4.175).
- `core/SECURITY.md`: **batch reads return partial maps — an absent key is a denial**,
  never a business default; tests cover the incomplete map and cross the chunk boundary
  with an in-scope control (4.176).
- `core/SECURITY.md` + `backend/php.md` §10: **concurrent limit/uniqueness invariants
  close on the write side** (conditional write or constraint), proven by counting rows
  under real concurrency — read locks don't reach decisions taken in subqueries (4.177;
  the php.md addition is pending human re-review).
- `core/PERFORMANCE.md`: **cost fixes are proven on the path named by the finding** — 
  count all round-trips at two volumes; composition-born N+1 (new collaborator injected
  into a service called in a loop) requires grepping callers (4.178).
- `docs/wiki/Solucao-de-problemas.md`: new entry — commands typed mid-turn arrive as
  text; human-only commands must be sent standalone.

### Changed

- `/keelson:e2e-setup`: the close now runs **gate 8 before writing `quality.e2e`** when
  `gates.security` is on — the command's diff is sensitive by design (installs a
  third-party dependency, generates credential-reading code); a stop hook is a net,
  never the gate (4.171, postmortem proposal M1). The Node manifest prerequisite gains
  its third state — **exists in a subdirectory** (signals: `--prefix` in the ficha's
  quality commands, root gitignore) — instead of proposing a root manifest that would
  create a second Node ecosystem (4.172, proposal M4).
- `commands/implement.md`: the ledger event catalog now names `decisao` (Director's
  choice at an escalation), aligning the text with what `ledger.sh` already accepts
  (4.179).
- `docs/_meta/conventions/index-contract.md`: **durable risks/debts live in a versioned
  source artifact first**; the INDEX mirrors them with `Origem` pointing at the owner — 
  the INDEX is derived and a rebuild erases anything that lives only there (4.179).

### Fixed

- `scripts/epic-state.sh`: the BRIEF→PLAN link now matches by **extracted SPEC id** with
  a numeric boundary instead of the raw header string — a field BRIEF carrying
  `**SPEC**: SPEC-008 (a criar na Etapa 1)` had made the script classify an advanced
  in-cycle slice as `pre-task` (and the raw match also accepted false prefixes:
  `SPEC-01` matched `SPEC-010`). An in-cycle slice whose child brief cannot be resolved
  now emits a visible `aviso` line instead of silently electing a route. Four new
  fixtures born from the field artifact, red-repro-proven against the old script
  (4.170).

## [0.92.2] — 2026-08-11

Re-init: none

Decision 4.169 — first gate 8 run over the `/keelson:e2e-setup` scaffold (same field
session as 4.167/4.168): three medium findings, all one family — the credential typed
by the auth setup project leaked into run artifacts.

### Fixed

- **The generated auth skeleton is born hardened**: setup projects — the only ones that
  type credentials — carry `trace: 'off'` and `screenshot: 'off'` (other projects keep
  the default); the realm name is validated as a slug (`^[A-Za-z0-9_-]+$`, failing
  closed) before composing the `storageState` path; and the `keelson.local.json` read
  gets its own guard, since the parser's error message echoes a window of the
  credential file and must never be passed through.
- **E2E run output declared sensitive** (`guidelines/core/TESTING.md`): even with
  capture off, any failure produces the runner's error context with a page snapshot —
  password field value included. The gitignored destination is the containment
  (coverage proven with `check-ignore`, per 4.168); the output must never become a
  published CI artifact — the generated config carries this note where whoever wires
  CI will read it.

Consumers that already ran the setup with auth: re-run `/keelson:e2e-setup` (repair
mode) or apply the three adjustments by hand.

---

## [0.92.1] — 2026-08-11

Re-init: none

Decision 4.168 — field feedback from the first real `/keelson:e2e-setup` run: the setup
scattered three gitignored runtime directories (`test-results/`, `playwright-report/`,
`e2e/.auth/`) across the app root, each needing its own `.gitignore` line.

### Fixed

- **E2E runtime artifacts consolidate into one home**: `thoughts/e2e/` at the project
  root (subfolders `test-results/`, `report/`, `.auth/<realm>.json`) — the same
  transitory house as `thoughts/screen-verify/`, covered by the single `thoughts/`
  ignore line (coverage still proven with `check-ignore`, per 4.51). Apps in a
  subdirectory point at the root `thoughts/` via relative paths. Pre-existing Playwright
  configs keep their own paths (the setup does not fight an established config) — the
  individual ignore lines apply there. General rule extracted: a new tool producing
  transitory artifacts is configured toward `thoughts/`, never granted its own root
  directory.

Consumers that already ran the setup with the defaults: re-run `/keelson:e2e-setup`
(repair mode) or move the three paths in the config.

---

## [0.92.0] — 2026-08-11

Re-init: none

Decision 4.167 — first real `/keelson:init` run after 4.166 exposed the adoption gap:
a project without an E2E runner got `e2e: null` and nothing else. An opt-in gate with
no guided door is opt-in only for those who already know the tool (same finding that
produced `/keelson:mutation-setup`, 4.123).

### Added

- **`/keelson:e2e-setup` (human-only)**: guided E2E setup mirroring `mutation-setup` —
  detects an existing runner (a consolidated non-Playwright engine is never swapped;
  it becomes the ficha command, with the tag-scoping caveat), installs
  `@playwright/test` and the browser binary with confirmation, generates the config
  from the ficha (`testDir: e2e/`, gitignored outputs, `baseURL` via env, per-realm
  auth skeleton reading `keelson.local.json` at runtime — no committed secrets), writes
  a smoke spec as a living example of the tag convention, proves the pipeline with
  `npx playwright test --list` and only then writes `quality.e2e`. AC specs remain the
  developer's per-task deliverable.

### Changed

- `/keelson:init` now points at `/keelson:e2e-setup` in its report line when no E2E
  runner is detected — instead of leaving `e2e: null` with no next step.

---

## [0.91.0] — 2026-08-11

Re-init: required

Decision 4.166 — screen verification gains a durable, re-runnable layer: verified UI
behavior is codified into versioned E2E specs, so regression stops re-paying the cost
of live browser exploration.

### Added

- **`quality.e2e` (opt-in ficha field)**: the project's literal E2E suite command (e.g.
  `npx playwright test`); exit code is the verdict, like `quality.test` (4.166).
- **E2E specs as gate-9 memory**: behavior verified once via the driven browser (MCP) is
  codified by the developer into a committed spec, tagged `@<slug>` per file and
  `@AC-NNN-XXX` per test — task-scoped runs via `--grep`, full regression at
  `/keelson:integrate` (same position as the mutation gate). The driven browser is
  reserved for new behavior and visual judgment. Owner ruler: `guidelines/core/TESTING.md`,
  "Specs E2E".
- **`scripts/e2e-coverage.sh` + test suite**: mechanical AC→spec coverage facts —
  `WARNING e2e-tag-orfa` (tag pointing at a nonexistent AC, scoped to slug-tagged files),
  `INFO ac-sem-spec-e2e` (not every AC is a screen AC — calibration stays with gate 9)
  and `INFO e2e-cobertura` (M/N). Wired into pre-commit and CI.
- **Spec-edit ruler (gate 2)**: editing an existing spec's assertion/selector requires
  citing the intentional AC/SPEC change that justifies it — rewriting a red spec green
  without one is the red-repro violation (4.159) at the E2E layer.
- **No committed reference images**: specs assert DOM/text/state/network only;
  screenshots remain runtime evidence in gitignored folders (`test-results/`,
  `playwright-report/` added to the init `.gitignore` step).

### Changed

- `/keelson:init` detects `@playwright/test`/`playwright.config.*` and offers
  `quality.e2e` (opt-in, proven with `--list` — never a full run); `/keelson:integrate`
  runs the full E2E regression after the green suite, declaring absence or an unavailable
  screen environment by named cause, never silently. `qa` proves already-covered behavior
  by running the tag-scoped suite and cites the coverage facts; `screen-verify` documents
  the division of labor with the versioned suite.

Consumers adopting the field should re-run `/keelson:init` (new ficha key + `.gitignore`
lines); projects without an E2E runner are untouched (`e2e: null`).

---

## [0.90.0] — 2026-08-11

Re-init: none

Decisions 4.161–4.165 — a real consumer cycle (26 tasks, 8 waves, ~60 commits) lands its
four proposals plus one maintainer finding from the same session's transcript: text-anchored
criteria become a mechanical check, verification gains reach, commits gain pathspecs, the
middle layer gets an owner, and the wave guard stops taxing every turn.

### Added

- **New lint check `task-criterio-grep-nao-ancorado`** (4.161, WARNING): a "Critérios de
  pronto" line whose `grep`/`egrep`/`rg` command carries no anchoring signal (`\b`, `::`,
  `->`, `class `/`function `, `Reflection`, a `-v` exclusion, or a `^`-anchored pattern)
  now surfaces as a lint fact; the `task-validator` escalates to ERROR when the condition
  being proven is structural (signature, field, projection, payload key). Field data: 12
  text-anchored criteria in one delivery — two of which, followed to the letter, would
  have taught the bug back (wrong exception type; camelCase VO field where the payload
  uses snake_case). Item (b) of the contorno block now names the general class (text
  fails both by relocation and by prose/wrong-layer false-positives).
- **Contorno tests (d) and (e)** (4.162): an AC that alters a shared file/symbol
  (SQL/schema, trait, shared builder) requires a verification command that **reaches the
  other known consumers** — `--filter` on the task's own class is insufficient alone
  (field data: 4 tasks, 4 post-merge breaks in another consumer's suite); and two
  criteria of the same TASK must never contradict each other over the same file (empty
  diff expected vs. new assertion required).
- **Middle-layer clause in decomposition principle 2** (4.164): data crossing 3+ layers
  with only the two ends named in the decomposition requires an explicit "Escopo >
  Inclui" item for the intermediate layer in some task of the wave — a node that never
  became a task is not an edge any gate can reach.

### Changed

- **Commit by pathspec** (4.163): every actor committing in the shared working tree —
  developer and the orchestrator's milestone/closure commits alike — now uses
  `git commit -m "<msg>" -- <files>`, never `add`-then-`commit` without `--`. The `--`
  pathspec makes the guarantee git's own, deterministic regardless of what other agents
  staged (field incident: a milestone commit without pathspec swept a deliberately
  neutralized tenant predicate onto the branch). Single owner in `sdd-conventions.md`;
  `agents/developer.md` cites it.
- **Wave guard nudges once per run state, not per turn** (4.165): with background agents
  and task notifications, ending the turn mid-run is the correct anti-polling behavior —
  the guard now fingerprints the run-state fields into an append-only window (same valve
  design as the agent guard, 4.141) and stays silent for an already-nudged state,
  re-arming when `waves_concluidas` advances. Measured before the change: 41 blocked
  turn-ends in one 8-wave session, one per collected notification. The core scenario
  (stopping mid-wave overnight) still gets the full nudge on first attempt, and
  legitimate stops still require `status: encerrado`.

---

## [0.89.0] — 2026-08-11

Re-init: none

Decisions 4.159–4.160 — the full sweep of the mattpocock/skills benchmark lands its two
remaining borrowings: bugfix proof starts red, and doctrine pruning gets a method.

### Added

- **Bugfix TASKs require the red repro** (4.159): the gate-1 command/expected pair of a
  `Tipo: bugfix` TASK is born from a repro that reproduces the exact symptom of the
  violated AC and **fails when executed at fixation** — the captured red evidence enters
  the criterion (in place of the non-emptiness evidence other task types carry). After
  the fix, the same command passes and becomes the regression test. A test that was
  never red proves the imagined diagnosis, not the fix. Closes the "prova do vermelho"
  step deferred on the 4.123 ladder. Mechanical check in `task-validator` stays behind
  the recurrence trigger.
- **Doctrine pruning ruler** (4.160, maintainer-side only): distillation batches now
  test every sentence — no-op (does it change behaviour vs. the model's default? no →
  delete the whole sentence), sediment (does it still match current behaviour?), and
  leading-word collapse (a three-sentence definition a pretrained concept carries in one
  token). Prohibitions that fit as positive targets are rewritten positively. Lives in
  the repo's `CLAUDE.md`; never enters consumer doctrine or validators.

---

## [0.88.1] — 2026-08-11

Re-init: none

Decision 4.158 — the audit that followed 4.157 (same gap class: a principle declared
without a falsifiable test) found one recurrence of the shape, in `/keelson:specify`.

### Fixed

- SPEC principle 8 ("scope and non-scope symmetric") gains its test: every in-scope item
  has the neighbour a reader would assume included **named** in the out-of-scope section,
  with a written answer either way. An empty or generic out-of-scope next to a
  non-trivial in-scope is the violation signal. The symmetry is what makes gate 4's
  "unrequested" question (4.143) judgeable — without a declared boundary, scope excess
  is opinion. Validator, graph and template untouched; a mechanical check in
  `spec-validator` stays deferred behind the recurrence trigger.

---

## [0.88.0] — 2026-08-10

Re-init: none

Decision 4.157 — vertical slicing stops being a decorative principle: it gains a
falsifiable test, and the structure around it (granularity by file count, single-component
TASKs) stops contradicting it. Prompted by a benchmark of mattpocock/skills, whose
`to-tickets` skill reaches the same rules independently (tracer bullets, blocking edges,
expand–contract).

### Changed

- `/keelson:tasks` decomposition principle 4: a finished TASK must deliver behaviour
  verifiable **on its own** — if its behaviour check only exists once a sibling from a
  later wave lands, the cut was horizontal and must be re-sliced by behaviour. Slices
  sharing a surface declare their blocking edge; the first slice opens the skeleton.
- Granularity (principle 7) is measured by effort and delivered behaviour, never by file
  count — a typical vertical slice touches one file per layer and stays atomic.
- The TASK `Componente` field accepts a list with a `(principal)` marker — a vertical
  slice crosses as many PLAN components as the behaviour requires. The PLAN's FR→COMP
  map documents architecture and no longer dictates TASK granularity. The graph parser
  already accepted lists and parenthetical markers, and no check consumes the
  `implements` edge: engine untouched, no new fixture.
- Named exceptions stay explicit: sensitive slices keep their own TASK (risk cut,
  principle 8 unchanged), and wide mechanical refactors are sequenced as
  **expand–contract** (expand beside the old form → migrate call sites in batches →
  contract when no caller remains).
- Wave scheduling, barriers and parallel dispatch are untouched — the autonomous cycle
  keeps its parallelism. Whether vertical cuts alone reduce wave counts is the
  observation that will feed the pending pipeline-vs-barrier decision (4.112–4.120).

---

## [0.87.1] — 2026-08-09

Re-init: none

Decision 4.156 — first real consumer round of the mechanical-fact scripts (4.151/4.154):
the parsers now match the format the plugin actually produces in the field, and degrade
with a declared warning instead of inventing a fact where they cannot parse.

### Fixed

- `epic-state.sh` maps the epic queue columns **by the table header** (canonical
  `| # | Fatia | Slug de destino | Estado |` and the field variant
  `| # | Fatia | Estado | Âncora |`), strips bold/backtick from the state, resolves the
  child brief path from the Âncora column, and emits an `aviso` line plus rule `-` for a
  state outside the closed vocabulary — it no longer picks the wrong slice with the
  confidence of a fact (in the field round it labeled delivered slices as not delivered).
- `artifact-lint.sh` no longer floods a legitimate SPEC with false positives: FR and AC
  blocks are accumulated across wrapped lines before checking (the field format breaks at
  ~100 columns, so `DEVE` and `Dado/Quando/Então` land on continuation lines), the EARS
  checks are case-insensitive and accept punctuation after the verb, and glossary terms
  are compared without bold/backtick markers — a term with a `(…)` qualifier also matches
  by its base, and the aggregated `*(reutilizados…)*` row is skipped.
- `ledger.sh append` discards a `ts:` line arriving via stdin: the measured-timestamp
  header belongs to the script, so a model-estimated timestamp can no longer end up in
  the event (the convention example that still showed the old format was updated).

### Changed

- `/keelson:auto` names the mechanical ID allocator (`next-id.sh … alloc`) at brief
  creation time — the slice launch had numbered a BRIEF from memory and collided with a
  PLAN in the same single-allocator sequence.
- `/keelson:continue` documents the degraded output (`aviso` line / rule `-`) as the
  same derive-from-artifacts order it already prescribed.
- Regression suites for the three scripts gained cases in the **real consumer format**
  (bold states, anchor column, multi-line FR/AC, bold glossary, duplicated `ts:`).

---

## [0.87.0] — 2026-08-07

Re-init: required

Decision 4.155 — performance becomes a dedicated quality gate (gate 10), mirroring the
proven gate-8 design: a specialist reviewer, a canonical trigger list, the checklist
owner read at runtime, and a verdict that is always declared — never silence.

### Added
- **`performance-engineer` agent (gate 10)**: reviews the delivered diff against
  `core/PERFORMANCE.md` plus the active profile's performance section whenever the
  change touches cost-sensitive surface (queries/ORM, loops over variable-size data,
  large-volume processing, cache/invalidation, network calls/timeouts, jobs/queues,
  heavy list/UI rendering, bundle/imports, data migrations/backfills). Runs once per
  wave in the parallel review round, in `/keelson:review`, and in on-demand mode;
  outside the trigger the verdict is a declared `n/a`, never an omission.
- Task closure gains a `performance_gate10` field and the final report a gate-10
  column, so a delivery states explicitly that performance was validated.

### Changed
- The delivery pre-check in `/keelson:auto` now demands evidence of the gate-10
  verdict on the final diff when it touches cost-sensitive surface — same rule as
  gate 8 (`revisado_por ≠ implementado_por`; missing verdict → the gate runs before
  the push).
- Severity is calibrated by Charter Art. 8: known pathological cost patterns (query
  in a loop, unbounded materialization, missing pagination/timeouts) are blocking
  findings; any optimization beyond the catalog requires a cited measurement and
  surfaces as a suggestion, never a rejection — the gate does not demand speculative
  optimization or stress testing.
- Consumer block updated (the on-demand team now includes the `performance-engineer`
  trigger) — re-run `/keelson:init` in consumer projects to refresh the block.

## [0.86.0] — 2026-08-06

Re-init: none

Decision 4.154 — the deferred list from 4.151 closes: the remaining seven pieces of
deterministic work move from prose to scripts, under the same contract (frozen
regression suites on pre-commit and CI, named degradation, doctrine citing facts).

### Added
- **`init-selfcheck.sh`**: the disk-and-git provable part of `/keelson:init` step 6 —
  codePaths, quality binaries, real-match proof of `sensitiveGlobs` against secrets on
  disk, profile resolution/`reviewed`/`charter` drift, `keelson.local.*` hygiene
  (versioned example, gitignore proven via `check-ignore`, placeholders), effective
  Playwright MCP flags across the three config scopes, minimum Jira fields. MCP-alive
  checks stay with the command.
- **`probe-env.sh`**: the QA environment probe with named causes
  (`credencial_ausente`/`credencial_placeholder`/`app_fora_do_ar`) and literal
  evidence ready for the handoff `sonda:`; `quality.boot` attempt is executed and
  recorded (4.71); passwords never echo.
- **`epic-state.sh`**: the deterministic state derivation of `/keelson:continue` —
  epic queue vs child artifacts, first matching rule, queue divergences flagged.
- **`handoff-scan.sh`**: pending verification handoffs per worktree with open V-item
  counts, for `verify-handoff`, `integrate` and delivery reports.
- **`legacy-move.sh`**: transactional root-`.md` move for `/keelson:migrate-legacy`
  (`git mv` when tracked; mid-failure rolls itself back).
- **`postmortem-facts.sh`**: installed plugin version, branch/HEAD and commit window
  for the postmortem header.
- **`edge-diff.sh`**: proves the 4.117 rewrite rule — edge fields and criteria ACs
  before/after a scribe rewrite; lost edges nobody asked for go back in the next
  redispatch.

### Changed
- Doctrine now cites these scripts as fact: `init.md`, `agents/qa.md`, `continue.md`,
  `verify-handoff.md`, `integrate.md`, `migrate-legacy.md`, `postmortem.md` and
  `graph-contract.md` §4.1.

---

## [0.85.0] — 2026-08-06

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: required

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

Decision 4.103 (description-cap correction)

### Fixed
- **`scribe` and `tracker-sync` frontmatter descriptions trimmed under the 350-char
  agent cap** (desc-guard caught them at 449/484 right after 0.70.0): over the cap the
  always-loaded plugin budget inflates on every consumer session. Trigger terms and the
  invoker list stay first; the full detail lives in each agent's body.

---

## [0.70.0] — 2026-08-04

Re-init: required

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: required

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

Re-init: required

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

`3ab34f0`

### Fixed
- Precise Agent Teams facts in the teams-mode owner.

---

## [0.22.0] — 2026-07-26

Re-init: required

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

Re-init: none

`f639fec`

### Fixed
- `/keelson:auto` resolves the slug and the BRIEF number at step 0.5, **before** the kickoff.
  The brief was persisted at 0.5 while slug resolution and SPEC numbering lived inside
  `specify` — an ambiguity that could write the brief into a parallel slug or mismatch the
  pairing number.

---

## [0.21.0] — 2026-07-26

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

Decision 4.36 · `9f54f84`

### Added
- **`/keelson:review`** — standalone code review for code that arrived without an SDD artifact
  (a diff, a branch, someone else's change), with the gate 1–7 ruleset **single-owned** by
  `guidelines/core/CODE-REVIEW.md` and executed by `code-reviewer` in both the cycle and the
  standalone route.

---

## [0.17.0] — 2026-07-25

Re-init: required

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

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

Re-init: none

Decision 4.27 · `6add21c`

### Added
- **Optional feature layer (`FEAT-*`)** — the QA unit of test, collapsible: a SPEC that declares
  features plus a configured `issueType.feature` gets the full Epic ▸ Story ▸ Sub-task
  projection, with a "feature ready for QA" milestone per Story. Both opt-ins missing → nothing
  changes.

---

## [0.9.0] — 2026-07-23

Re-init: none

Decisions 4.25, 4.26 · `10c611e`

### Added
- **Multi-realm screen verification**: named realms in `keelson.local.json` (each with its own
  URL and DEV credentials), so a project with more than one authenticated surface can be
  verified.
- **Proof of unavailability**: gate 9 only degrades into a HANDOFF after a probe that actually
  failed and was recorded — never on the assumption that the environment is down.

---

## [0.8.0] — 2026-07-23

Re-init: none

Decisions 4.23, 4.24 · `e98e46c`

### Changed
- **Running out of breath is not a trigger**: `/keelson:auto` runs to Delivery and no longer
  stops at a "clean point" between waves.
- **`wave-guard` (Stop hook)** plus an on-disk run-state make it mechanical instead of a
  matter of the model remembering.

---

## [0.7.0] — 2026-07-22

Re-init: none

Decision 4.22 · `b1bb97a`

### Added
- **Optional Jira integration** via the Atlassian MCP connector: issue types, statuses and
  custom fields are **discovered at runtime** by `/keelson:init` and stored as **IDs** in the
  ficha (no site, project key or field id ever ships in the plugin). Two modes (`create` /
  `link`), default status policy `comment` (moving cards is opt-in per project and validated
  against the live workflow), and `/keelson:jira-sync` for idempotent reconciliation.

---

## [0.6.0] — 2026-07-22

Re-init: none

Decision 4.21 · `c49e122`

### Changed
- **Namespace naming doctrine** recorded, plus the renames `guiado` → `guided` and
  `state` → `status`.

---

## [0.5.1] — 2026-07-22

Re-init: none

Decision 4.20 · `498dcdf`

### Changed
- **Anti-redundancy trim** across commands, agents and skills: a native harness capability is
  not re-instructed. `security-engineer` reads the `core/SECURITY.md` checklist at runtime
  instead of replicating it.

---

## [0.5.0] — 2026-07-22

Re-init: none

Decision 4.19 · `eaec382`

### Added
- **Legacy PHP ladder embedded** (5.6 · 7.0 · 7.4 · 8.0) with **nearest-lower** version
  resolution — a generated profile starts from the closest embedded version *below* the
  project's and writes only the delta, never from a higher one.

---

## [0.4.0] — 2026-07-22

Re-init: none

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

Re-init: none

Decision 4.15 · `3521e88`

### Added
- **`review-guard` (Stop hook)** — forced code review for code written outside the SDD flow,
  with a size threshold.

---

## [0.3.0] — 2026-07-22

Re-init: none

Charter `0.2.0` → `0.3.0` · `6ead08a`, `9d54075`

### Changed
- Clean-code doctrine into the Charter: parameters, effects in the name, conditionals, naming
  red flags (`0.2.0`); abstraction parsimony and patterns as vocabulary (`0.3.0`). Plugin
  version realigned with the Charter.

---

## [0.2.5] — 2026-07-20

Re-init: none

`1bf6538` (LRN-015/016/017)

### Fixed
- Process-chain tuning from an audit: the ficha reaches the validators, the INDEX contract is
  enforced, gate briefing is explicit.

---

## [0.2.4] — 2026-07-18

Re-init: none

`a155bb3` (LRN-014)

### Fixed
- `/keelson:auto`'s understanding mirror is written in the conversation body, not in a dialog.

---

## [0.2.3] — 2026-07-18

Re-init: none

Decision 4.14 · `b6f1062`

### Added
- **Understanding mirror on the last call**: the confirmed prompt is the contract.

---

## [0.2.2] — 2026-07-18

Re-init: none

Decision 4.13 · `de9e6ea`

### Added
- **Absent mode** in the autonomous cycle: last call plus reaction ladder (recalibrates 4.11).

---

## [0.2.1] — 2026-07-17

Re-init: none

`fc54360`

### Changed
- `/keelson:init` is merge-preserving; `keelson.local.example.json` is versioned.

---

## [0.2.0] — 2026-07-17

Re-init: none

`806a9c5`

### Added
- **`screen-verify` skill** and the local access config — screen verification becomes a method
  (`screenVerify` gate) instead of an ad-hoc request.

---

## [0.1.3] — 2026-07-17

Re-init: none

`3eb088b`

### Added
- **`/keelson:verify-handoff`** — closes a pending screen-verification HANDOFF.

---

## [0.1.2] — 2026-07-17

Re-init: none

`9541b71`

### Added
- **`stale-background-guard` (Stop hook)**.

---

## [0.1.1] — 2026-07-17

Re-init: none

`1d8469c`

### Fixed
- Full review pass: plugin/project boundary, hook anti-renudge, profile resolution.

---

## [0.1.0] — 2026-07-16

Re-init: none

`079b973`

### Added
- **Initial scaffold**: the SDD engine (`specify → plan → tasks → implement`), the Quality
  Charter, the Profile Outline, language profiles, validators and the first hooks.
