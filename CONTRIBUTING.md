# Contributing to Claude Code AGI

Thanks for contributing! Here's how to help.

## Adding a New Preset

Presets are opinionated configuration templates for different tech stacks. They help teams get started faster by bundling conventions specific to their stack.

1. Create `presets/<stack-name>/<stack-name>.md`
2. Write 40-80 lines of opinionated conventions
3. Focus on patterns Claude should follow, not documentation
4. Include:
   - Model selection guidance for your stack
   - Testing strategy (framework, coverage targets)
   - Deployment process (how to validate before deploying)
   - Performance expectations (token limits, complexity thresholds)
   - Error recovery patterns specific to your stack
5. Update `setup.sh` to include your preset in the selection menu
6. Update `README.md` presets table
7. Submit a PR with description of the stack and why these conventions matter

**Example structure:**
```markdown
# Next.js Preset

## Model Selection
Claude Opus 4.6 for complex pages and API routes, Haiku for component refactoring.

## Testing Strategy
Vitest + React Testing Library. 80% line coverage required before deploy.

## Deployment
Run `pnpm build && pnpm test:ci` before pushing. Use Vercel previews for validation.
```

## Adding a New Hook

Hooks automate workflows at lifecycle events (session start, file changes, test failures, etc.).

1. Create `core/hooks/<hook-name>.sh`
2. Make it executable: `chmod +x`
3. Use `{{PROJECT_URL}}` and `{{PROJECT_ID}}` as placeholders for setup.sh substitution
4. Include a header comment explaining when the hook runs and what it does
5. Use `set -euo pipefail` for safety
6. Register in `core/settings.json` under the appropriate event
7. Document in README under "Hooks"

**Example hook:**
```bash
#!/usr/bin/env bash
# Runs on test failures - captures error patterns for lessons.md
set -euo pipefail

# Hook receives stdin as JSON with failure context
INPUT=$(cat)

# Do something useful with the input
echo "Test failure detected" >> .claude/lessons.md
```

## Adding a New Doc

Documentation should be practical and actionable — real examples, no fluff.

1. Create `docs/<topic>.md`
2. Include step-by-step instructions with exact commands
3. Include timing estimates where relevant
4. Include example prompts or configurations
5. Cross-reference related docs
6. Update `docs/README.md` table of contents

**Format:**
```markdown
# Topic

## Overview
One paragraph explaining what this is for.

## When to Use
Bullet list of scenarios.

## How It Works
Step-by-step explanation.

## Example
Code example with expected output.

## Related Docs
Links to related content.
```

## Adding a Workflow Recipe

Recipes are step-by-step guides for accomplishing common tasks using Claude Code.

1. Create `docs/workflows/<recipe-name>.md`
2. Include exact commands to run
3. Include timing estimates
4. Include example prompts for agents
5. Include success criteria (how to know it worked)

**Example recipe:**
```markdown
# Audit Codebase (30 min)

## Goal
Understand architecture and identify code quality issues.

## Steps
1. Use `/batch` to spawn 3 exploratory agents
2. Agent 1: Search for TypeScript errors
3. Agent 2: Identify missing test coverage
4. Agent 3: Find performance bottlenecks

## Success Criteria
All agents report findings in less than 5 minutes.
```

## Testing

Before submitting a PR, test the setup script:

```bash
# Test on Linux
mkdir /tmp/test-linux
echo -e "/tmp/test-linux\ntest-project\n\n\nnone\nn" | bash setup.sh

# Test on macOS
mkdir /tmp/test-mac
echo -e "/tmp/test-mac\ntest-project\n\n\nnone\nn" | bash setup.sh

# Verify all files created
test -f /tmp/test-linux/.claude/CLAUDE.md && echo "✓ CLAUDE.md created"
test -f /tmp/test-linux/.claude/settings.json && echo "✓ settings.json created"
test -x /tmp/test-linux/.claude/hooks/session-start-context.sh && echo "✓ hooks are executable"
```

## Code Style

- **Markdown files**: 80 character line width preferred
- **Shell scripts**: Use `set -euo pipefail` at the top
- **JSON files**: Use 2-space indentation
- **Placeholders**: Use `{{PLACEHOLDER}}` syntax for user-configurable values in templates
- **No emojis**: Keep text clear and professional

## Commit Message Format

```
type(scope): subject (lowercase, max 72 chars)

Optional body explaining the change.
```

Types: `feat`, `fix`, `docs`, `chore`, `refactor`

Examples:
- `feat(preset): add Terraform preset`
- `docs(hooks): explain session-start-context behavior`
- `fix(setup): handle symlinks in project paths`

## Pull Request Process

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-preset`
3. Make your changes
4. Test locally: Run the setup script against a temp directory
5. Verify hooks are executable: `ls -la core/hooks/*.sh`
6. Check JSON syntax: `python3 -m json.tool <file>`
7. Commit with conventional format
8. Push and open a PR

In your PR description, include:
- What you added (preset, hook, doc, recipe, etc.)
- Why it matters
- How to test it
- Any breaking changes

## Code Review Standards

PRs should meet these criteria before merge:

- [ ] Setup script runs without errors on both Linux and macOS
- [ ] All new files have proper permissions (hooks are executable)
- [ ] JSON files are valid and well-formatted
- [ ] Markdown files follow the 80-character guideline
- [ ] Documentation is clear and includes examples
- [ ] Commit messages follow conventional format
- [ ] No hardcoded paths or credentials
- [ ] All placeholders use `{{PLACEHOLDER}}` syntax
- [ ] Tests pass (run locally before submitting)

## Questions?

Open a discussion in the repo. We're here to help.
