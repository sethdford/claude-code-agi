# Background Tasks

Background tasks let you run long-running operations (test suites, builds, deploys) while continuing to work on other things in the same session. Your AI doesn't block waiting — it stays responsive.

## What Background Tasks Are

A background task is a long-running operation that:

- Runs asynchronously in the background
- Doesn't block your main Claude Code session
- You can check on progress anytime
- Can be killed or paused
- Outputs logs you can review later

**Key benefit:** Run a full test suite (10 minutes) while you write code, deploy while you review, or build while you chat.

## Starting a Background Task

### From a Running Command: Ctrl+B

You're running a long command:

```bash
pnpm test
```

After a few seconds, realize it will take 10 minutes. Press **Ctrl+B**:

```
[Current task backgrounded]
Task ID: bg-1234
Output: /Users/me/.claude/tasks/bg-1234/output.log
Status: pnpm test [Running]
```

The command keeps running in the background. Your prompt returns.

### From a Subagent: `background: true`

Define a long-running subagent that starts in background:

```yaml
agents:
  - name: test-suite
    role: "Run full test suite"
    background: true
    permissions: "dontAsk"  # Pre-approved (no permission prompts)
    instructions: |
      Run: pnpm test --coverage
      Report: Coverage % when done
```

The agent starts automatically in background. You're not blocked.

## Managing Background Tasks

### List All Background Tasks

```
/tasks
```

**Output:**
```
Background Tasks:
1. bg-1234 [pnpm test] — Running (5/15 min)
2. bg-1235 [pnpm build] — Running (2/5 min)
3. bg-1236 [firebase deploy] — Queued (starts in 5s)

Active: 2 running, 1 queued, 0 completed
```

### Check a Specific Task

```
/tasks show bg-1234
```

**Output:**
```
Task ID: bg-1234
Command: pnpm test
Status: Running (8/15 min estimated)
Progress: 37 tests pass, 0 fail
Output: /Users/me/.claude/tasks/bg-1234/output.log
Last update: 30s ago
```

### View Task Logs

```bash
tail -f /Users/me/.claude/tasks/bg-1234/output.log
```

Or in Claude:

```
/tasks log bg-1234
```

Shows last 50 lines of output.

### Stop a Background Task

Press **Ctrl+F** (twice):

```
[Stopping background tasks...]
Stopped: bg-1234 (pnpm test)
Stopped: bg-1235 (pnpm build)
Backgrounded tasks: 0
```

Or stop a specific task:

```
/tasks kill bg-1234
```

### Pause/Resume

Pause a task:

```
/tasks pause bg-1234
```

Resume later:

```
/tasks resume bg-1234
```

## Pre-Approved Background Agents

Background agents can't ask permission questions (they'd block the whole background system). Instead, define their permissions upfront:

```yaml
agents:
  - name: test-runner
    role: "Run tests continuously"
    background: true
    model: sonnet  # Use faster model for background work
    permissions:
      mode: "acceptEdits"  # Auto-accept file edits
      tools:
        - bash      # Always allowed
        - read      # Always allowed
        - edit      # Always allowed
        - glob      # Always allowed
    instructions: |
      Every 30 minutes:
      1. Run: pnpm test
      2. If failures, update docs/test-failures.md
      3. Report summary
```

The agent starts with these permissions pre-granted. No prompts.

## Common Patterns

### 1. Run Tests While Coding

```bash
# Start a test run in background
pnpm test

# Press Ctrl+B after a few seconds
[Backgrounded: pnpm test]

# Continue editing
# Open another file, make changes
```

Keep coding while tests run. When done:

```
/tasks
[bg-1234] pnpm test — PASS (47 tests, 0 fail)
```

### 2. Deploy While Reviewing Code

You're reviewing a PR. Deploy the previous version in background:

```
/tasks start firebase deploy
```

While deploy runs (5 minutes), review the PR. When done:

```
/tasks show bg-1234
Status: Deploy successful
```

### 3. Build and Test in Parallel

Start a build in background:

```
pnpm build
[Ctrl+B to background]
```

While it builds, run tests in the main session:

```
pnpm test
```

Both complete, neither blocked the other.

### 4. Continuous Monitoring

Define a background agent that watches your repo:

```yaml
agents:
  - name: monitor
    background: true
    task: |
      Loop every 5 minutes:
      1. Run: pnpm typecheck
      2. Run: pnpm lint
      3. Report: "✓ All clear" or "✗ <errors>"
```

Agent keeps running. You get updates every 5 minutes without asking.

### 5. Multi-Job Queue

Start multiple tasks:

```
/tasks start pnpm test
/tasks start pnpm build
/tasks start pnpm typecheck
/tasks start firebase deploy
```

All queue and run concurrently (or sequentially if resources are tight). Check status:

```
/tasks
[bg-1] pnpm test — 40% complete
[bg-2] pnpm build — 60% complete
[bg-3] pnpm typecheck — Running
[bg-4] firebase deploy — Queued
```

## Output and Logging

### Real-Time Monitoring

View live output:

```bash
tail -f ~/.claude/tasks/bg-1234/output.log
```

### Summary Reports

When a task completes, Claude reports:

```
Background Task Complete: bg-1234 [pnpm test]
Duration: 12 minutes 34 seconds
Result: ✓ PASS (47 tests, 0 fail)
Summary: All tests pass. Ready to deploy.
```

### Parsing Task Output

Extract specific metrics from a test run:

```
/tasks parse bg-1234 "coverage:"
```

