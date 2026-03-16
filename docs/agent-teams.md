# Agent Teams

Agent teams are multiple Claude instances coordinating in parallel to accomplish work faster and with better separation of concerns than sequential execution or single-agent delegation.

## What Agent Teams Are

An agent team is a group of independent Claude Code agents working simultaneously on a shared codebase. Each agent:

- Runs its own full Claude Code session (separate context window, separate tool access)
- Can read and write files, run commands, make decisions autonomously
- Sees a shared task list and coordinates via task claiming
- Communicates via direct messages or broadcast announcements
- Can escalate to a human lead for approval (plan mode)

Teams scale from 2 agents (parallel exploration) to 8+ agents (large-scale refactors), but returns diminish beyond 5-6.

## When to Use Teams vs Subagents

| Scenario | Agent Team | Subagent |
|----------|-----------|----------|
| Auditing entire large codebase | Team (7+ agents in parallel) | Single subagent (sequential) |
| Parallel independent features | Team (each agent owns files) | Subagent (single feature) |
| Research + implementation | Team (researcher, implementer) | Subagent (delegated task) |
| Risky changes with review | Team (proposer + reviewer) | Subagent (requires approval) |
| Long builds/tests | Background task (concurrent) | Subagent in background |

**Key rule:** Teams are for **parallel independent work**. Subagents are for **delegated serial tasks**.

## Team Composition

### Optimal Size: 3-5 Agents

- **2 agents**: Overkill for most tasks; use subagents instead
- **3 agents**: Sweet spot for small features (frontend, backend, tests)
- **5 agents**: Good for medium refactors or audits
- **7+ agents**: Use for large-scale work (codebase audit, multi-package migration)
- **>8 agents**: Coordination overhead exceeds parallelism gains

### Agent Roles

Assign each agent a **different scope** to avoid merge conflicts:

1. **Researcher** — Explores codebase, builds understanding, generates plan
2. **Implementer-A** — Writes code for module A
3. **Implementer-B** — Writes code for module B
4. **Reviewer** — Verifies changes, runs tests, checks governance
5. **Lead** — Coordinates, resolves blockers, approves risky decisions

**File isolation is critical.** Each agent should own 2-3 specific files/directories and only touch those. Overlapping file ownership causes merge conflicts and wasted context on conflict resolution.

## Setting Up Agent Teams

### Enable Teams (One-Time)

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

Or in `.zshrc`:
```bash
echo 'export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1' >> ~/.zshrc
source ~/.zshrc
```

### Create a Team Session

```bash
shipwright session audit-team --template multi-agent
```

This creates:
- A tmux session named `claude-audit-team` (with lambda icon in status bar)
- 5 panes (one per agent)
- Each pane titled `audit-team-researcher`, `audit-team-impl-a`, etc.
- Shared task list in `.claude/team-tasks.md`

### Manual Team Setup (Advanced)

If you need fine-grained control:

```bash
# Start a main Claude Code session
claude

# In a second terminal, start a teammate:
claude --teammate analyzer --parent-session-id <id-from-main>

# In a third terminal, start another:
claude --teammate reviewer --parent-session-id <id-from-main>
```

## Display Modes

Agent teams can run in three display modes. Configure in `.claude/settings.json`:

```json
{
  "teamMateMode": "auto"
}
```

### 1. Auto Mode (Recommended)

```json
{ "teamMateMode": "auto" }
```

Claude detects your environment:
- **In tmux**: launches team members as new panes
- **In iTerm/Terminal**: launches new windows
- **In VS Code terminal**: launches new terminals
- **Fallback**: in-process mode

### 2. tmux Mode

```json
{ "teamMateMode": "tmux" }
```

All agents run as panes in a single tmux session. Best for:
- Remote SSH work (all agents in one connection)
- High-context work (shared panes visible)
- Minimal window clutter

**tmux conventions:**
- Prefix key: `Ctrl+a` (not `Ctrl+b`)
- Layouts: `prefix + M-1` (horizontal), `M-2` (vertical), `M-3` (tiled)
- Zoom: `prefix + G` (focus one pane)
- Capture: `prefix + M-s` (current), `prefix + M-a` (all)
- Session name: `claude-<team-name>` (shows lambda icon)
- Pane title: `<team>-<role>` (visible in borders)

