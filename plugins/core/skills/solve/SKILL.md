---
name: solve
description: Work a non-trivial engineering problem end to end - investigate from independent angles, falsify the leading theory, agree an approach, then implement with verification. Use when a cause is unknown, an approach is contested, a change spans several files, or a task is ambiguous. Not for changes that are already fully specified.
---

# solve

You are the orchestrator and you run on the **main thread**. Subagents do the
expensive work; you hold the gate. Never delegate the gate — subagents have no
`AskUserQuestion` tool and cannot ask the user anything.

Do not add `context: fork` to this skill. It would strip `AskUserQuestion` and
the commitment gate would silently stop working.

## Ladder — start at zero ceremony

Do not classify the task up front and commit to that classification. You know
least at the start. Begin at the cheapest rung and escalate when evidence
arrives.

**Rung 0 — just do it.** The change is stated, contained, and you have no open
questions. Make it, run its verify command, report. No files, no agents, no gate.

**Escalate when any of these becomes true, including mid-task:**

- the cause is unknown, or you are inferring it rather than confirming it
- more than ~3 files will change
- two plausible approaches with different blast radius
- evidence contradicts something you already assumed
- an irreversible action is ahead: migration, delete, force-push, external call

State which rung you are on in one line, and say so again whenever you escalate.

## Rung 1 — FRAME

Create `.claude/work/<yyyy-mm-dd>-<slug>/`.

Dispatch **two or three `framer` agents in parallel, in a single message**, each
given a *different, explicitly stated scope*. They must not overlap — isolation
is what makes their disagreement meaningful. Typical splits:

| Problem | Scope A | Scope B | Scope C |
|---|---|---|---|
| Bug, unknown cause | the code path itself | what changed recently: git, deploy, deps | runtime, config, infra |
| New feature | how this codebase does it today | constraints: data model, auth, API contract | prior art, library options |
| Performance | the hot path | data access and query shape | infrastructure and limits |

Reconcile their reports, and write the reconciliation down:

- **Where they agree** — treat as probably settled, and state what it rules out.
- **Where they disagree** — this is the finding. Do not average them and do not
  pick the more confident one. Competing causes predict *different symptoms*.
  Name the symptom that distinguishes them, then go check which one is real.

## Rung 1 — RED-TEAM

Before writing the brief, dispatch `red-team` against the load-bearing claims —
the ones the whole approach rests on. Give it the claims, **not** the reasoning
that produced them.

It returns each claim as FALSIFIED, SURVIVED, or UNVERIFIABLE with evidence. A
claim that is merely plausible and unchecked is UNVERIFIABLE, not SURVIVED.

If your leading theory is falsified, return to FRAME. Do not proceed with a
weakened version of a theory that failed.

## Rung 1 — brief.md

Write `brief.md` from `templates/brief.md`. Hard rules:

- **Under 100 lines.** It is re-read at every execute step. Detail belongs in
  `log.md`.
- **Every plan step carries a verify command** that can actually be run. A step
  you cannot verify is a step you cannot call done — say so in the step itself.
- **Mark irreversible steps with the warning sign.**
- **`We will NOT` is required** and must be specific. This is what stops scope drift.
- Record rejected theories and why. The rejections are as useful as the decision.

## COMMIT GATE

Stop here. This is the only routine gate, so make it worth reading. In chat, in
under eight lines: the cause and your confidence in it, the decision, where you
will stop again, and a pointer to `brief.md`.

Then wait. Do not begin implementing. The user steers either by replying or by
editing `brief.md` — re-read it after any reply.

## Rung 2 — EXECUTE

Work the approved plan. For each step:

1. Implement it.
2. **Run its verify command.** Use `build-runner` for builds and test suites so
   their output does not land in this context. Never mark a step done on belief.
3. Append the result to `log.md`.

Then:

- **Verify passes** → next step.
- **Verify fails** → log it, make one repair attempt, then stop and report. Do
  not keep trying variations.
- **Irreversible step** → stop and ask, every time, regardless of where it falls
  in the plan. Show exactly what will change before asking.
- **Reality contradicts the brief** → distinguish two cases. If the *details*
  moved (a test needs updating, a file is elsewhere), adapt and log it. If the
  *approach* is wrong, stop, amend `brief.md`, and return to the gate.

Re-read `brief.md` before each step. It is the defense against drift.

## REPORT

Three sections, all required, in this order:

- **Passed** — steps completed, with the verify output that proves it
- **Failed** — what broke, and where work stopped
- **NOT DONE** — everything skipped, deferred, or unverifiable, and why

`NOT DONE` is never omitted. If it is genuinely empty, write "nothing". If you
could not verify something in this environment, it belongs here — not in Passed.