Returns:
```
Coverage: 78.5% lines, 82% functions
```

## Permissions and Safety

### Pre-Approved Permissions

Background agents must have explicit permissions before starting:

```yaml
permissions:
  mode: "acceptEdits"  # Auto-accept file changes
  tools:
    - bash       # Shell access
    - read       # File reads
    - edit       # File writes
    - glob       # Pattern matching
```

### Denied Permissions

Some actions always require human approval, even in background:

- Creating new accounts
- Permanent deletions
- Modifying security settings
- Sharing sensitive documents
- Making financial transactions

If a background task tries these, it fails and alerts you:

```
Background Task Alert: bg-1234 [permission-denied]
Agent tried: Create AWS IAM user
Status: BLOCKED (requires human approval)
Recommendation: Review task definition
```

### Timeout Protection

Long-running agents have a timeout:

```yaml
maxTurns: 50           # Max 50 iterations
timeout: 3600          # 1 hour max runtime
```

If exceeded, the agent is killed:

```
Background Task Timeout: bg-1234 [pnpm test]
Time limit exceeded: 1h
Gracefully stopped. Review output for progress.
```

## Best Practices

### 1. Use Background for Genuinely Long Tasks

**Good candidates:**
- Full test suite (5-20 minutes)
- Full build (3-10 minutes)
- Deploy to production (5-15 minutes)
- Database migration (10-60 minutes)

**Bad candidates:**
- Quick lints (30 seconds) — Just wait
- Typecheck (1 minute) — Just wait
- Single test file (2 seconds) — Just wait

### 2. Monitor Critical Deploys

Don't fire-and-forget a production deploy. Background it but check periodically:

```
/tasks start firebase deploy

# While deploy runs:
/tasks show deploy-bg

# Every 2 minutes:
curl https://yoursite.com -o /dev/null -w "Status: %{http_code}\n"
```

If the site goes down mid-deploy, you'll catch it quickly.

### 3. Pre-Define Recurring Tasks

Instead of starting background tasks manually, define them in config:

```json
{
  "backgroundTasks": [
    {
      "name": "nightly-tests",
      "schedule": "0 2 * * *",
      "command": "pnpm test",
      "onFailure": "email"
    },
    {
      "name": "hourly-lint",
      "schedule": "0 * * * *",
      "command": "pnpm lint",
      "onFailure": "log"
    }
  ]
}
```

### 4. Kill Background Tasks on Deploy

Before a critical deploy, ensure old test runs finish:

```
/tasks kill test-bg
/tasks kill build-bg

# Now deploy cleanly
firebase deploy
```

### 5. Review Failure Logs Immediately

If a background task fails:

```
/tasks log bg-1234
```

Scan the output. If it's a transient error (network timeout), retry:

```
/tasks resume bg-1234
```

If it's a real failure, fix the code and re-run.

## Real-World Example: Deploy Validation

You're deploying a major feature. Set up background tasks to validate:

**Step 1: Start deploy in background**

```
/tasks start ./scripts/deploy-consultant.sh
```

**Step 2: While deploying, run tests in foreground**

```
pnpm test --coverage
```

**Step 3: Monitor both**

```
/tasks
[bg-1] Deploy — 40% (4/10 steps)
[fg] Tests — 55/47 pass
```

**Step 4: When tests complete, check deploy**

```
/tasks show bg-1
Status: Deploy successful (8 min 32s)
Result: ✓ All functions deployed, firestore rules updated, indexes created
```

**Step 5: Run smoke tests**

```
curl -s https://gettheconsultant.com/ -o /dev/null -w "Status: %{http_code}\n"
# Output: Status: 200 ✓
```

**Timeline (total: 12 minutes):**
- 0:00 — Deploy starts in background
- 0:15 — Tests start in foreground (deploy 25% done)
- 8:00 — Tests complete, deploy 95% done
- 8:30 — Deploy completes
- 8:45 — Smoke test passes

Without background tasks: sequential (deploy 8m + tests 8m = 16m). With background: parallel (8-9m). Saved 7-8 minutes.

## Troubleshooting

### Task Is "Stuck" (Not Making Progress)

Check the logs:

```bash
tail -50 ~/.claude/tasks/bg-1234/output.log
```

Common causes:
- Waiting for user input (shouldn't happen with pre-approved agents)
- Hung process (network timeout, disk full)
- Rate limiting

**Fix:**
```
/tasks kill bg-1234
# Fix the underlying issue
/tasks start bg-1234
```

### Task Output Is Missing

Logs are written to `~/.claude/tasks/bg-XXXX/output.log`. If missing:

```bash
ls -la ~/.claude/tasks/
```

Ensure the directory exists. If tasks are in `/tmp/` (system temp), they may be cleared on reboot.

### Too Many Background Tasks Queued

Limit concurrent tasks:

```json
{
  "maxBackgroundTasks": 3
}
```

Additional tasks queue and run when others complete.

### Background Agent Quit Unexpectedly

Check why:

```
/tasks show bg-1234
Error: Agent crashed. Review output.

/tasks log bg-1234
[Error] TypeError: Cannot read property 'length' of undefined
[Error] Stack trace: ...
```

Fix the code, then re-run.

### Deploy Backgrounded But Site Went Down

Kill the deploy:

```
/tasks kill deploy-bg
```

Investigate:

```bash
gcloud run revisions list --project=my-project
gcloud run revisions describe <revision-id>
```

Rollback if needed:

```bash
gcloud run deploy my-service --image=gcr.io/my-project/my-service:last-known-good
```
