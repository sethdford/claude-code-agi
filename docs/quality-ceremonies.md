# Quality Ceremonies & Recurring Rituals

This guide defines recurring quality rituals that prevent standards drift and catch issues early. These ceremonies can be automated via git hooks, CI/CD pipelines, or manual scripts—adapt them to your project.

Quality ceremonies are the difference between "shipping code that works today" and "maintaining code that works for years."

## The Ceremony Pyramid

```
Release Gate (quarterly)
  ↑
Weekly Drift Audit
  ↑
PR Gate (per-merge)
  ↑
Pre-Push Verification
  ↑
Pre-Commit (every change)
```

## Pre-Commit: Guard the Barrier

**When:** Before `git commit`
**Who:** Local developer (or git hook)
**Cost:** 30 seconds per commit

### Checklist

- [ ] **Format check** — code is prettier-compliant
- [ ] **Lint check** — no obvious code smell (unused vars, etc.)
- [ ] **Type check** — no TypeScript errors
- [ ] **Jest/Vitest** — all unit tests pass
- [ ] **No secrets** — no API keys, tokens, or PII in code

### Implementation

**Via Git Hooks (Husky):**

```bash
# Install husky
pnpm install husky --save-dev
npx husky install

# Create pre-commit hook
cat > .husky/pre-commit << 'EOF'
#!/bin/sh
pnpm run format:check || exit 1
pnpm run lint || exit 1
pnpm run typecheck || exit 1
pnpm test -- --run --bail || exit 1
EOF

chmod +x .husky/pre-commit
```

**Via Script (if not using hooks):**

```bash
#!/bin/bash
# scripts/pre-commit-check.sh
set -e

echo "Checking format..."
pnpm format:check

echo "Checking lint..."
pnpm lint

echo "Type checking..."
pnpm typecheck

echo "Running tests..."
pnpm test -- --run

echo "✓ Pre-commit checks passed"
```

Run before every commit:
```bash
./scripts/pre-commit-check.sh && git commit -m "..."
```

### Coverage Thresholds

Define in `vitest.config.ts` or `jest.config.js`:

```javascript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
    },
  },
})
```

If coverage drops below thresholds, the commit is rejected. Force push only with explicit `--no-verify`:

```bash
# Bad habit — don't do this
git commit --no-verify

# Good — fix coverage first
pnpm test --coverage
# [add tests until coverage recovers]
git commit -m "feat: add X with tests"
```

## Pre-Push: Verification Suite

**When:** Before `git push` (or before creating PR)
**Who:** Local developer (or CI on PR)
**Cost:** 2-3 minutes

### Checklist

- [ ] All tests pass (full suite, not just changed tests)
- [ ] Full build succeeds
- [ ] Type check passes (strict mode)
- [ ] Lint passes
- [ ] No merge conflicts with main
- [ ] Doc index is current (no orphaned .md files)
- [ ] Security audit passes (no high/critical CVEs)

### Implementation

**Via Husky Pre-Push Hook:**

```bash
cat > .husky/pre-push << 'EOF'
#!/bin/sh

echo "Running full verification suite..."
set -e

pnpm test -- --run
pnpm typecheck
pnpm lint
pnpm build
./scripts/check-doc-index.sh
pnpm audit --audit-level=high

echo "✓ All verification checks passed"
EOF

chmod +x .husky/pre-push
```

**Via Manual Script:**

```bash
#!/bin/bash
# scripts/pre-push-check.sh
set -e

echo "═══════════════════════════════════════"
echo "Running Full Verification Suite"
echo "═══════════════════════════════════════"

echo "1/6 Testing..."
pnpm test -- --run || exit 1

echo "2/6 Type checking..."
pnpm typecheck || exit 1

echo "3/6 Linting..."
pnpm lint || exit 1

echo "4/6 Building..."
pnpm build || exit 1

echo "5/6 Checking docs..."
./scripts/check-doc-index.sh || exit 1

echo "6/6 Security audit..."
pnpm audit --audit-level=high || exit 1

echo ""
echo "✓ All checks passed. Ready to push."
```

