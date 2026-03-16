# Recipe: Audit an Entire Codebase

Systematically audit a codebase for quality, security, architectural issues, and compliance in minutes using parallel agents.

## Overview

This workflow uses 7 parallel Explore agents to partition a large codebase and audit it simultaneously:

1. **Architecture Agent** — Review package structure, dependencies, coupling
2. **Security Agent** — Check auth, secrets, injection vulnerabilities, rate limiting
3. **Testing Agent** — Verify test coverage, test quality, missing tests
4. **Performance Agent** — Identify bottlenecks, N+1 queries, unused code
5. **Code Quality Agent** — Linting, TypeScript strictness, naming, duplication
6. **Docs Agent** — Check README, API docs, inline comments, standards compliance
7. **Compliance Agent** — License headers, deprecated deps, EOL versions

Total time: ~2 minutes for agents to complete, ~5 minutes for fixes, ~10 minutes for full suite.

## Prerequisites

- `~/.claude/CLAUDE.md` configured with agent principles
- `.claude/agents/` with agent templates (or create inline)
- Full test suite passing
- Git on main branch, no uncommitted changes

## Workflow

### Phase 1: Plan (2 minutes)

Start in plan mode to understand the scope:

```
Shift+Tab twice

Analyze this codebase and suggest audit domains. For each domain,
list the key patterns to check (3-5 per domain).

Focus on:
- Architecture (circular deps, monolithic modules)
- Security (auth, rate limiting, input validation)
- Testing (coverage gaps, flaky tests)
- Performance (n+1 queries, memory leaks)
- Code quality (TypeScript, linting, dead code)
- Docs (README, standards compliance)
- Compliance (licenses, deprecated deps)
```

Claude creates a plan with audit domains and key checks per domain.

### Phase 2: Dispatch Agents (2 minutes)

Use the Agent tool to spawn 7 parallel Explore agents. Each agent covers one domain.

**Architecture Agent:**
```
Agent(name: "architecture-auditor", model: "haiku", isolation: "none")

Audit the codebase architecture:

1. Map package boundaries — are they clear?
2. Check for circular dependencies: grep -r "import.*from" | cycle detection
3. Identify highly coupled modules (>5 imports from same source)
4. Check monolithic modules (files >500 lines)
5. Verify layering (components don't import features, features don't import each other)

For each issue found, provide:
- File path and line
- Root cause
- Severity (critical/high/medium/low)
- Suggested fix

Use only Glob and Grep tools. Do not read entire files.
```

**Security Agent:**
```
Agent(name: "security-auditor", model: "haiku", isolation: "none")

Audit security practices:

1. Authentication checks:
   - Find all route handlers and verify auth checks
   - List unprotected endpoints

2. Secrets detection:
   - Search for hardcoded API keys, tokens, passwords
   - Check .env.example has all required vars

3. Input validation:
   - Find all input-accepting functions
   - Verify they validate before use
   - Check for SQL injection, XSS, command injection patterns

4. Rate limiting:
   - Find all API endpoints
   - Verify rate limiting on public routes

5. CORS and headers:
   - Check for overly permissive CORS
   - Verify security headers (CSP, X-Frame-Options, etc.)

For each issue found, provide file, line, severity, and fix.
```

**Testing Agent:**
```
Agent(name: "testing-auditor", model: "haiku", isolation: "none")

Audit test coverage and quality:

1. Coverage analysis:
   - Find test directory
   - Calculate coverage percentage
   - Identify files with <50% coverage

2. Test patterns:
   - Find slow tests (>500ms)
   - Identify flaky patterns (sleeps, timeouts)
   - Check for meaningful assertions (not just "expect(x).toBeTruthy()")

3. Missing tests:
   - Identify untested critical paths
   - Find 404/error handlers without tests
   - Check middleware coverage

4. Test maintenance:
   - Find commented-out tests
   - Identify tests with wrong descriptions
   - List tests with .skip or .only

Report file, severity, and recommended fix.
```

