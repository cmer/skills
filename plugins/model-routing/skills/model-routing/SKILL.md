---
name: model-routing
description: Pick which model and reasoning effort executes delegated work (subagents, workflows, Codex). Use before dispatching any delegated task — defines the effort dial, the mandatory Opus scope fence, Fable's planner and skeptic roles, review verdicts (ship/fix-first/rethink), and escalation ladders.
user_invocable: true
---

# Model routing

Rules for picking which model executes a piece of work when dispatching subagents (the Agent/Workflow `model` and `effort` parameters) or Codex. Read this before the first delegated dispatch in a session; treat it as binding when you delegate.

**Project overrides win.** If the repo has its own routing doc (e.g. `docs/tech/model-routing.md`) or CLAUDE.md routing rules, its specifics — cost tables, risk examples, reporting targets — override the defaults here. This skill supplies the doctrine and the agents.

## Core rule

**Default to `opus-5` at `xhigh` for coding and agentic work, `high` for everything else.** Deviate only for a stated reason, and say which reason.

"Coding and agentic" means writing or refactoring code and long multi-step tool-use runs. "Everything else" is review, planning, copy, analysis, and design calls. When a task is both, take the higher setting.

Two facts this doctrine is built on:

1. **Effort is the cost lever, not the model.** `low` → `max` on Opus 5 spans a wider cost range than the Sonnet↔Opus gap, and dropping effort costs far less quality than dropping model. Turn the effort dial first; change model second.
2. **The quality gap above Opus 5 is small; the price gap is not.** Fable is a deliberate spend with specific jobs (planning and reviewing the hardest class of work, escalation elsewhere), not a routing default.

## Effective cost (defaults — override per subscription mix)

Weigh *effective* subscription cost, not API list price. Defaults assume a Claude subscription where Fable tokens are scarce and a ChatGPT subscription that makes Codex near-free; adjust if yours differ.

| model | effective cost |
|-------------|---------------|
| gpt-5.6-sol (Codex) | near-free |
| sonnet-5 | well below opus |
| opus-5 | **baseline (1×)** |
| fable-5 | **~3–4× opus** |

## Choosing effort (Opus 5)

| effort | use for |
|--------|---------|
| `low` | Trivial mechanical edits, lookups, thin wrapper/orchestration agents |
| `medium` | Well-specified bulk work: migrations, repetitive edits, data analysis. Unusually strong on Opus 5 — the usual landing spot when you sweep down |
| `high` | **Default for non-coding work:** review, planning, copy, analysis, design calls |
| `xhigh` | **Default for coding and agentic work:** implementation, refactors, multi-file changes, long autonomous runs |

Starting points, not floors — step down wherever the output still clears the bar, and say you did. Starting high and sweeping down beats starting low and escalating: a rerun costs more than the tokens it saved.

**Don't use `max`.** When `xhigh` falls short, switch to `fable-5` rather than spending more on Opus.

## Choosing a model

- **Route parts, not whole tickets.** Split mixed work before dispatch. Don't delegate a trivial edit when writing the brief takes longer than doing the work.
- **`opus-5`** — everything by default: execution, planning, UI, copy, API design, review.
- **`sonnet-5`** — bulk mechanical work with a complete spec and cheap verification (specs pass / lint clean / diff is obviously right). Step back up to Opus the moment the spec has gaps. Never ship it unreviewed on user-facing surfaces.
- **`gpt-5.6-sol` (Codex)** — adversarial review, second opinions, red-teaming, pressure-testing a design. Its value is a decorrelated error profile from a different training run, plus near-zero marginal cost. **Not an execution track** — Opus 5 at `medium` beats sol for the same effective money once you count review overhead and round-trips. Run sol at `high` for review, `xhigh` for the gnarliest calls. Use the `sol-reviewer` agent.
- **`fable-5`** — a deliberate spend with three jobs:
  1. **Planner for big, hairy work.** Dispatch Fable *first* — not after Opus misses — when a task crosses architectural boundaries, the edge-case space is larger than you can enumerate, or the decision is expensive to reverse. Fable writes the plan; opus-5 `xhigh` executes it behind the scope fence. Use the `fable-planner` agent.
  2. **Read-only skeptic at commitment boundaries.** Consult Fable before committing to a design, merging, or reporting complex work done. It reviews the accumulated diff or plan with fresh eyes against the stated goal and returns a verdict — `ship` / `fix-first` / `rethink` — with reasons. It never implements. Use the `fable-skeptic` agent (or `/verdict`).
  3. **Escalation for execution** when opus-5 `xhigh` has actually missed the bar twice.

  Keep the gate tight or "big and hairy" inflates until everything qualifies: routine features, even multi-file ones, still plan on opus-5 `high`. Fable planning is justified when a wrong plan costs more than the ~3–4× tokens.

  **Advisor-only mode** — the budget posture for medium-risk work: execution and planning stay on opus-5 (or sonnet-5 for mechanical parts), and Fable is consulted only at the commitment boundary for a verdict. No Fable planning pass, no Fable implementation.
- **Never use Haiku.**