## PR Gate: Merge Requirements

**When:** Before merging to main
**Who:** Automated CI + code reviewer
**Cost:** Zero (automated)

### GitHub Actions Checklist

```yaml
# .github/workflows/pr-gate.yml
name: PR Gate

on:
  pull_request:
    branches: [main]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v2

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'

      - name: Install deps
        run: pnpm install --frozen-lockfile

      - name: Format check
        run: pnpm format:check

      - name: Lint
        run: pnpm lint

      - name: Type check
        run: pnpm typecheck

      - name: Test
        run: pnpm test -- --run --coverage

      - name: Build
        run: pnpm build

      - name: Security audit
        run: pnpm audit --audit-level=high

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
```

### PR Template Checklist

Add to `.github/PULL_REQUEST_TEMPLATE.md`:

```markdown
## Description
[What does this PR do?]

## Related Issue
Fixes #[issue number]

## Changes
- [ ] Backend logic
- [ ] Frontend UI
- [ ] Database schema
- [ ] Tests
- [ ] Documentation

## Checklist
- [ ] All tests pass
- [ ] No new TypeScript errors
- [ ] Code coverage maintained (>80%)
- [ ] No console.error or console.warn left
- [ ] Related docs updated
- [ ] No hardcoded secrets or credentials

## How to Verify
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Screenshots (if UI changes)
[Add screenshots or GIFs]
```

**Required merge conditions (GitHub Settings):**
- At least 1 approval (or 2 for sensitive areas)
- All status checks pass
- PR branch is up-to-date with main
- No conversation comments pending

## Weekly Drift Audit

**When:** Every Monday at start of day
**Who:** Team lead or automation
**Cost:** 10-15 minutes
**Purpose:** Catch standards erosion early

### Drift Audit Checklist

```bash
#!/bin/bash
# scripts/weekly-drift-audit.sh
set -e

echo "════════════════════════════════════"
echo "Weekly Standards Drift Audit"
echo "════════════════════════════════════"

echo ""
echo "1. Full verification suite..."
./scripts/verify-all.sh || echo "⚠ Some checks failed"

echo ""
echo "2. Checking for orphaned docs..."
./scripts/check-doc-index.sh || echo "⚠ Orphaned .md files found"

echo ""
echo "3. Checking for hardcoded secrets..."
git grep -E 'sk-ant-|api[_-]?key|password' src/ || echo "✓ No exposed secrets"

echo ""
echo "4. Checking for console statements in production code..."
git grep -E 'console\.(log|warn|error)' packages/*/src --exclude='*.test.ts' --exclude='*.spec.ts' || echo "✓ No console statements"

echo ""
echo "5. Checking commit message format..."
git log --oneline -20 | grep -E '^[0-9a-f]{7} (feat|fix|refactor|docs|style|test|chore|ci):' || echo "⚠ Check recent commits"

echo ""
echo "6. TypeScript coverage..."
pnpm typecheck

echo ""
echo "════════════════════════════════════"
echo "Drift Audit Complete"
echo "════════════════════════════════════"
```

**Report outputs to:**
- Slack channel: `#weekly-drift-audit`
- GitHub issue (optional): creates a tracking issue if drift found
- Email to team lead

### Drift Detection Scripts

Create these helper scripts:

**`scripts/check-doc-index.sh`** — Find orphaned .md files:

```bash
#!/bin/bash
# Find all .md files NOT in docs/
find . -name "*.md" \
  -not -path "./node_modules/*" \
  -not -path "./.git/*" \
  -not -path "./.next/*" \
  -not -path "./dist/*" \
  -not -path "./docs/*" \
  | while read file; do
  if ! grep -r "$(basename "$file")" docs/README.md docs/*/README.md 2>/dev/null; then
    echo "⚠ Orphaned: $file"
  fi
done
```

**`scripts/verify-all.sh`** — Comprehensive verification:

