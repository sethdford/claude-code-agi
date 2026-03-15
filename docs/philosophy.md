# Claude Code AGI: 10 Autonomous Capabilities

This document explains the core AGI capabilities built into Claude Code and why each matters for autonomous AI development.

## 1. Session Memory

**What:** Persistent context across sessions via hooks and memory files.

**Why:** Most agents forget what happened after the session ends. Claude Code captures learned patterns, architectural decisions, and failure modes automatically, then injects them into future sessions. This prevents the same mistakes and accelerates decision-making.

**How it works:**

- Failures are automatically captured in `.claude/agent-memory/` (shared across projects)
- Project-level lessons persist in `.claude/lessons.md` (per-project)
- Hooks fire at key lifecycle events (`SessionStart`, `PostToolUse`, etc.)
- Memory is injected into every session start, so you don't repeat mistakes

**Example:**

```
Session 1: Deploy fails with "memory limit exceeded" because functions are too large
→ Lesson captured: "When bundling Firebase Functions, compress dependencies with --production"

Session 2: Agent reads lesson, knows to add the flag immediately, deploy succeeds
```

## 2. Self-Improvement

**What:** Agents learn from corrections and automatically prevent repeated mistakes.

**Why:** Without self-improvement, the same bug gets debugged multiple times. Claude Code systematize corrections into reusable rules.

**How it works:**

- When corrected, the agent appends the lesson to `.claude/lessons.md`
- Lessons are tagged with category (testing, deployment, architecture, etc.)
- At session start, relevant lessons are loaded and injected
- If a mistake repeats 3+ times, a hook rule is auto-suggested

**Example:**

```
User correction: "Don't use `jest.fn()` — we use Vitest. Use `vi.fn()` instead."
→ Lesson added: "Testing: Always use vi.fn() not jest.fn() (Vitest convention)"

Next session: Agent reads lesson, knows to use vi.fn() immediately without prompting
```

## 3. Proactive Action

**What:** Background monitoring and scheduled tasks via `/loop`.

**Why:** Humans don't watch logs 24/7. Agents should monitor health and take action autonomously.

**How it works:**

- `/loop 5m curl -s https://site.com -o /dev/null -w "Status: %{http_code}\n"` runs every 5 minutes
- `/loop 1h ./scripts/verify-all.sh` runs quality checks hourly
- Background tasks continue while you work on other things
- If a check fails, the agent reports and suggests remediation

**Example:**

```
Agent runs: /loop 1h ./scripts/check-analytics.sh
→ Detects missing GA4 events at 11 PM
→ Reports: "GA4 tracking down. Last event 3 hours ago. Likely deploy issue."
→ Suggests: "Check recent deployments with `git log --oneline -5`"
```

## 4. Production Awareness

**What:** Hooks check live systems at session start.

**Why:** Agents shouldn't work blind. They need to know if the service is healthy before making changes.

**How it works:**

- `SessionStart` hook runs production health checks (`curl`, `gcloud logs`, etc.)
- Captures recent deployments and error rate
- If service is degraded, agent knows to prioritize fixes over features
- Hook runs automatically; no user action required

**Example:**

```
Hook fires at session start:
- Checks: curl https://site.com → 200 OK
- Checks: gcloud logging read 'severity>=ERROR' → 5 errors in last hour
- Reports: "Production healthy. Last deploy 2 hours ago. No recent errors."

Agent now has context: "Service is stable, safe to make changes"
```

## 5. Tool Creation

**What:** When a pattern repeats 3+ times, Claude Code suggests creating a tool (hook, skill, script, or rule).

**Why:** Repetitive tasks should be automated. Agents should build tools for their future selves.

**How it works:**

- Agent tracks repeated patterns (same debug steps, same checks, same fixes)
- After 3rd repetition, agent suggests: "This pattern repeats. Create a hook/script for it?"
- Creates `.claude/hooks/check-x.sh` or `.claude/rules/pattern.md`
- Future agents use the tool automatically

**Example:**

```
Repetition 1: Agent manually checks logs with gcloud logging read
Repetition 2: Agent checks logs again with same command
Repetition 3: Agent says "I've done this 3 times. Let me create a hook."
→ Creates: .claude/hooks/check-errors.sh
→ Adds to SessionStart hook
→ Future sessions auto-run the check
```

## 6. Cross-Project Learning

**What:** User-level memory files persist across all projects.

**Why:** Lessons from the AIM project should apply to every other project. Global memory prevents relearning the same patterns.

**How it works:**