Set pane title in a hook:
```bash
printf '\033]2;team-name-role\033\\'
```

### 3. In-Process Mode

```json
{ "teamMateMode": "in-process" }
```

All agents run in the same terminal sequentially. Simplest but slowest — agents block each other.

## Task Coordination

### Shared Task List

All team members see and work from `.claude/team-tasks.md`:

```markdown
# Team Task List

## To Do
- [ ] Research audit scope (Researcher)
- [ ] Audit auth module (Impl-A)
- [ ] Audit API routes (Impl-B)
- [ ] Compile findings (Researcher)

## In Progress
- [ ] Audit utility functions (Impl-A — claimed 3:45 PM)

## Done
- [ ] Setup team environment (Lead — completed 3:30 PM)
```

### Claiming Tasks

An agent claims a task by marking it In Progress with a timestamp:

```markdown
- [ ] Audit API routes (Impl-B — claimed 3:45 PM)
```

This signals other agents: "Don't do this task, I'm on it."

When done:
```markdown
- [x] Audit API routes (Impl-B — completed 4:10 PM, findings in docs/audit-api.md)
```

### Task Dependencies

If Task B depends on Task A, mark it explicitly:

```markdown
- [x] Build analyzer (Impl-A — completed)

## Blocked Until Above Completes
- [ ] Run analyzer on codebase (Impl-B)
```

When Task A is done, the Impl-B agent moves their task to In Progress.

### Creating Subtasks

For complex tasks, break into subtasks:

```markdown
- [ ] Refactor payment module (Impl-A)
  - [ ] Extract PaymentProcessor class
  - [ ] Add unit tests
  - [ ] Integration test with Stripe
  - [ ] Performance baseline
```

Each subtask is claimed individually.

## Communication

### Direct Messages

Agents can send direct messages to teammates:

```
/message Reviewer: I found a potential security issue in auth.ts line 42. Can you review?
```

The Reviewer sees this in their context and can respond.

**Use sparingly.** Direct messages should be:
- Blockers ("Can't proceed without answer")
- Security/safety concerns
- Design decisions that affect multiple agents

Most coordination happens via the task list and async findings docs.

### Broadcast Announcements

For team-wide updates:

```
/broadcast: I found a critical pattern. All agents: check docs/pattern-alert.md before proceeding.
```

All agents are notified.

### Async Findings

Agents document findings in separate files that others can read:

- `docs/audit-auth.md` — Impl-A's findings
- `docs/audit-api.md` — Impl-B's findings
- `docs/compile-findings.md` — Researcher's synthesis

This keeps contexts focused and allows async work.

## Best Practices

### 1. File Isolation (Critical)

Assign each agent 2-3 specific files/directories:

**Good:**
- Impl-A: `src/auth/` and `src/utils/validators.ts`
- Impl-B: `src/api/` and `src/middleware/`
- Impl-C: `src/db/` and `src/types/`

**Bad:**
- Impl-A: "Anything that needs fixing"
- Impl-B: "Anything else"
(This causes merge conflicts on every file touched.)

### 2. Task Count: 5-6 Per Agent

Keep task lists lean. 10+ tasks per agent causes context thrashing and dropped context.

```markdown
## For Impl-A (Current Sprint)
- [ ] Audit auth patterns
- [ ] Write auth.test.ts
- [ ] Document findings
- [ ] Review Impl-B's changes
```

### 3. Research Before Implementation

Start every team session with a Researcher agent:

1. Researcher explores codebase, builds understanding
2. Researcher writes a 5-minute plan
3. Team reviews plan (60 seconds)
4. Implementers start work with clear scope
5. Researcher updates task list as blockers emerge

### 4. Plan Mode for Risky Work

When an agent is making a risky change (security, data migration, architecture), use plan mode:

```markdown
Agent: Impl-A (plan mode)
Task: Migrate payment schema v1 → v2
Scope: Limited to src/payments/ only
Approval: Lead must review plan before implementation
```

The Impl-A agent writes a detailed plan in a `proposal-*.md` file, then the Lead reviews and approves before code is written.

### 5. Post-Mortem on Conflict

If two agents accidentally edit the same file:

1. Don't panic — git tracks it
2. Check which changes are valid
3. Document the lesson: "Impl-A and Impl-B both touched src/utils.ts. Reassign to single owner."
4. Add to `.claude/lessons.md` for future teams

## Shutdown

### Graceful Shutdown

When done, agents send a shutdown message:

```
/shutdown_request: Task list is complete. Ready to merge and verify.
```

The Lead coordinates:
1. Check all agents have no open tasks
2. Run final integration tests
3. Review merged changes
4. Shut down each agent explicitly

### Forced Shutdown

If an agent is stuck or unresponsive:

```bash
Ctrl+C  # Kill the specific agent's session
```

Or from the Lead's session:

```
/kill-teammate Impl-A
```

### Session Cleanup

After team completes:

```bash
shipwright cleanup --force   # Kill orphaned tmux sessions
```

## Example: Codebase Audit in 2 Minutes

**Setup (30 seconds):**
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
shipwright session audit --template multi-agent
```

**Team composition:**
- Researcher (lead)
- Auditor-A (auth, crypto, secrets)
- Auditor-B (API, permissions, rate limiting)
- Auditor-C (data, queries, transactions)
- Reviewer (compiles findings, checks severity)

**Task list:**
```markdown
## In Progress (All Start Here)
- [ ] Read codebase structure, 10-min overview (Researcher)

## Waiting for Researcher Complete
- [ ] Audit auth patterns (Auditor-A)
- [ ] Audit API surface (Auditor-B)
- [ ] Audit data access (Auditor-C)

## Waiting for Auditors Complete
- [ ] Compile findings by severity (Reviewer)
- [ ] Write executive summary (Researcher)
```

**Execution:**
1. Researcher runs `find . -name "*.ts" | wc -l` → 247 files. Spends 10 min reading key directories, writes `codebase-overview.md`
2. Researcher updates task list: "Overview done. Start audits."
3. All three Auditors claim their task simultaneously
4. Auditor-A: 8 minutes finding potential security issues
5. Auditor-B: 7 minutes finding rate limiting gaps
6. Auditor-C: 6 minutes finding missing transaction guards
7. Each documents findings in `audit-{category}.md`
8. Reviewer: Reads all three audit files, cross-references, writes `SECURITY_AUDIT_FINAL.md` with severity levels
9. Researcher writes executive summary: "Found 3 critical, 7 high, 12 medium issues"

**Total time:** ~20-25 minutes (vs 2-3 hours solo)

**Key factor:** Parallel work on different code sections. No agent had to wait for another, and file isolation prevented merge conflicts.

## Scaling Guidelines

| Team Size | Best For | Coordination | Overhead |
|-----------|----------|--------------|----------|
| 2 agents | Small feature, initial exploration | Minimal (direct message) | Low |
| 3 agents | Feature team (UI/API/DB) | Task list + async docs | Low |
| 5 agents | Medium refactor, codebase audit | Task list + daily sync | Medium |
| 7+ agents | Large migration, multi-package work | Task list + lead coordination | High |

Beyond 7 agents, spend more time coordinating than coding. Use only for truly massive work.

## Troubleshooting

### Agent A and Agent B Both Edited the Same File

**Prevention:** Better file assignment at the start.

**Recovery:**
```bash
git status  # See the conflict
git diff src/utils.ts  # Review both versions
# Edit manually, keeping the better version
git add src/utils.ts
git commit -m "Merge: Impl-A and Impl-B changes to utils"
```

### Agent Is Stuck / Not Responding

From your session:
```
/message [Agent Name]: Hey, are you stuck? What's your blocker?
```

If no response in 2 minutes:
```
/kill-teammate [Agent Name]
```

Then review what they were doing and reassign the task.

### Task List Gets Out of Sync

One agent finishes but forgets to update the task list:

```
/broadcast: Please check .claude/team-tasks.md and mark your completed tasks. Thanks!
```

Or the Lead manually updates it:
```bash
$EDITOR .claude/team-tasks.md
```

### Merge Conflicts on Final Commit

If three agents modified `index.ts`:

```bash
git merge --no-ff --no-commit agent-a-branch
git diff  # See the conflicts
# Resolve manually — keep the cleanest version
git add index.ts
git commit -m "Merge: three agents' changes to index"
```

Test after merge:
```bash
pnpm typecheck
pnpm test
```