```bash
#!/bin/bash
# Full verification suite (format, lint, type, test, build, security)
set -e

echo "Formatting..."
pnpm format:check

echo "Linting..."
pnpm lint

echo "Type checking..."
pnpm typecheck

echo "Testing..."
pnpm test -- --run

echo "Building..."
pnpm build

echo "Security audit..."
pnpm audit --audit-level=high

echo "✓ All checks passed"
```

## Release Gate: Pre-Release Audit

**When:** Before deploying a release
**Who:** Release manager + engineering lead
**Cost:** 30 minutes
**Triggers:** Every release tag or manual approval

### Release Checklist

```markdown
## Release Gate Checklist for v[X.Y.Z]

### Code Quality
- [ ] All tests pass (full suite)
- [ ] Coverage remains >80%
- [ ] No TypeScript errors
- [ ] No lint warnings
- [ ] Build succeeds

### Standards Compliance
- [ ] Run full drift audit: `./scripts/verify-all.sh`
- [ ] No orphaned docs: `./scripts/check-doc-index.sh`
- [ ] CHANGELOG updated with all changes
- [ ] Version bumped in package.json
- [ ] Git tag created: `git tag v[X.Y.Z]`

### Security
- [ ] Security audit passes: `pnpm audit --audit-level=high`
- [ ] No new secrets in code
- [ ] Dependency updates reviewed
- [ ] Breaking changes documented

### Documentation
- [ ] README updated if user-facing changes
- [ ] CHANGELOG follows conventional format
- [ ] Migration guide (if applicable)
- [ ] Deprecation notices (if applicable)

### Testing
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Smoke tests pass (if applicable)
- [ ] Manual test checklist completed

### Performance
- [ ] Bundle size check (if applicable)
- [ ] Database migration tested (if applicable)
- [ ] No performance regressions

### Approval
- [ ] Engineering lead approval: [Name]
- [ ] Product manager approval: [Name]
- [ ] Security team approval (if infrastructure): [Name]

**Release approved by:** [Name] at [Timestamp]
```

## Automation: CI/CD Pipeline

Here's a typical GitHub Actions workflow combining all gates:

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'pnpm'
      - run: pnpm install --frozen-lockfile
      - run: pnpm format:check
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test -- --run --coverage
      - run: pnpm build
      - run: pnpm audit --audit-level=high

  drift:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/check-doc-index.sh

  release:
    if: startsWith(github.ref, 'refs/tags/v')
    needs: [test, drift]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: echo "✓ Release ${{ github.ref }} approved"
      # Deploy steps here
```

## Example: AIM Monorepo Quality Setup

Integrate these ceremonies into your monorepo:

```bash
# Root-level verification
pnpm -r format:check
pnpm -r lint
pnpm -r typecheck
pnpm -r test -- --run
pnpm -r build

# Drift checks
./scripts/check-doc-index.sh
./scripts/check-design-tokens.sh
./scripts/check-brand-compliance.sh
```

## Metrics to Track

Monitor ceremony effectiveness:

| Metric | Target | Why It Matters |
|--------|--------|----------------|
| Pre-commit success rate | >95% | Few rejected commits = good hygiene |
| PR review time | <24h | Faster feedback = faster velocity |
| Bug escape rate | <5% | Most bugs caught before production |
| Test coverage | >80% | High coverage = fewer surprises |
| Release rollback rate | 0% | No rollbacks = confidence |
| Drift audit failures | 0 | Standards maintained |

## Common Pitfalls

| Pitfall | Prevention |
|---------|-----------|
| Hooks too strict (block legitimate commits) | Start permissive, tighten over time |
| Outdated docs (drift audit ignores stale files) | Enforce doc reviews in PR gate |
| Coverage metric gamed (high % but low quality) | Require code review on coverage changes |
| Ceremonies become busywork | Automate everything; only humans decide |
| No rollback procedure for bad releases | Document release undo steps upfront |

## Resources

- `.github/workflows/` — CI/CD pipeline definitions
- `.husky/` — Git hooks (pre-commit, pre-push)
- `scripts/` — Local verification scripts
- `CHANGELOG.md` — Release notes by version
- `.github/PULL_REQUEST_TEMPLATE.md` — PR checklist