**Performance Agent:**
```
Agent(name: "performance-auditor", model: "haiku", isolation: "none")

Audit for performance issues:

1. Database queries:
   - Find database query patterns
   - Identify missing indexes (look for large result loops)
   - Check for n+1 patterns

2. Memory leaks:
   - Find event listeners without cleanup
   - Check for circular references
   - Identify uncleared intervals/timeouts

3. Bundle size:
   - Identify large dependencies
   - Find unused imports
   - Check for large data structures in memory

4. Rendering/execution:
   - Find long-running loops
   - Identify blocking operations
   - Check for synchronous I/O

List file, line, issue, and suggested optimization.
```

**Code Quality Agent:**
```
Agent(name: "code-quality-auditor", model: "haiku", isolation: "none")

Audit code quality:

1. TypeScript strictness:
   - Find any/unknown types
   - Check for missing type annotations
   - Verify function signatures are typed

2. Naming:
   - Find single-letter variable names (except loops)
   - Check function names describe behavior
   - Verify constant names are SCREAMING_SNAKE_CASE

3. Duplication:
   - Find repeated code patterns (3+ occurrences)
   - Identify similar functions that could be generalized

4. Complexity:
   - Find functions with deep nesting (>3 levels)
   - Identify functions with many branches (>10 paths)

5. Modern practices:
   - Check for use of deprecated APIs
   - Verify error handling (no bare throws, catches)
   - Check for const/let usage (no var)

Report by file, with severity and refactoring suggestion.
```

**Docs Agent:**
```
Agent(name: "docs-auditor", model: "haiku", isolation: "none")

Audit documentation:

1. Project-level docs:
   - Check README exists and covers: setup, build, dev, test, deploy
   - Verify architecture document exists
   - Check CONTRIBUTING.md or similar exists

2. Code documentation:
   - Find undocumented exported functions
   - Identify complex logic without comments
   - Check for outdated comments

3. API documentation:
   - Verify all endpoints have descriptions
   - Check for parameter/response documentation
   - Ensure error codes documented

4. Standards compliance:
   - Check if project follows declared standards
   - Verify .claude/CLAUDE.md exists and is current
   - List standards not yet adopted

Report missing docs by file/section.
```

**Compliance Agent:**
```
Agent(name: "compliance-auditor", model: "haiku", isolation: "none")

Audit compliance and dependencies:

1. License headers:
   - Check source files have correct license header
   - Verify LICENSE file exists
   - Check dependencies have compatible licenses

2. Dependencies:
   - Find deprecated packages
   - Identify packages with known vulnerabilities
   - Check for unused dependencies

3. Version compliance:
   - Verify Node/Python/etc. version in package.json matches requirements
   - Check for EOL language versions
   - Identify unpinned versions that could break builds

4. Build/CI:
   - Verify CI configuration exists (.github/workflows or similar)
   - Check for secrets in CI logs
   - Verify deployments are protected

Report by file/package.
```

Save each agent invocation and let them run in parallel. Check status with `/tasks`.

### Phase 3: Collect Findings (1 minute)

Agents complete in ~2 minutes. Collect their output into a master report.

Create `audit-findings.md`:

```markdown
# Codebase Audit Report

Generated: [timestamp]

## Executive Summary

- Total issues found: XX
- Critical: X  | High: X  | Medium: X  | Low: X
- Estimated fix time: X hours

## By Domain

### Architecture (Agent: architecture-auditor)
[Issues from agent output]

### Security (Agent: security-auditor)
[Issues from agent output]

### Testing (Agent: testing-auditor)
[Issues from agent output]

### Performance (Agent: performance-auditor)
[Issues from agent output]

### Code Quality (Agent: code-quality-auditor)
[Issues from agent output]

### Documentation (Agent: docs-auditor)
[Issues from agent output]

### Compliance (Agent: compliance-auditor)
[Issues from agent output]

## Top 5 Priorities

1. [Highest impact fix]
2. [Second priority]
3. ...

## By Severity

### Critical (X issues)
[List and fix immediately]

### High (X issues)
[Fix before next release]

### Medium (X issues)
[Schedule for next sprint]

### Low (X issues)
[Nice-to-haves]
```

