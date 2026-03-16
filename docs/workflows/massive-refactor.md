# Recipe: Massive Refactor Across Many Files

Refactor a large system (50+ files, 10K+ LOC) with multiple agents working in parallel, no merge conflicts, minimal supervision.

## Overview

This workflow is for large architectural changes:

- Rename a type across the entire codebase (100+ references)
- Extract a shared service into a new package
- Migrate from one framework to another
- Reorganize folder structure across 30+ files
- Update from one API design to another (breaking changes)

**Key principle:** Each agent owns distinct files. No conflicts. Full parallel execution.

**Timeline:** 15-20 minutes for planning, 30-40 minutes for execution, 10-15 minutes for integration/verification.

## Prerequisites

- Main branch is clean and deployable
- Full test suite passes
- TypeScript compiles
- No uncommitted changes
- `.claude/CLAUDE.md` with agent principles

## Phase 1: Understand the Refactor (Plan Mode)

Start in plan mode:

```
Shift+Tab twice

Describe this refactor:
- Current state (what exists now)
- Target state (what you want)
- Key constraints (no breaking API, must stay backwards-compatible, etc.)
- Scope (how many files, which packages)
```

Claude explores the codebase in read-only mode and returns:
- All affected files
- Dependency graph showing which files must change
- Suggested agent boundaries (who owns what files)
- Risk assessment
- Verification strategy

**Output example:**
```
## Refactor Analysis: Extract Auth Service

Affected files: 47
Packages: 3 (web, api, shared)
Dependencies: circular check ✓ (no cycles found)

### Agent Boundaries
- Agent 1 (auth-core): service definition, logic, tests
- Agent 2 (web-integration): web routes, hooks, components
- Agent 3 (api-integration): API middleware, decorators
- Agent 4 (migration): type updates, backwards compatibility

### Risks
- Circular imports if auth imports web
- Tests depend on old implementation

### Verification
- Full test suite must pass
- No TypeScript errors
- No breaking changes for backward-compat
```

Review this plan, ask Claude to adjust if needed, then proceed.

## Phase 2: Create Implementation Plan

Based on the analysis, create a detailed plan:

```
./tasks/refactor-plan.md:

# Extract Auth Service Refactor

## Scope
47 files across 3 packages

## Agent Assignments
| Agent | Files | Responsibility |
|-------|-------|-----------------|
| auth-core | 8 | New auth service: logic, types, tests |
| web-integration | 15 | Update web routes, React hooks, components |
| api-integration | 12 | API middleware, endpoint protection, decorators |
| migration | 10 | Backwards-compat layer, deprecation warnings |
| testing | 2 | Integration tests (no file ownership) |

## Order of Execution
1. auth-core (new service, no dependencies on other agents)
2. web-integration + api-integration (parallel, depend on auth-core)
3. migration (depends on 1 & 2)
4. testing (integration, depends on all)

## Checklist
- [ ] Agent 1 completes
- [ ] Agent 2 completes
- [ ] Agent 3 completes
- [ ] Agent 4 completes
- [ ] Integration tests pass
- [ ] Full suite passes
- [ ] Deploy

## Rollback Plan
If anything breaks, use git reset to pre-refactor state.
```

## Phase 3: Dispatch Agents (Sequential with Dependencies)

Agents work in order (or parallel if independent):

### Wave 1: Core Changes (Agent 1)

```
Agent(
  name: "auth-core",
  model: "sonnet",
  isolation: "worktree"
)

Implement the new auth service.

## Current State
[Description of current auth system]

## Target State
[Description of what the new service should look like]

## Your Scope
You own these files (and ONLY these):
- src/services/auth/index.ts (new)
- src/services/auth/types.ts (new)
- src/services/auth/providers.ts (new)
- src/services/auth/verify.test.ts (new)
- src/lib/old-auth.ts (modify for backwards-compat)

## Requirements
1. Create a new auth service with:
   - Type-safe token verification
   - Provider abstraction (JWT, OAuth, Session)
   - Full test coverage (>80%)

2. Keep old auth working (deprecation mode):
   - Old functions still work, just call new service
   - Add deprecation warnings
   - Document migration path

3. No changes outside your scope:
   - Don't touch web routes, API handlers, or UI components
   - Keep exports stable for now
   - Return to 'auth-core complete' when done

## Verification
- TypeScript compiles with no errors
- Your 4 tests pass
- No changes to files outside your scope

## When Complete
Report:
- Files created/modified
- Breaking vs non-breaking changes
- How other agents should use this service
```

