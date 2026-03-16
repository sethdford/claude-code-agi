# Universal Development Pipeline

This guide describes the standard intake → plan → build → test → review → PR workflow that optimizes for both speed and quality. Use this workflow for any development task, from trivial hotfixes to complex multi-file refactors.

## The Full Pipeline

```
intake → plan → build → test → review → PR
```

### Intake: Understand the Task

**Goal:** Gather all context needed to make an informed plan.

1. **Read the issue** (or user request)
   - What is the problem or feature?
   - What are the acceptance criteria?
   - Are there links to related issues, PRs, or design docs?

2. **Gather context**
   - Check recent commits: `git log --oneline -10`
   - Check CI status and recent test failures
   - Review the task list if working on a larger initiative

3. **Run codebase orientation** (use subagent for large repos)
   - Identify affected files and modules
   - Check file sizes, dependencies, related tests
   - Look for existing patterns to reuse

**Output:** A clear summary of what needs to be done and why.

### Plan: Enter Plan Mode (Shift+Tab)

**Goal:** Explore the codebase read-only, design the solution, and get approval before writing code.

1. **Enter plan mode** — Press Shift+Tab twice in Claude Code
   - This restricts tools to read-only operations
   - Separates analysis from execution
   - Reduces token consumption by 40-50%

2. **Explore the codebase**
   - Read relevant files: `Read`, `Glob`, `Grep`
   - Map out the change scope
   - Identify integration points
   - Check for existing solutions or similar patterns

3. **Write a detailed plan**
   - List the files that need to change
   - Describe the architectural approach
   - Call out any risky areas (concurrent writes, external APIs, migrations)
   - Suggest test strategy
   - Estimate scope (small, medium, large)

4. **Wait for approval**
   - The user reviews and approves (or asks for modifications)
   - This checkpoint prevents wasted tokens on wrong approaches

**Example plan structure:**
```
## Plan

### Scope
- [ ] Modify `src/api/leads.ts` — add retry logic to createLead()
- [ ] Update `src/types/lead.ts` — add `retryCount` field
- [ ] Create `src/__tests__/api/leads.test.ts` — test retry scenarios
- [ ] Update `infra/firebase/firestore.rules` — allow retryCount writes

### Approach
1. Add exponential backoff (100ms, 200ms, 400ms, 800ms)
2. Store attempt count in Firestore
3. Fail after 4 attempts or 5 seconds elapsed
4. Log each retry for debugging

### Risks
- Potential for duplicate writes if client retries simultaneously
- Mitigation: idempotency key (UUID) in lead record

### Test Plan
- Success path: lead created on first try
- Retry path: verify backoff timing
- Failure path: exhausted retries, proper error response

### Estimate
Medium (3-4 affected files, new test file)
```

**When to skip plan mode:**
- Trivial fixes (1-2 line changes, obviously correct)
- Fixing known bugs with clear solutions
- Adding simple constants or config values

### Build: Execute the Plan

**Goal:** Write clean, tested code following project conventions.

1. **Create a branch** (if not already done)
   ```bash
   git checkout -b feature/retry-logic
   ```

2. **Write code** following the approved plan
   - Stick to the plan — if you deviate, note why
   - Use subagents for parallel, independent tasks
   - Reference existing patterns in the codebase
   - Type-check continuously (`npx tsc --noEmit` or `pnpm typecheck`)

3. **Use subagents for parallel work**
   - Assign different files to different subagents
   - Offload data-heavy exploration to subagents
   - Keep your main context clean for orchestration
   - Example: one subagent updates types, another writes tests, another updates rules

4. **Document as you go**
   - Update comments for non-obvious logic
   - Add JSDoc for public functions
   - Update README if user-facing behavior changed

**Subagent strategy:**
- Use `model: haiku` for simple tasks (refactoring, boilerplate)
- Use `model: sonnet` for complex analysis (algorithm design, API integration)
- Keep yourself (Opus) for orchestration and final review
- Never spawn >5 subagents at once; wait for 2-3 to finish before adding more

### Test: Verify Quality

**Goal:** Ensure the code is correct, safe, and maintainable.

1. **Run the full test suite**
   ```bash
   pnpm test
   ```
   - Fix any new failures
   - Don't increase timeouts to hide flaky tests — find the root cause

2. **Type-check**
   ```bash
   pnpm typecheck
   ```
   - Zero TypeScript errors, strict mode

3. **Lint**
   ```bash
   pnpm lint
   ```
   - Auto-fix with `--fix` if available

4. **Check coverage**
   - Most projects require 80%+ line coverage
   - Run coverage report: `pnpm test --coverage`
   - Add tests for uncovered branches if needed

5. **Build verification**
   ```bash
   pnpm build
   ```
   - Catches tree-shaking issues, unused imports, bundle size problems

6. **Smoke test in dev** (for UI changes)
   - Start dev server: `pnpm dev`
   - Manually verify the feature works end-to-end
   - Check responsive design if applicable