- User memory stored in `~/.claude/agent-memory/` (outside any project)
- Lessons about "How to debug Firestore rules" apply everywhere
- "PostgreSQL connection pooling patterns" learned once, used everywhere
- Project-specific memory stored in `.claude/` (local only)

**Example:**

```
Project A (AIM): Agent learns "Firestore indexes must have composite fields ordered by specificity"
→ Lesson saved to ~/.claude/agent-memory/firestore-patterns.md

Project B (New project): Agent reads user-level memory, knows index pattern immediately
→ Avoids 30 minutes of debugging the same issue
```

## 7. Goal Persistence

**What:** Plans with checkboxes are tracked across sessions.

**Why:** Long-running projects span multiple days. Agents need to remember where they left off.

**How it works:**

- Plans written to `tasks/todo.md` with checkboxes
- Progress automatically tracked: `[x] Item 1`, `[ ] Item 2`
- At session start, agent loads the plan and resumes
- Completed work feeds into the next session's context

**Example:**

```
Session 1: Agent writes plan to tasks/todo.md
- [x] Fix TypeScript errors
- [ ] Add tests
- [ ] Deploy to production

Session 2: Agent reads plan, sees progress, continues from "Add tests"
```

## 8. Autonomous Error Recovery

**What:** Monitoring rules detect failures and propose fixes without waiting for the user.

**Why:** Errors don't care if a human is watching. Agents should detect and recover autonomously.

**How it works:**

- Hooks monitor for errors (test failures, deploy failures, linting errors)
- On error, hook captures root cause and suggests fix
- If fix is low-risk (code formatting, dependency update), agent applies it
- If fix is high-risk (data loss), agent proposes and waits for approval
- Next session loads the learnings so future errors are prevented

**Example:**

```
Deploy fails with "Function exceeds memory limit"
Hook detects the error:
→ Root cause: bundled dependencies too large
→ Suggests: "Run: pnpm install --only=production before bundling"
→ Agent applies fix and redeploys
→ Lesson saved: "Always use --only=production for dependency bundling"

Next session: Agent knows the fix immediately if limit is hit again
```

## 9. Quality Feedback Loop

**What:** Deployment history records outcomes and correlates with quality metrics.

**Why:** Without feedback, agents don't know if their changes improved or worsened the system.

**How it works:**

- `.claude/deploy-history.md` tracks every deploy: timestamp, author, commit, outcome (success/failure)
- If a deploy causes errors, the next session knows which commit to revert
- Quality metrics (test coverage, performance, error rate) are tracked
- Agent uses this feedback to avoid patterns that break production

**Example:**

```
Deploy history:
2026-03-15 12:00 — Commit abc123 (refactor auth) → Success, errors: 0
2026-03-15 13:00 — Commit def456 (new feature) → Failure, errors: 15

Next session: Agent avoids the pattern from def456, learns from abc123
```

## 10. Collaborative Intelligence

**What:** Multiple agents work in parallel with shared context and coordination.

**Why:** Complex problems require different specialists. Agent teams divide work and share learnings.

**How it works:**

- Main agent spawns specialist subagents (explorer, reviewer, tester, etc.)
- Each subagent gets a focused task and a subset of context
- Subagents read shared files (`.claude/lessons.md`, standards) for continuity
- Results feed back into main agent context
- All agents contribute to shared memory for future sessions

**Example:**

```
Main agent splits work:
→ Explorer agent: "Find all TypeScript errors in the codebase" (read-only, fast)
→ Fixer agent: "Fix the top 5 errors" (in a worktree, isolated)
→ Reviewer agent: "Review the fixes for security issues"
→ Tester agent: "Run full test suite"

All agents share access to .claude/lessons.md
If explorer finds a pattern (e.g., "all errors are import paths"), lesson is saved
Fixer agent reads the lesson and fixes faster
```

---

## Why AGI Matters

Traditional automation is **brittle**: one unexpected case breaks it. AGI automation is **learning**: each error teaches the agent, preventing the same mistake later.

With these 10 capabilities, Claude Code agents can:

1. **Learn** — Capture lessons from every session
2. **Remember** — Persist context across days and projects
3. **Monitor** — Run background checks while you work
4. **Recover** — Fix failures autonomously
5. **Improve** — Build tools to prevent repeated mistakes
6. **Collaborate** — Divide work across specialist agents
7. **Feedback** — Track outcomes and learn from them
8. **Scale** — Handle bigger projects as learnings accumulate
9. **Persist** — Remember long-term goals across sessions
10. **Teach** — Share learnings across projects and teams

This is the path from automation to true artificial general intelligence in software development.