Wait for this agent to complete, verify tests pass.

### Wave 2: Consumer Changes (Agents 2 & 3 in Parallel)

```
Agent(
  name: "web-integration",
  model: "sonnet",
  isolation: "worktree"
)

Update web routes and React hooks to use new auth service.

## Your Scope (15 files)
- pages/login.tsx
- pages/dashboard.tsx
- hooks/useAuth.ts (rewrite)
- components/ProtectedRoute.tsx (update)
- middleware/auth.ts (update)
- [11 more web-specific files from the plan]

## Requirements
1. Replace calls to old auth with new service
2. Update TypeScript types to match new service
3. Keep user-facing behavior identical
4. Add/update tests for each changed component
5. No changes outside your file list

## Integration Point
The new auth service is at src/services/auth/index.ts
Import it like: `import { verifyToken, ... } from '@/services/auth'`

## When Complete
Report changed files and any API incompatibilities.
```

And in parallel:

```
Agent(
  name: "api-integration",
  model: "sonnet",
  isolation: "worktree"
)

Update API middleware and decorators to use new auth service.

## Your Scope (12 files)
- middleware/auth.ts (API side)
- lib/decorators/protected.ts
- lib/decorators/admin-only.ts
- [9 more API-specific files]

## Requirements
1. Replace old auth calls with new service
2. Update error responses to match new auth errors
3. Ensure all endpoint tests still pass
4. No changes outside your scope

## When Complete
Report compatibility notes for web team.
```

Both agents run simultaneously. Wait for both to complete.

### Wave 3: Backwards Compatibility (Agent 4)

```
Agent(
  name: "migration",
  model: "sonnet",
  isolation: "worktree"
)

Create backwards-compatibility layer and migration guides.

## Your Scope (10 files)
- lib/old-auth-compat.ts (new wrapper)
- MIGRATION.md (new guide)
- docs/auth-migration.md (new)
- deprecation-warnings.ts (new)
- [6 more compat files]

## Requirements
1. For any breaking changes from agents 1-3, create compatibility wrappers
2. Add deprecation warnings to old code paths
3. Document migration guide for consuming code outside this refactor
4. Create deprecation timeline (e.g., "remove in v3.0")

## When Complete
Report any remaining breaking changes.
```

Wait for completion.

### Wave 4: Integration Testing (Agent 5)

```
Agent(
  name: "testing",
  model: "sonnet",
  isolation: "worktree"
)

Write integration tests across the new auth system.

## Scope
Create integration tests that verify:
1. Web routes work with new auth
2. API endpoints work with new auth
3. Token refresh flows work end-to-end
4. Sessions work across web and API
5. Backward-compat flows still work

## Files
- src/__tests__/auth-integration.test.ts (new)
- src/__tests__/migration-compat.test.ts (new)

## When Complete
Report test results and any compatibility issues found.
```

## Phase 4: Integration & Verification (5-10 minutes)

After all agents complete, do integration verification:

```bash
# Check for conflicts (should be none)
git status

# Typecheck everything
pnpm typecheck

# Run full test suite
pnpm test

# Build for production
pnpm build

# Smoke test critical flows
curl -X POST http://localhost:3000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"xxx"}'
```

**If any failures:**

Option A (Fix):
```
Agent(
  name: "fix-integration",
  model: "sonnet",
  isolation: "worktree"
)

Fix these integration test failures:
[List failures]

Do NOT change auth-core.
Review other agents' changes and make minimal fixes only.
```

