# Workflow: Prepare Code for Review

**Goal:** Get your code ready for human review by doing self-review, automated checks, and addressing low-hanging fruit before asking reviewers for their time.

**Context:** You've written code or been asked to review a PR. Before requesting or starting a formal review, verify quality and fix obvious issues.

## Step 1: Verify Tests Pass Locally (5 min)

Before anything else, confirm tests pass:

```bash
# Run full test suite for the affected package(s)
npm test                        # or pnpm test / cargo test / etc.

# If tests fail, stop here and fix them
# (Your code is not ready for review if tests fail)

# Run coverage to identify untested code
npm run test:coverage
```

**What to look for:**
- 80%+ line coverage on new code
- All tests passing (not skipped or pending)
- No flaky tests that sometimes fail

**If coverage is low:** Add tests before requesting review.

## Step 2: Run Automated Checks (3 min)

Execute the team's automated quality checks:

```bash
# TypeScript / type checking
npx tsc --noEmit              # or npm run typecheck

# Linting
npm run lint                  # or eslint src/

# Code formatting
npm run format:check          # or prettier --check .

# Security audit
npm audit --audit-level=high
```

**If any fail:** Fix them locally using:

```bash
npm run format                # Auto-fix formatting
npm run lint -- --fix         # Auto-fix linting issues
```

## Step 3: Review the Diff Yourself (10 min)

Read your own changes before a human does. This catches obvious mistakes.

```bash
# See changes against main
git diff main..HEAD

# Or see files changed
git diff main --name-only

# Or use GitHub/GitLab web UI to view diff visually
```

**Self-review checklist:**

- [ ] Does each change make sense in isolation?
- [ ] Are there any obvious bugs or typos?
- [ ] Are variable names clear and consistent?
- [ ] Did I remove debugging code (console.log, debugger statements)?
- [ ] Are error messages user-friendly?
- [ ] Did I introduce any security issues (hardcoded secrets, SQL injection)?
- [ ] Are there any performance problems (N+1 queries, unnecessary renders)?
- [ ] Did I follow the team's code style?
- [ ] Are there any comments that need updating?
- [ ] Did I accidentally commit unwanted files (.env, node_modules, etc.)?

**Time-saving tip:** If you see an issue you can fix in 30 seconds, fix it now rather than making the reviewer point it out.

## Step 4: Dispatch Code-Reviewer Agent (5 min setup + parallel execution)

Use a specialized AI agent to audit your changes in parallel with your own review:

```markdown
Agent(code-reviewer)
- Model: Sonnet 4.6 (higher quality than Haiku)
- Read-only mode (no write access)
- maxTurns: 2 (focused, not verbose)
- background: true (runs while you continue)

## Task: Code Review

Review the diff from `main` to `HEAD` in this repository.

Focus on:
1. **Correctness**: Do the changes implement the feature correctly?
2. **Testing**: Are edge cases tested? Is there sufficient coverage?
3. **Performance**: Any N+1 queries, unnecessary re-renders, or blocking operations?
4. **Security**: Hardcoded secrets, injection vulnerabilities, access control?
5. **Readability**: Variable names, function length, complexity, documentation?
6. **Consistency**: Do changes follow team conventions from CLAUDE.md / docs/standards/?
7. **Breaking Changes**: Does this change break existing APIs or behavior?

## Output Format

Return a prioritized list:

### Critical Issues (must fix)
- [ ] Issue 1: [specific error or problem]
- [ ] Issue 2: [specific error or problem]

### Important (should fix)
- [ ] Issue 1: [suggestion with reasoning]

### Nice-to-Have (optional)
- [ ] Issue 1: [suggestion]

### Approval
- [ ] Code is ready for human review
- [ ] Ready to merge (if all suggestions addressed)
```

The agent will run in the background. While it works, proceed to Step 5.

## Step 5: Build and Smoke Test (5 min)

Verify the code actually builds and doesn't break the app:

```bash
# Build
npm run build

# If there's a dev server, start it and manually test the feature
npm run dev

# Test in browser/emulator:
# 1. Navigate to the feature
# 2. Test the happy path
# 3. Test an error condition
# 4. Check console for errors/warnings
# 5. Close and re-open to test persistence
```

**What to check:**
- No build errors or warnings
- Feature loads without crashing
- Form inputs work, submissions succeed
- Errors are handled gracefully
- UI is not broken (alignment, colors, fonts)

## Step 6: Update PR Description (if applicable) (5 min)

Write a clear PR description that explains the *why*, not just the *what*:

```markdown
## Description
What problem does this PR solve? Why is this change needed?

Example:
"Users were unable to delete their account. This PR adds account deletion with proper permission checks and data cleanup."

## Changes
High-level summary of what changed. Use past tense.

Example:
- Implemented deleteAccount API endpoint with permission validation
- Added AccountDeletionForm component with confirmation dialog
- Added cascading delete for user's posts and comments
- Added integration tests for deletion flow

## Testing
How did you verify this works?

Example:
- [x] Unit tests for account deletion logic (10 new tests)
- [x] Integration tests for API endpoint (5 new tests)
- [x] Manual testing: account deletion flow end-to-end
- [x] Error handling: tested with missing permissions, concurrent deletes
- [x] Coverage: 92% lines, 88% branches

## Breaking Changes
Any changes that break existing code?

Example:
- None (backwards compatible)

OR

- Removed `user.deleteOld()` method (use `user.delete()` instead)
- Changed `/api/users/:id` response format (see migration guide in PR comments)

## Checklist
- [x] Tests pass locally
- [x] No console.log or debugging code
- [x] Follows team conventions (see CLAUDE.md)
- [x] TypeScript is strict, no @ts-ignore
- [x] Performance OK (ran Lighthouse / benchmarks)
- [x] Accessibility checked (keyboard nav, screen reader)
- [x] Self-review complete

## Screenshots / Videos
(Include if UI-heavy)

## Related Issues
Closes #123
Relates to #456
```