**Testing conventions vary by project:**
- Check `.claude/rules/testing.md` or equivalent
- Typical pattern: mock external dependencies, test happy path + error paths
- Always test auth (401), rate limiting (429), success, and failure

### Review: Self-Review & Code Review

**Goal:** Catch issues before merging. Maintain code quality standards.

1. **Self-review**
   - Run `git diff HEAD~1` to see your changes
   - Ask: "Would a staff engineer approve this?"
   - Check for code smells: duplication, unclear variable names, side effects
   - Verify you didn't break related features

2. **Request code review**
   - Dispatch a code-reviewer subagent (if available in your project)
   - Or tag a human reviewer for complex changes
   - Provide context: what changed, why, and how to verify

3. **Address feedback**
   - Fix issues immediately
   - Don't argue about style — accept conventions
   - Ask for clarification if feedback is unclear

### PR: Create Pull Request

**Goal:** Communicate the change, link to issue, document the test plan.

1. **Create PR** with this structure:

   ```markdown
   ## Summary
   Add retry logic to lead creation endpoint to handle transient failures.

   Fixes #123.

   ## Changes
   - Add exponential backoff (4 attempts, max 5 seconds)
   - Store `retryCount` in lead document for audit trail
   - Update types and Firestore rules

   ## Test Plan
   - [x] All existing tests pass
   - [x] New tests verify retry behavior (success, backoff timing, failure)
   - [x] Manual test in dev: create lead, verify no duplicates
   - [x] Edge case: simultaneous retries (idempotency key prevents duplicates)

   ## How to Verify
   1. Checkout this branch
   2. Run `pnpm test` — all pass
   3. Run `pnpm dev` and test the flow manually
   4. Check diff against main for unexpected changes

   ## Type Checks
   - `pnpm typecheck` ✓
   - `pnpm lint` ✓
   - `pnpm build` ✓
   ```

2. **Link to issue** — use "Fixes #N" in description

3. **Wait for CI** — all checks must pass before merge

4. **Address review comments** — same as above

## Pipeline Shortcuts

Not all tasks require the full pipeline. Use judgment:

| Task Type | Intake | Plan | Build | Test | Review | PR |
|-----------|--------|------|-------|------|--------|-----|
| Typo/comment | ✓ | ✗ | ✓ | ✗ | ✗ | ✓ |
| 1-line config change | ✓ | ✗ | ✓ | ✓ | ✗ | ✓ |
| Bug fix (clear root cause) | ✓ | ⚡ | ✓ | ✓ | ✓ | ✓ |
| New feature (small) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| New feature (large/risky) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Refactor (10+ files) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**Legend:**
- ✓ = full phase
- ⚡ = lightweight plan (5 min design, no subagents)
- ✗ = skip entirely

## Plan Mode: Token & Cost Savings

Plan mode is a force multiplier. Here's why:

### Token Efficiency

**Without plan mode (typical execution flow):**
1. Read files to understand structure (20K tokens)
2. Design solution while reading (10K tokens)
3. Write code based on design (15K tokens)
4. Realize design flaw, re-read files (15K tokens)
5. Rewrite code (10K tokens)
**Total: 70K tokens, includes wasted exploration**

**With plan mode (separated analysis):**
1. Read files (read-only tools, 20K tokens)
2. Design solution, write plan (5K tokens)
3. User approves plan (no tokens)
4. Execute approved plan with confidence (20K tokens)
5. Test and review (5K tokens)
**Total: 50K tokens, no wasted exploration**

**Savings: 20K tokens (28%) per task, compounds across projects.**

### Cost Savings

Using Haiku for plan mode exploration instead of Opus:

- Opus 4.6: $15 per MTok
- Haiku 4.5: $0.25 per MTok

**For a 20K token exploration:**
- Opus cost: $0.30
- Haiku cost: $0.005
**Per-token savings: 60x cheaper**

**Multiply across a project with 10 PRs/week:**
- Wasted cost per week (no plan mode): ~$3
- Cost with plan mode: ~$0.05
**Annual savings: $150+ per developer**

## Environment Hints

Check your project's CLAUDE.md for specifics:

- `CLAUDE_CODE_SUBAGENT_MODEL=haiku` — use cheap subagents by default
- `CLAUDE_CODE_EFFORT_LEVEL=low/medium/high` — controls reasoning depth (Opus/Sonnet only)
- `.claudeignore` — excludes large files from auto-context (reduces token bloat)

Run `/cost show` periodically to see cumulative spending.

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Planning too much | Set a 10-minute timer; accept good-enough plans |
| Skipping tests | Tests catch 70% of bugs; don't skip |
| Reviewing only your own changes | Ask another human or subagent to review |
| Merging without running tests | CI should be required, but verify locally first |
| Committing without typecheck | Add pre-commit hook: `git hook install` |

## Resources

- `.claude/CLAUDE.md` — project-specific customizations
- `docs/quality-ceremonies.md` — recurring quality rituals
- `docs/cost-management.md` — detailed token budgeting