Option B (Rollback):
```bash
git reset --hard HEAD~5  # Back to before refactor
# Or use worktree recovery if agents are still running
```

## Phase 5: Commit & Deploy (2-3 minutes)

Once all tests pass:

```bash
# Review all changes
git diff main...HEAD --stat

# Create summary commit
/commit "refactor: extract auth service, update web and api integration"

# Push to feature branch
git push origin feature/auth-refactor

# Create PR
/commit-push-pr
```

In GitHub:
1. Review the diff (should be clean, 47 files changed as planned)
2. Verify CI passes
3. Merge to main
4. Deploy normally

## Advanced Patterns

### Distributed Agents Across Multiple Worktrees

Keep agents completely isolated:

```bash
# Agent 1
git worktree add .git/worktrees/auth-core feature/auth-core
cd .git/worktrees/auth-core
# Agent runs here

# Agent 2
git worktree add .git/worktrees/web-integration feature/web-int
cd .git/worktrees/web-integration
# Agent runs here

# Merge back to main when done
git checkout main
git merge feature/auth-core
git merge feature/web-int
```

No file conflicts, full parallelism.

### Feature Flagging for Safety

Wrap new auth behind a feature flag:

```typescript
const useNewAuth = process.env.FEATURE_NEW_AUTH === 'true';

function verifyToken(token: string) {
  if (useNewAuth) {
    return newAuthService.verify(token);
  } else {
    return oldAuth.verify(token);
  }
}
```

Deploy with flag off, turn on in stages:
1. Deploy with new code, flag off
2. Verify no errors
3. Enable for 10% of traffic
4. Monitor metrics
5. Roll out to 100%

### Rollback Strategy

If deployment fails:

```bash
# Immediate rollback (1 minute)
gcloud deploy releases revert main-prod

# Investigate (on a branch)
git checkout -b debug/auth-issue
# Fix the issue
/commit
# Re-deploy when ready
```

## Timing Breakdown

| Phase | Time | What Happens |
|-------|------|--------------|
| Plan Mode | 3 min | Understand scope, dependencies, risks |
| Plan Adjustment | 2 min | Refine agent boundaries |
| Dispatch Wave 1 | 1 min | Launch auth-core agent |
| Wave 1 Execution | 10-15 min | Implementation, testing |
| Dispatch Wave 2+3 | 1 min | Launch web and api agents (parallel) |
| Wave 2+3 Execution | 10-15 min | Both run in parallel |
| Wave 4 Execution | 5 min | Integration testing |
| Verification | 5 min | Full test suite, build, smoke tests |
| Commit & Push | 2 min | Atomic commit, open PR |
| **Total** | **~40-45 min** | Complete refactor ready to merge |

## Checklist

- [ ] Understand current state
- [ ] Create implementation plan
- [ ] Dispatch agents in correct order
- [ ] Verify Wave 1 completes
- [ ] Verify Waves 2-3 complete in parallel
- [ ] Verify Wave 4 completes
- [ ] Run full integration verification
- [ ] All tests pass
- [ ] TypeScript compiles
- [ ] Production build succeeds
- [ ] Commit and push
- [ ] PR reviewed and merged
- [ ] Deploy to production
- [ ] Monitor metrics for 1 hour

## Tips

1. **No overlapping file ownership:**
   - Each file is owned by exactly one agent
   - Create this explicitly in the plan
   - Agents only read others' files, never write

2. **Use worktrees for isolation:**
   - Each agent gets its own worktree
   - No merge conflicts
   - Each agent's branch can be reviewed independently

3. **Verify between waves:**
   - After Wave 1, confirm compilation
   - After Waves 2-3, run subset of tests
   - After Wave 4, full integration test

4. **Keep changes small and focused:**
   - Don't let agents drift from their scope
   - Tightly scoped agents are easier to review
   - Small changes = lower risk

5. **Document for the next refactor:**
   - Update `.claude/lessons.md` with what you learned
   - Create a template for next massive refactor
   - Track: what went well, what was hard, timing accuracy