| Risk | Examples | Routing |
|------|----------|---------|
| Low | Formatting, generated migrations, mechanical specs | sonnet-5, or opus-5 at `low`/`medium` |
| Medium | Business logic, shared abstractions, background jobs | opus-5 `xhigh` + independent review |
| High | Auth, tenancy, billing, destructive migrations, public APIs | opus-5 `xhigh` executes; review by a fresh instance and by sol (`xhigh`) |
| Complex/hairy | Cross-cutting features, architecture changes, edge-case-heavy domains | fable-5 plans and reviews (verdicts); opus-5 `xhigh` executes each plan step behind the scope fence |
| Taste-critical | UI, copy, product behavior | Copy and product-behavior calls: opus-5 `high`. Building the UI is coding — opus-5 `xhigh`. fable-5 only when the right experience is genuinely undecided |

## Briefing differs by model — don't reuse one brief

These models need opposite corrections. Handing one model's brief to the other measures prompt fit, not capability.

**Briefing `opus-5`:**
- **Delete verification instructions.** It verifies its own work unprompted; "double-check your answer" causes redundant work rather than better work.
- **State the scope fence.** It expands scope — and will act on what it finds, not just mention it. Every opus brief carries the mandatory fence (below).
- **Cap subagent delegation.** Say when delegation is warranted (independent parallel tracks) and when it isn't (a few file reads, verification).
- **Ask for conciseness explicitly.** Lowering effort does *not* reliably shorten output — prompting does.

**Briefing `fable-5`:**
- **State the goal and constraints, not the steps.** Over-prescriptive briefs measurably reduce its output quality.
- Give it somewhere to write notes when the task spans a long run.

## Dispatch and review contract

Every delegated brief must state the exact deliverable and files in scope, constraints and recorded decisions, verification commands, whether the agent may edit or is review-only, the required response format, and conditions that require it to stop instead of improvising.

**Scope fence (mandatory for every opus-5 brief).** Opus expands scope and acts on what it finds, so every opus brief must include:

- the exact files and deliverables in scope;
- **flag, don't fix** — anything out of scope goes in a required **Noticed, not touched** section of the response, never into the diff;
- a stop condition: if the task can't be completed within the fence, stop and report — don't widen silently.

**Enforce the fence; don't trust it.** After an opus run, check `git diff --name-only` against the fence. Out-of-scope changes are reverted, not reviewed. *Noticed, not touched* items go to the user or the tracker as backlog candidates — the tangent energy is captured, not acted on. A necessary adjacent fix isn't lost by this: the stop condition surfaces it as a report instead of a surprise diff.

**Plan as fence.** When Fable wrote the plan, the plan *is* the fence: brief Opus to implement the steps exactly and to stop and report when a step doesn't survive contact with the code — not improvise around it. (The briefing asymmetry holds: Fable gets goals, Opus gets the prescriptive brief.)

**Review verdicts.** Every review — Fable, sol, or a fresh Opus instance — ends with one verdict: `ship` (merge as-is), `fix-first` (listed issues block, fix then ship without re-review), or `rethink` (approach is wrong, go back to planning). Reviews are read-only; findings go back to the executing model.

Required independent review must use a fresh model instance; for high-risk work, prefer a different model family from the author (Opus wrote it → sol reviews it). Self-review by the producing instance does not count.

## Escalation (standing permission)

Defaults, not limits. If output doesn't meet the bar, rerun with more **without asking** — judge the output, not the price tag. Escalate one step at a time:

- **Coding / agentic:** `opus-5 xhigh` → `fable-5`
- **Everything else:** `opus-5 high` → `opus-5 xhigh` → `fable-5`

Skip `max` — it's not a step in either ladder. For review specifically, insert `gpt-5.6-sol xhigh` before Fable — it's near-free and independent.

**Planning skips the ladder.** For work matching the Complex/hairy row, go straight to fable-5 for the plan — the two-misses rule applies to execution, not planning.

Escalate when repo research doesn't resolve important ambiguity, a change crosses architectural boundaries, a risky decision can't be defended coherently, two focused correction attempts fail, or verification passes but intent/taste remains doubtful. If Fable still misses the bar, stop and flag it rather than burning reruns.

## Mechanics

- **Claude models** run via the Agent/Workflow `model` parameter, which takes short aliases: `sonnet`, `opus`, `fable`. Effort is the separate `effort` parameter: `low` | `medium` | `high` | `xhigh` | `max`.
- **Bundled agents** (dispatch via the Agent tool's `subagent_type`): `fable-planner` (plans on Fable, read-only), `fable-skeptic` (verdict review on Fable, read-only), `sol-reviewer` (thin Opus wrapper driving the Codex CLI, pinned to `effort: low`). The `/verdict` command wraps `fable-skeptic` for the commitment-boundary check.
- **gpt-5.6-sol is Codex.** Prefer the `codex:*` skills/agents when the Codex plugin is installed; otherwise use the Codex CLI directly: `codex exec -m gpt-5.6-sol -c model_reasoning_effort=high "<brief>"` (`=xhigh` for adversarial passes). If the CLI is missing or unauthenticated, run the review on a fresh `opus-5` instance instead and note the substitution.

## Communicating model use (always)

Be transparent about which model and effort did what — the user decides whether the routing was right, so they need to see it.

- **In chat:** state up front which model and effort you're using for which part, and call out escalations or substitutions as they happen. Say it when you dispatch, not only if asked.
- **In tickets:** record model + effort per part in the closing comment. One line per part: `Migration + backfill: opus-5 medium. Report view + copy: opus-5 high. Review: gpt-5.6-sol xhigh.`
- **In PR descriptions:** add a short **Models used** section mapping model + effort → the part it produced, including escalations and who reviewed.
