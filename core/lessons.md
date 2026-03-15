# Lessons and Self-Improvement

This file tracks learned patterns, common mistakes, and debugging insights. Sessions automatically load these lessons to prevent repeating known mistakes and apply proven solutions.

## Format

Each lesson entry has:

- **Category**: Error type, Mistake pattern, Debugging strategy, etc.
- **Pattern**: When/where the issue occurs
- **Root cause**: Why it happens
- **Fix**: How to resolve it
- **Prevention**: How to avoid it in future

---

## Starter Lessons

### Error Handling

- **Pattern**: Wrapping JSON parsing in try-catch
- **Root cause**: `request.json()` can throw if body is malformed
- **Fix**: Always use try-catch around `request.json()` with explicit 400 error response
- **Prevention**: Create a utility function to wrap JSON parsing for consistency

### Test Failures

- **Pattern**: Async test timeouts
- **Root cause**: Missing `await` on async operations or test not waiting for promises
- **Fix**: Ensure all async operations in tests are awaited before assertions
- **Prevention**: Use TypeScript strict mode to catch missing awaits

### Context Window

- **Pattern**: Context exhaustion during long sessions
- **Root cause**: Large tool outputs and verbose intermediate results
- **Fix**: Use subagents to pre-process data; summarize and discard intermediates
- **Prevention**: Monitor `/context` regularly; use `.claudeignore` to exclude large files

### Deploy Failures

- **Pattern**: Functions fail after successful local tests
- **Root cause**: Environment variable missing, Firebase config not deployed, or runtime mismatch
- **Fix**: Check `.env` exists, verify Firebase emulator config, validate runtimes
- **Prevention**: Create pre-deploy checklist; run smoke tests against staging

### Git Conflicts

- **Pattern**: Merge conflicts on schema files or auto-generated code
- **Root cause**: Parallel changes to shared files without coordination
- **Fix**: Resolve by picking the latest version and re-running codegen
- **Prevention**: Coordinate schema changes; use worktrees for parallel work

---

## Template for New Lessons

When you encounter a repeatable issue:

```
### [Issue Title]
- **Pattern**: When X happens, Y breaks
- **Root cause**: [diagnosis]
- **Fix**: [immediate solution]
- **Prevention**: [long-term prevention]
```

Add it to this file immediately after discovery. Review this section at session start.

---

## Session-Specific Notes

None yet. Fill in as you work.