### Phase 4: Fix Issues (5-10 minutes)

For critical and high issues, dispatch fix agents:

```
Agent(name: "fix-security", model: "sonnet", isolation: "worktree")

Fix these security issues:
1. [Critical issue 1]
2. [Critical issue 2]
3. [High issue 1]

For each:
- Show the current code
- Explain why it's insecure
- Implement the fix
- Add a test if missing

Use worktree isolation to avoid conflicts.
```

For medium/low issues, create GitHub issues for tracking:

```bash
gh issue create --title "Code quality: remove unused imports" \
  --body "See audit-findings.md. Low priority, can batch with other refactors."
```

### Phase 5: Verify (2-3 minutes)

Run the full suite to ensure no regressions:

```bash
pnpm test                    # Full test suite
pnpm typecheck              # TypeScript check
pnpm build                  # Production build
./scripts/verify-all.sh     # All checks (if available)
```

All should pass before proceeding.

### Phase 6: Commit & Push (1 minute)

```bash
git add -A
/commit                      # Atomic commit with generated message
/commit-push-pr             # Push and open PR
```

Then review the PR in your browser and merge.

## Total Timeline

| Phase | Time | What Happens |
|-------|------|--------------|
| Plan | 2 min | Understand scope, domains, checks |
| Dispatch | 1 min | Spawn 7 agents |
| Agents Run | 2 min | Parallel exploration |
| Collect | 1 min | Master report |
| Fix Critical | 5-10 min | High-priority fixes via agents |
| Verify | 2-3 min | Full test suite, typecheck, build |
| Commit | 1 min | Atomic commit and PR |
| **Total** | **~15-20 min** | Complete audit + fixes |

## Advanced Variations

### Quick Audit (5 minutes)
Run agents but skip fixes:
1. Plan (2 min)
2. Dispatch (1 min)
3. Agents (2 min)

Results: report only, issues tracked for later.

### Deep Audit (30 minutes)
Add detailed investigation:
1. Include agent turns for verification ("Deep dive on X")
2. Run integration tests between fixes
3. Do manual code review of complex fixes

### Focused Audit (10 minutes)
Audit specific domains only:
```
Agent(name: "security-only", ...)  # Only security agent
Agent(name: "perf-only", ...)       # Only performance agent
```

Run 2-3 focused agents instead of all 7.

## Tips

1. **Use worktrees for fixes:**
   - Each fix agent gets `isolation: "worktree"`
   - No merge conflicts between parallel fixes
   - Each agent can commit independently

2. **Batch low-priority fixes:**
   - Don't fix every medium/low issue immediately
   - Create GitHub issues, batch in next sprint
   - Focus on critical/high for quick wins

3. **Run plan mode first:**
   - Verify audit domains match your codebase
   - Adjust agent prompts if needed
   - Skip domains that don't apply

4. **Parallelize aggressively:**
   - All 7 agents run simultaneously
   - They only use read-only tools (Glob, Grep, Read)
   - No conflicts, much faster than serial

5. **Verify after each phase:**
   - Run tests after fixes
   - Check typecheck passes
   - Build succeeds before committing

## Customization

Create your own agent list:

```bash
cat > ~/.claude/agents/custom-auditors.md <<EOF
# Custom Audit Agents

## Your Domain Agent
[Custom audit instructions]

## Another Domain
[Custom instructions]
EOF
```

Then reference them in the dispatch phase:
```
Agent(name: "your-domain-auditor", model: "haiku", ...)
```
