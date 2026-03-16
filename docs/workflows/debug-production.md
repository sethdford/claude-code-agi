# Recipe: Debug a Production Issue

Structured workflow for identifying, fixing, and verifying production bugs in under 15 minutes (for simple issues) or 1-2 hours (for complex root causes).

## Overview

Production issues require speed, precision, and verification. This workflow prioritizes finding root cause, fixing it, and confirming the fix works.

**Key principle:** Correlate time (when did it start?), code (what changed?), and symptoms (what's broken?) to isolate the bug.

## Phase 1: Assess the Situation (2 minutes)

When you notice a production issue (error spike, user report, monitoring alert):

### Check Production Health

```bash
# Site reachability
curl -s https://example.com/ -o /dev/null -w "HTTP %{http_code}\n"

# Specific endpoint
curl -s https://example.com/api/health -w "%{http_code}\n"

# Check Cloud Logging (if on GCP)
gcloud logging read 'severity>=ERROR' --limit=10 --project=your-project

# Check recent deployments
git log --oneline -10  # Did we deploy recently?

# Check deployed version
curl -s https://example.com/api/version  # If endpoint exists
```

### Gather Initial Information

- **What's broken?** (Specific endpoint? Entire service? Specific user feature?)
- **How many users affected?** (Just you? Percentage? All users?)
- **When did it start?** (Just now? This morning? This week?)
- **Is it intermittent or constant?** (Reproducible? Random errors?)

Create a quick summary:

```markdown
# Production Issue Report

## Symptoms
- Feature: [What's broken]
- Affected: [Who/what is affected]
- Since: [When did it start]
- Reproducible: [Yes/No, description]

## Environment
- Project: [your-project]
- Region: [us-central1]
- Version: [git hash or tag]

## Initial Hypothesis
[Your first guess at what's wrong]
```

## Phase 2: Correlate Code & Time (3-5 minutes)

Did something change recently that could cause this?

### Check Recent Deployments

```bash
# See last few deploys
cat ~/.claude/deploy-history.md | head -20

# Or check git log
git log --oneline -10

# See what changed in last deploy
git diff HEAD~1...HEAD --stat
```

### Check Recent Commits

```bash
# What changed in the last 24 hours?
git log --oneline --since="24 hours ago"

# What changed in the last commit?
git show --stat

# What changed in a specific file (if you suspect it)?
git log --oneline -- src/api/checkout.ts | head -5
```

### Hypothesis

If a recent deploy matches the timing:
- **Likely** the deploy introduced the bug
- Check what changed in those specific files
- Read the diff carefully
- Look for obvious bugs (type errors, logic inversions, missing checks)

If no recent deploy:
- Infrastructure issue (database, upstream service, network)
- Traffic spike causing resource exhaustion
- Third-party service failure (payment processor, email service)

## Phase 3: Read Error Logs (3-10 minutes)

Get the full picture from logs:

### GCP Cloud Logging

```bash
# Recent errors (last hour)
gcloud logging read 'severity=ERROR' --limit=20 --project=your-project

# Errors from specific function
gcloud logging read 'resource.labels.function_name="myFunction" AND severity=ERROR' \
  --limit=20 --project=your-project

# Errors with specific text
gcloud logging read 'textPayload=~"TypeError"' --limit=20 --project=your-project

# Full structured entry (JSON)
gcloud logging read 'severity=ERROR' --limit=5 --format=json --project=your-project
```

### AWS CloudWatch

```bash
# Recent errors
aws logs tail /aws/lambda/myFunction --since 1h --filter-pattern "ERROR"

# Specific error
aws logs tail /aws/lambda/myFunction --since 1h --filter-pattern "[...]ERROR[...]"
```

### Application Logs

If you have custom logging:

```bash
# Check your app's logs
docker logs container-name | tail -50

# Or file-based logs
tail -100 /var/log/app.log | grep ERROR
```

### Read Full Error Details

Pick one error and understand it completely:

```bash
# Get full context
gcloud logging read 'severity=ERROR' --limit=1 --format=json --project=your-project | jq '.[] | .textPayload'
```

Extract:
- **Error type** — what failed? (TypeError, ReferenceError, 404, timeout, etc.)
- **Error message** — what was the issue?
- **Stack trace** — where in the code did it fail?
- **Context** — what was the input? What was the state?

## Phase 4: Identify Root Cause (5-15 minutes)

Now you have:
- Symptoms (what's broken)
- Timeline (when it started)
- Logs (error details)
- Code (what changed)

### Hypothesis Testing

```
Initial hypothesis:
[Based on symptoms + timeline + code changes]

Evidence:
- [Log entry A]
- [Changed file B]
- [Timing matches C]

Alternative hypotheses:
1. [Could be X instead]
2. [Could be Y]

Next test:
[What to check next]
```

### Common Causes (by symptom)

**Endpoint returning 500:**
- Exception in code (check logs for stack trace)
- Missing dependency (database, external service)
- Permission denied (auth issue)
- Resource exhausted (memory, connection pool)

**Endpoint returning 404:**
- Route deleted or renamed
- Typo in route definition
- Request going to wrong service

**Endpoint timing out:**
- Infinite loop in code
- Waiting for slow external service
- Database query is too slow

**Intermittent failures:**
- Race condition (concurrent execution)
- Resource contention (one slow request blocks others)
- Third-party service is slow sometimes

**All users affected:**
- Deploy broke something fundamental
- Database/infra is down
- Traffic spike exhausted resources

**Specific users affected:**
- User-specific data is corrupt
- Feature flag didn't evaluate correctly
- Auth issue (specific permission problem)

### Narrow Down with Code Review

Read the relevant code:

```bash
# If error is in checkoutHandler
cat src/api/checkout.ts

# Focus on the failing function
grep -n "function checkout" src/api/checkout.ts

# Check if there were recent changes
git diff HEAD~1...HEAD -- src/api/checkout.ts
```

Look for:
- Type errors (passing wrong type to function)
- Logic inversions (if condition backwards)
- Missing null/undefined checks
- Missing error handling
- Off-by-one errors
- Missing imports or typos

## Phase 5: Fix the Bug (5-20 minutes)

Once you've identified the root cause:

### Create a Fix Branch

```bash
git checkout -b fix/issue-description
```

### Implement the Fix

```typescript
// Example: Missing null check causing TypeError
// Before (buggy):
function checkout(cart) {
  const total = cart.items.reduce((sum, item) => sum + item.price, 0);
  // If cart.items is null/undefined, this crashes
}

// After (fixed):
function checkout(cart) {
  if (!cart || !cart.items) {
    throw new Error('Invalid cart');
  }
  const total = cart.items.reduce((sum, item) => sum + item.price, 0);
}
```

### Test the Fix

Run tests for the affected function:

```bash
pnpm test -- src/api/checkout.test.ts

# Or run specific test
pnpm test -- src/api/checkout.test.ts -t "checkout with empty cart"
```

Add a test case if the bug wasn't covered:

```typescript
it('handles null cart gracefully', () => {
  expect(() => checkout(null)).toThrow('Invalid cart');
});
```

### Commit the Fix

```bash
/commit "fix: add null check in checkout handler

Production issue: checkout endpoint was crashing with TypeError
when cart.items was null. Added guard clause to validate input.

Fixes: [issue number if tracked]"
```

## Phase 6: Deploy the Fix (2-5 minutes)

### Deploy to Production

```bash
# For Firebase Functions
./scripts/deploy-consultant.sh --functions

# For Cloud Run
gcloud deploy releases create fix-checkout --source .

# For other platforms
[Your deploy command]
```

Wait for deploy to complete.

### Verify on Production

Immediately after deploy:

```bash
# Check health endpoint
curl -s https://example.com/api/health | jq

# Test the fixed endpoint
curl -s https://example.com/api/checkout -d '{"items": [...]}' | jq

# Check logs for errors
gcloud logging read 'severity=ERROR' --since 10m --limit=20
```

### Monitor for 10 Minutes

```bash
# Watch for new errors
/loop 1m gcloud logging read 'severity=ERROR' --since 10m --limit=5

# Or manually check periodically
gcloud logging read 'severity=ERROR' --since 10m --limit=5
```

If new errors appear, roll back immediately:

```bash
# Roll back the last deploy
gcloud deploy releases revert main-prod

# Or manually redeploy previous version
git checkout HEAD~1
./scripts/deploy-consultant.sh --functions
```

## Phase 7: Post-Mortem & Learning (2-5 minutes)

After the fix is confirmed working:

### Update Lessons File

```bash
cat >> ~/.claude/lessons.md <<EOF

## Production Issue: [Date] - [Issue Name]

**Root cause:** [What was wrong]

**Why it happened:** [Why did the bug exist]

**How we detected it:** [Monitoring, user report, etc.]

**Fix:** [What we changed]

**Prevention:** [How to prevent next time]

**Time to fix:** [How long from detection to deployed]

### Actions
- [ ] Add test case to prevent regression
- [ ] Review similar code for same pattern
- [ ] Update monitoring/alerts if needed
- [ ] Document in runbook if critical issue

EOF
```

### Add Test Case

Ensure this bug can't happen again:

```typescript
it('checkout with null cart should throw error', () => {
  expect(() => checkout(null)).toThrow('Invalid cart');
});
```

### Review Similar Code

If you found a null-check bug, search for similar patterns:

```bash
# Find other places with cart.items
grep -r "cart\.items" src/ | grep -v test

# For each, verify null checks exist
```

### Update Monitoring

If this should have been caught earlier:

```bash
# Add alert for checkout endpoint errors
gcloud alpha monitoring policies create \
  --notification-channels=[channel-id] \
  --display-name="Checkout endpoint errors" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=0.05 \
  --condition-threshold-filter='resource.type="cloud_function"'
```

## Quick Reference: Time to Resolution

| Issue Type | Detect | Diagnosis | Fix | Deploy | Verify | Total |
|------------|--------|-----------|-----|--------|--------|-------|
| Obvious bug (typo, logic) | 1 min | 2 min | 2 min | 2 min | 1 min | 8 min |
| Missing null check | 1 min | 3 min | 3 min | 2 min | 1 min | 10 min |
| Regression from deploy | 1 min | 5 min | 5 min | 2 min | 2 min | 15 min |
| Subtle race condition | 2 min | 10 min | 10 min | 2 min | 2 min | 26 min |
| Third-party service down | 1 min | 5 min | 0 min | 0 min | 5 min | 11 min |
| Database query timeout | 2 min | 10 min | 10 min | 2 min | 2 min | 26 min |

## Troubleshooting

**Logs not showing errors:**
- Logs have latency (may take 30s-1m to appear)
- Check if logging is enabled
- Check if errors are being suppressed
- Try increasing time window: `--since 1h` instead of `--since 10m`

**Can't reproduce locally:**
- Might be environment-specific (database size, network latency)
- Might be concurrent issue (need load testing)
- Might be specific to production data
- Try running against production database in staging

**Fix didn't work:**
- Maybe root cause is different
- Go back to Phase 4, re-read logs with fresh eyes
- Check if there are multiple bugs
- Consider rolling back and investigating more

**Panic / High Pressure:**
- Take 30 seconds to breathe
- Don't just revert without understanding why
- Verify fix before celebrating
- Can always rollback if needed

## Escalation

If you can't identify root cause in 30 minutes:

1. **Rollback** — go back to last known good state
2. **Alert team** — notify on-call engineer and team lead
3. **Investigate on branch** — don't debug on main
4. **Document findings** — save logs and context for post-mortem

```bash
# Emergency rollback
git reset --hard HEAD~1
./scripts/deploy-consultant.sh --functions

# Notify team
slack: "@oncall Production issue in checkout. Rolled back to [version]. Investigating."

# Debug on branch
git checkout -b debug/checkout-issue
# Take time to understand
# Once fixed, commit and redeploy
```

## Checklists

### During Issue
- [ ] Assessed situation (affected scope, timing)
- [ ] Checked production health
- [ ] Read recent deploys and git log
- [ ] Gathered error logs
- [ ] Formed hypothesis
- [ ] Identified root cause
- [ ] Implemented fix
- [ ] Tested locally
- [ ] Deployed to production

### After Fix
- [ ] Verified fix works in production
- [ ] Monitored for 10 minutes
- [ ] No new errors appearing
- [ ] Updated lessons.md
- [ ] Added test case to prevent regression
- [ ] Reviewed similar code
- [ ] Considered monitoring improvements
- [ ] Documented in runbook if critical

### Post-Mortem
- [ ] Root cause clearly documented
- [ ] Test case added
- [ ] Similar code reviewed
- [ ] Alerts/monitoring added
- [ ] Team notified
- [ ] Incident reviewed in retrospective