## Step 7: Review Code-Reviewer Agent Feedback (3 min)

When the code-reviewer agent finishes:

```bash
# Check if the agent left comments or output
# (Depends on your tool setup, but likely in a pinned message or file)
```

**For each issue the agent found:**

1. **Critical issues**: Fix them now before requesting review
2. **Important issues**: Fix if they take <5 min; otherwise add a comment explaining why you're deferring
3. **Nice-to-have**: Consider for polish; not blockers

**Example response in PR comments:**

```markdown
## Code Review Feedback

### Agent Review Results

**Critical Issues:** Fixed

**Important Issues:**
- N+1 query in getUser() → Fixed by adding eager loading
- Missing validation on email field → Fixed, added regex pattern

**Nice-to-Have:**
- Suggestion to rename `temp` variable → Will address in follow-up PR
```

## Step 8: Verify Fixes (2 min)

If you made changes based on feedback:

```bash
# Run tests again
npm test

# Verify build still works
npm run build

# Look at the diff one more time
git diff main..HEAD
```

## Step 9: Request Review (2 min)

Once all automated checks pass and you've addressed critical feedback:

```bash
# Mark PR as ready for review (if it was draft)
# On GitHub: Convert from Draft → Ready for Review

# Or ping reviewers in Slack:
# "PR #123 ready for review. All tests pass, 92% coverage. ~400 lines changed."
```

**Pro tips:**
- Tag reviewers who are domain experts (not just "reviewers")
- Mention if there are tricky decisions explained in PR comments
- Mention if you'd like feedback on a specific aspect (performance, API design, etc.)

## Step 10: Respond to Human Review Feedback (ongoing)

When reviewers comment:

1. **Clarifying questions**: Answer directly in the comment
2. **Suggestions**: Implement if you agree; explain your reasoning if you disagree
3. **Requests for changes**: Fix and re-push (do *not* force-push without asking)
4. **Approvals**: Thank them and merge (or wait for all reviewers if required)

```bash
# Make a fix based on feedback
git add src/myfile.ts
git commit -m "Address review feedback: add input validation to form"

# Push (don't force-push)
git push origin feature/my-feature
```

## Full Workflow Timeline

| Step | Task | Time | Parallel? |
|------|------|------|-----------|
| 1 | Run tests | 5 min | — |
| 2 | Automated checks | 3 min | — |
| 3 | Self-review diff | 10 min | No (do first) |
| 4 | Dispatch code-reviewer agent | 5 min setup | ✅ Yes (background) |
| 5 | Build and smoke test | 5 min | Parallel with agent |
| 6 | Update PR description | 5 min | Parallel with agent |
| 7 | Review agent feedback | 3 min | Depends when agent finishes |
| 8 | Fix issues | varies | — |
| 9 | Request review | 2 min | — |
| 10 | Respond to feedback | ongoing | — |

**Total: ~25 min before requesting human review** (agent runs in background)

## What NOT to Do

❌ **Don't request review if tests fail** — Fix them first
❌ **Don't have console.log in production code** — Linter should catch this
❌ **Don't ignore linter warnings** — Fix or disable with a comment explaining why
❌ **Don't force-push without asking** — It messes with reviewer comments
❌ **Don't merge your own PR** — Wait for approval (even if you're the maintainer)
❌ **Don't add unrelated changes to the PR** — Keep changes focused on one feature/bug
❌ **Don't skip testing edge cases** — The test suite is your safety net

## Self-Review Checklist (Print This)

Copy this into your PR description:

```markdown
## Self-Review Checklist
- [ ] All tests pass locally: `npm test`
- [ ] Code builds: `npm run build`
- [ ] TypeScript is strict: `npx tsc --noEmit`
- [ ] Linting passes: `npm run lint`
- [ ] Code is formatted: `npm run format:check`
- [ ] No console.log or debugger statements
- [ ] No hardcoded secrets or credentials
- [ ] Variable names are clear and follow conventions
- [ ] Comments explain *why*, not *what*
- [ ] Error messages are helpful
- [ ] No performance regressions
- [ ] Follows team style (CLAUDE.md)
- [ ] Edge cases tested
- [ ] Coverage >= 80%
```

## Example: Before and After

### Before (Not Ready)

```
PR: Add user creation
- Made some changes
- Tests pass I think
- Let me know if anything's wrong
```

❌ Vague, likely has issues, reviewers will be frustrated

### After (Ready)

```
PR: feat: add user creation feature with validation

Description: Add ability for admins to create user accounts with automatic
verification email. Includes input validation, permission checks, and error handling.

Testing:
- 15 new tests covering happy path + edge cases
- 94% line coverage on new code
- Manual testing: created 5 test accounts, verified emails sent

Checklist:
- [x] All tests pass
- [x] No console.log or debugger
- [x] Follows team conventions
- [x] Type-safe (no @ts-ignore)
- [x] Performance OK

Reviewers: @alice (backend expert), @bob (security)
```

✅ Clear, confident, professional. Reviewers know what to expect.

---

**Result:** Code that's thorough, self-aware, and respectful of reviewers' time. This workflow reduces back-and-forth and gets PRs merged faster.
