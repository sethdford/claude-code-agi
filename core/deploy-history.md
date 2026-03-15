# Deploy History

This file tracks all production deployments: timing, success/failure, commits, and outcomes. Used for incident investigation and correlating errors to deployments.

## Format

Each deploy entry includes:

- **Timestamp**: When the deploy ran
- **Status**: Success, Partial, Failure, Rolled back
- **Commits**: Hash(es) and messages deployed
- **Changes**: What changed (functions, data, rules, etc.)
- **Smoke test**: Did the post-deploy health check pass?
- **Notes**: Any anomalies or issues

---

## Deploys

### [2026-XX-XX HH:MM UTC] - [Status]

**Commits:**

- `abc1234` - [message]

**Changes:**

- [Function/data/config changes]

**Smoke test:** ✓ Pass / ✗ Fail

- Health endpoint: [URL] → [status]
- Key API route: [URL] → [status]

**Notes:**

- [Any issues encountered, workarounds, or follow-ups]

---

## Investigation Protocol

When correlating production errors to deployments:

1. Get error timestamp from logs
2. Find the most recent deploy before that timestamp
3. Check if that deploy introduced the breaking change
4. Review commit messages and code diff
5. If yes: create hotfix and re-deploy
6. If no: continue investigating in logs/code

---

## Starter Notes

- Keep this file updated after every deploy
- Include the exact commit hash for reproducibility
- Note any ENV vars that changed
- Document post-deploy health check results
- If a deploy fails, include the error message and context
