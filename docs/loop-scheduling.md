# Loop Scheduling

The `/loop` command runs a prompt or command on a recurring interval, perfect for monitoring, background checks, and continuous verification.

## What `/loop` Does

`/loop` executes a task repeatedly at a fixed interval while you continue working. The task runs in the background, outputs appear in your session, and you can cancel anytime.

## Syntax

```
/loop <interval> <prompt or command>
```

### Intervals

- `30s` — every 30 seconds
- `5m` — every 5 minutes
- `1h` — every 1 hour
- `24h` — every 24 hours
- `7d` — every 7 days

### Intervals: Supported Formats

- Seconds: `30s`, `45s`
- Minutes: `5m`, `15m`
- Hours: `1h`, `4h`, `12h`
- Days: `1d`, `7d`, `30d`

### Task Format

The task can be:
- **A shell command**: `/loop 5m curl -s https://yoursite.com/ -o /dev/null -w "Status: %{http_code}\n"`
- **A natural language prompt**: `/loop 1h check if there are new error logs and summarize`
- **A bash script**: `/loop 10m ./scripts/verify-all.sh`
- **Mixed**: `/loop 30m run tests and check coverage`

## Session Lifecycle

- **Active only in current session:** Loops die when you exit Claude Code
- **Auto-expiry:** Recurring tasks expire after 3 days (safety measure)
- **Manual cancellation:** Press `Ctrl+C` or type `/loop cancel`
- **Concurrent limits:** Up to 50 concurrent scheduled tasks

## Common Recipes

### 1. Site Health Monitoring

```
/loop 1h curl -s https://yoursite.com/ -o /dev/null -w "Site: %{http_code}\n"
```

**Output:**
```
[15:30] Site: 200
[16:30] Site: 200
[17:30] Site: 503 ← Alert!
```

### 2. Drift Detection (Verify All)

```
/loop 4h ./scripts/verify-all.sh
```

Runs format check, typecheck, tests, and linting every 4 hours. Good for:
- Catching regressions while you work
- Detecting environment drift
- Finding broken tests before push

**Output snippet:**
```
[14:00] Running format check... ✓ PASS
[14:05] Running typecheck... ✗ FAIL (3 errors in auth.ts)
       → Fix: Run `pnpm typecheck` locally
[18:00] Re-running... ✓ PASS (fixed)
```

### 3. Issue Triage

```
/loop 24h check for new GitHub issues in the repo and provide a summary
```

Runs daily, listing all new issues with priority:

**Output:**
```
[Daily 09:00] New Issues Summary:
- #234 [bug] Auth crash on Safari (Critical)
- #235 [feature] Dark mode support (Nice-to-have)
- #236 [docs] Update README (Maintenance)

Recommendation: Address #234 first
```

### 4. CI Watchdog

```
/loop 30m run pnpm test and report failures
```

Watches for test failures every 30 minutes. Alerts you before you push broken code.

**Output:**
```
[15:30] All tests pass ✓
[16:00] 2 tests failing ✗
  - src/__tests__/auth.test.ts (line 45)
  - src/__tests__/api.test.ts (line 120)
  → Found these errors 30min ago. Fix now?
```

### 5. Analytics Health Check

```
/loop 12h ./scripts/check-analytics.sh
```

Validates tracking setup, GA4 events, Web Vitals integration twice daily.

### 6. Deploy Status Monitoring

```
/loop 2h check last deploy status in Cloud Run and alert if failed
```

Monitors the last deploy:

**Output:**
```
[13:00] Last deploy: SUCCESS (2 hours ago)
[15:00] Last deploy: SUCCESS (4 hours ago)
[17:00] Last deploy: FAILED (8m ago, revision 47)
       Build error: TypeScript compilation failed
       → View logs: gcloud run revisions describe...
```

### 7. Brand Compliance Audit

```
/loop 24h ./scripts/check-brand-compliance.sh
```

Daily scan for blacklisted terms. Catches regressions overnight:

**Output:**
```
[09:00] Brand compliance ✓
[09:00] (Next run: tomorrow 09:00)

[Day 2 09:00] Brand compliance ✗
  Found 2 violations in packages/consultant/web/src/blog.tsx:
    - Line 23: "at the end of the day" → use "ultimately" instead
    - Line 87: "leverage" → use "use" or "employ" instead
  → Fix with: sed -i 's/leverage/use/g' ...
```

### 8. Performance Baseline Tracking

```
/loop 6h build and measure bundle size; compare to main branch
```

Tracks bundle growth:

**Output:**
```
[09:00] Bundle: 245 KB (main: 242 KB) +1.2%
[15:00] Bundle: 248 KB (main: 242 KB) +2.5% ← Degrading
[21:00] Bundle: 243 KB (main: 242 KB) +0.4% ✓ (fixed)
```

### 9. Database Migration Status

```
/loop 10m check Firebase migration progress and report blockers
```

Long-running migrations, checked every 10 minutes:

**Output:**
```
[14:00] Migration: 15% complete (5000 docs processed)
[14:10] Migration: 27% complete (9000 docs)
[14:20] Migration: 47% complete (15000 docs)
[14:30] Migration: 47% complete (BLOCKED — Firestore quota exceeded)
        → Reduced write rate; will resume in 30 minutes
[15:00] Migration: 62% complete
```

## Advanced Patterns

### Combining Commands with Logical Operators

```
/loop 1h pnpm test && pnpm build && pnpm typecheck
```

Runs all three; stops on first failure.

```
/loop 30m pnpm test || echo "Tests failed; check CI logs"
```

Runs tests; if they fail, echoes a reminder.

### Conditional Execution

```
/loop 1h test -f deploy.lock && echo "Deploy in progress, skipping checks" || ./scripts/verify-all.sh
```

Only runs verification if no deploy is in progress (checked via lock file).

### Piping and Filtering

```
/loop 1h curl -s https://api.example.com/health | jq '.status' | grep -v "ok" && echo "Alert: API unhealthy"
```

Checks API health, extracts status, alerts if not "ok".

### Writing Output to File

```
/loop 30m curl -s https://yoursite.com/ -o /dev/null -w "%{http_code}" >> ./health-check.log
```

Appends HTTP status code to a log file every 30 minutes. Review with:

```bash
tail -f ./health-check.log
```

### Cleanup

Remove old loop logs:

```bash
rm -f ./health-check.log
```

## Output and Notifications

### Output Behavior

Each `/loop` iteration outputs:
- **Timestamp** (when it ran)
- **Command result** (stdout/stderr)
- **Errors** (if any)
- **Next run time**

Example:
```
[15:30:42] Running: pnpm test
  ✓ 47 tests pass
  [Next run: 15:35:42]

[15:35:42] Running: pnpm test
  ✗ 1 test fails: src/__tests__/auth.test.ts line 45
  [Next run: 15:40:42]
```

### Error Handling

If a command fails, `/loop` continues:

```
/loop 1h ./scripts/deploy.sh
```

**Output:**
```
[10:00] Deploy failed (exit code 1)
        Error: Cannot connect to production server
        [Retry in 1h at 11:00]

[11:00] Deploy successful ✓
```

### Notifications

For long-running loops, ask for a notification at specific times:

```
/loop 24h run full regression suite; notify me when done
```

Outputs a visible notification when the task completes.

## Lifetime and Expiry

### Session-Only

Loops are scoped to your current Claude Code session. Close Claude:

```bash
exit  # Stops all loops
```

Restart Claude:

```bash
claude
```

Loops don't resume — they're stateless.

### 3-Day Auto-Expiry

Safety mechanism: any loop older than 3 days auto-cancels:

```
/loop 1h ./scripts/verify-all.sh
# Day 1: ✓ Runs
# Day 2: ✓ Runs
# Day 3: ✓ Runs
# Day 4: Auto-canceled
```

To restart after expiry:

```
/loop 1h ./scripts/verify-all.sh
```

### Manual Cancellation

Stop a loop anytime:

```
/loop cancel <loop-id>
```

Or find and cancel by pattern:

```
/loop list          # Shows all active loops
```

Then:

```
/loop cancel verify-all  # Cancel by name pattern
```

## Monitoring and Management

### List Active Loops

```
/loop list
```

**Output:**
```
Active Loops:
1. verify-all (every 4h) — Last run: 10:00, Next: 14:00
2. health-check (every 1h) — Last run: 14:30, Next: 15:30
3. bundle-size (every 6h) — Last run: 10:00, Next: 16:00
```

### View Loop History

```
/loop history <loop-id>
```

Shows recent runs and their outcomes.

### Disable/Re-enable a Loop

Temporarily pause a loop (useful if a check is noisy):

```
/loop pause health-check
```

Resume later:

```
/loop resume health-check
```

## Best Practices

### 1. Use the Right Interval

| Interval | Use Case | Cost |
|----------|----------|------|
| 30s | Live status (dashboards) | High — every 30s |
| 5m | Active monitoring (during a deploy) | Medium |
| 1h | Drift detection, health checks | Low — manageable |
| 4h | Full test suite | Low — once per shift |
| 24h | Daily audits, cron jobs | Very low |

### 2. Don't Over-Schedule

Avoid running too many loops simultaneously:

```
✗ Bad:
/loop 5m test
/loop 5m typecheck
/loop 5m build
/loop 5m lint
(All run at the same time, overload)

✓ Good:
/loop 20m pnpm test && pnpm typecheck && pnpm build && pnpm lint
(Runs once every 20 minutes, sequential)
```

### 3. Log Output to File for Review

For long-running jobs, capture output:

```
/loop 1h ./scripts/verify-all.sh >> verify.log 2>&1
```

Then review batch:

```bash
tail -50 verify.log | grep -E "FAIL|ERROR"
```

### 4. Alert on Failure Only

Use a conditional to reduce noise:

```
/loop 1h pnpm test || echo "⚠️  Tests failed; check immediately"
```

Only outputs when tests fail.

### 5. Combine with Background Tasks

Use `/loop` for continuous checks, **and** Ctrl+B for long-running work:

```
# Terminal 1: Start a build in background
Ctrl+B  (start: pnpm build)

# While build runs, in same terminal:
/loop 30m ./scripts/health-check.sh
(Monitors site health while build completes)
```

## Real-World Example: Deploy Validation

You just deployed a new version. Set up verification:

```
/loop 5m curl -s https://yoursite.com/ -o /dev/null -w "Status: %{http_code}\n"
/loop 5m check Cloud Run logs for errors
/loop 10m pnpm test (full suite in background)
```

**First 10 minutes:**
```
[Deploy +1m] Status: 200 ✓
[Deploy +1m] Logs: No errors ✓
[Deploy +5m] Status: 200 ✓
[Deploy +5m] Logs: No errors ✓
[Deploy +10m] Tests: All pass ✓
[Deploy +10m] Status: 200 ✓
```

If something goes wrong at +15m:

```
[Deploy +15m] Status: 502 ✗
[Deploy +15m] Logs: Memory exceeded in function X
→ Rollback initiated
```

You caught it in monitoring without manually checking every 5 minutes.

## Troubleshooting

### Loop Doesn't Run on Expected Interval

Check if it's paused:

```
/loop list
```

If paused, resume:

```
/loop resume <loop-id>
```

### Output is Too Noisy

Add filtering:

```
✗ /loop 1h ./scripts/verify-all.sh
(outputs all logs)

✓ /loop 1h ./scripts/verify-all.sh | grep -E "FAIL|ERROR|^>"
(outputs only failures)
```

### I Forgot Which Loops Are Running

```
/loop list
```

Shows all active loops, intervals, and last run time.

### Command Takes Longer Than Interval

If a command takes 30 minutes but interval is 1h, the next run waits for completion:

```
/loop 1h ./long-running-script.sh
```

**Timeline:**
```
[10:00] Start (completes at 10:30)
[11:00] Start (completes at 11:30)  ← Waits for previous to finish
[12:00] Start
```

For overlapping runs, use subagents in background mode instead.
