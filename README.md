# claude-super-tooling

A Claude Code plugin marketplace. One plugin so far: `core`, a staged workflow
for working non-trivial engineering problems.

## Install

```powershell
claude plugin marketplace add D:/Projects/claude-super-tooling
claude plugin install core@super-tooling
```

While developing, skip installing and load from disk instead:

```powershell
claude --plugin-dir ./plugins
```

Then `/reload-plugins` after each edit. `scripts/dev.ps1` wraps this.

## What `core` does

`/core:solve` orchestrates a problem from investigation through verified
implementation. It runs on the main thread — subagents have no `AskUserQuestion`
tool, so an orchestrator that needs to stop and ask you something cannot itself
be a subagent.

```
  start at ZERO ceremony
         |
  obvious + contained? -- yes --> do it. verify. done.
         | no
  FRAME      2-3 framer agents, parallel, non-overlapping scopes
             agreement -> probably settled
             disagreement -> that is the finding
         |
  RED-TEAM   fresh agent tries to falsify the load-bearing claims
         |
  brief.md   problem - decision - plan w/ verify cmds
             what we will NOT do - unknowns
         |
  === COMMIT GATE ===   the one routine gate
         |
  EXECUTE    per step: implement -> verify RUNS -> log
             fails -> one repair, then stop
             irreversible -> stop and ask, wherever it falls
             approach wrong -> amend brief, re-gate
         |
  REPORT     Passed | Failed | NOT DONE
```

### The four ideas it is built on

**Escalate, don't triage.** Classification up front happens when you know least
about the task. `solve` starts at zero ceremony and escalates on evidence —
unknown cause, >3 files, contradicted assumption, irreversible action ahead. Its
worst case self-corrects; upfront triage's worst case does not.

**Disagreement is the signal.** Two investigators with non-overlapping scopes
that never see each other's work. Where they converge is weak evidence. Where
they diverge is where the problem actually is. This is what independent contexts
are genuinely good for.

**Falsify before committing.** The dominant failure is a confidently wrong
premise that everything downstream inherits. `red-team` receives the claims
without the reasoning that produced them and tries to break them. A claim that
is plausible but unchecked comes back `UNVERIFIABLE`, never `SURVIVED`.

**Verification is an invariant, not a stage.** A step is not done until its
verify command has actually run. `build-runner` executes it in an isolated
context and returns only failures. The report's `NOT DONE` section is mandatory,
because the alternative to admitting something is unverified is implying it works.

### One gate, plus risk-triggered stops

There is a single routine gate, at the commitment point: after the problem is
understood, before meaningful code exists. Separate approval for each stage
trains you to skim, and a gate you skim is worse than no gate — it manufactures
confidence without supplying any.

Irreversible steps stop regardless of where they fall in an approved plan.
Migrations, deletes, force-pushes, anything leaving the machine.

## Artifacts

Written to `.claude/work/<yyyy-mm-dd>-<slug>/`, gitignored. Split by read
frequency:

- **`brief.md`** — the contract. Re-read at every execute step, so capped at 100
  lines. Edit it to steer.
- **`log.md`** — append-only. Verify output and what was learned. Grepped, never
  read whole.

## Components

| | |
|---|---|
| `skills/solve` | orchestrator, main thread, owns the gate |
| `agents/framer` | read-only investigator for one scope |
| `agents/red-team` | adversarial claim checker |
| `agents/build-runner` | runs builds and tests, returns only failures |

## Layout

```
.claude-plugin/marketplace.json
plugins/core/
  .claude-plugin/plugin.json
  skills/solve/SKILL.md
  skills/solve/templates/{brief,log}.md
  agents/{framer,red-team,build-runner}.md
```

Component directories live at the plugin root, never inside `.claude-plugin/`.
Only `plugin.json` goes there.

Note: `solve` must never be given `context: fork`. That strips
`AskUserQuestion`, and the commit gate stops working silently.
