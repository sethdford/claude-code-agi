# Workflow: Onboard to an Unfamiliar Codebase in 10 Minutes

**Goal:** Rapidly understand an unfamiliar codebase and be ready to make productive contributions in under 10 minutes.

**Context:** You're joining a new project, or a colleague handed you a codebase you've never seen. You need to understand structure, entry points, conventions, and data flow without spending hours reading docs.

## Step 1: Dispatch Explore Agent (2 min)

Kick off a read-only agent to map the directory structure in parallel with your work:

```markdown
Agent(explore)
- Read-only mode
- maxTurns: 3
- Model: Haiku (fast)

## Task: Map Codebase Structure

1. Find the root directory structure (up to 3 levels)
2. Identify entry points (main.ts, main.py, package.json, etc.)
3. List all major directories (src/, lib/, app/, pages/, etc.)
4. Find key configuration files (.env.example, config.json, tsconfig.json, etc.)
5. Identify test structure (tests/, spec/, __tests__, etc.)

Return a tree structure with brief purpose for each major directory.
```

This runs in the background while you continue.

## Step 2: Read the README (2 min)

Open `README.md` in the project root:

- **Title**: What is this project?
- **Quick Start**: How do I run it locally?
- **Architecture**: How is it organized?
- **Key Commands**: What are the most common tasks?
- **Contributing**: What conventions should I follow?

**If no README exists:** Look for `CONTRIBUTING.md`, `docs/`, or start with Step 3.

## Step 3: Check Project Metadata (1 min)

Open the project's package/config file:

**For Node.js projects:**
```bash
cat package.json | head -50
```
Look for: name, description, scripts, main entry point, key dependencies

**For Python projects:**
```bash
cat setup.py  # or pyproject.toml
```
Look for: name, description, dependencies, entry points

**For Go/Rust:**
```bash
cat go.mod  # or Cargo.toml
```
Look for: module name, key dependencies

**For Rails:**
```bash
cat Gemfile | head -30
```
Look for: Rails version, key gems

## Step 4: Look for Project Instructions (1 min)

Check for custom guidance files (in order of preference):

```bash
ls -la | grep -E "(CLAUDE|Claude|claude).md|\.md$|docs/"
```

Look for:
- `CLAUDE.md` — custom AI agent conventions
- `.claude/rules/` — modular rules
- `docs/architecture.md` or `docs/standards/` — architecture docs
- `.cursor/rules/` or `.ai/` — tool-specific guidance

Read the most relevant one (usually CLAUDE.md or architecture guide).

## Step 5: Identify Entry Points (1.5 min)

Find where the application starts:

**Frontend (React/Vue/Svelte):**
```bash
# Look for App component or main.tsx
find src -name "App.*" -o -name "main.*" -o -name "index.*" | head -5
```

**Backend (Node/Express):**
```bash
# Check package.json main field and scripts
grep -E '"main"|"start"' package.json
```

**Python/Django:**
```bash
find . -name "manage.py" -o -name "wsgi.py" | head -3
```

**The Explore agent should have already identified these.**

## Step 6: Read 3 Recent PRs (2.5 min)

Check the git log or GitHub for recent merged PRs:

```bash
git log --oneline --graph -10
# Or check GitHub PR history
```

For 3 recent merged PRs:
1. Read the **PR title** (what feature?)
2. Read the **description** (why was it built?)
3. Skim the **files changed** (what parts of the codebase touched?)

This shows you:
- Common patterns the team uses
- Code review standards
- How the team thinks about features

**Time-saving trick:** Look for PRs that touch files you'll likely need to change.

## Step 7: Run the Test Suite (optional, but recommended)

```bash
# Read instructions for running tests
cat README.md | grep -A 5 -E "test|Test"

# Common commands
npm test                    # Node
python -m pytest           # Python
cargo test                 # Rust
go test ./...              # Go
flutter test               # Flutter
```

Running tests tells you:
- Environment is set up correctly
- Key code paths work
- Team's testing philosophy

## Step 8: Write a 1-Page Mental Model

Synthesize what you've learned into a mental model document (keep in your session context or `.claude/notes/`):

```markdown
# [Project] Mental Model

## What is it?
[1-2 sentences describing the project]

## Entry Point
- Main file: [path]
- Start command: [command to run]

## Key Directory Structure
- `/src` — [purpose]
- `/tests` — [purpose]
- `/lib` — [purpose]

## Data Flow
[3-5 sentences: How does data move through the system?]

## Key Abstractions
- [Name]: [1 sentence what it does]
- [Name]: [1 sentence what it does]

## Team Conventions
- Naming: [style]
- Testing: [framework, where to put tests]
- State management: [Redux/Vuex/etc.]
- Code style: [enforced via ESLint/Prettier/etc.]

## Common Tasks
- Run dev server: [command]
- Run tests: [command]
- Build for production: [command]
- Deploy: [command]

## Next Steps for Me
- [ ] Read [specific file] to understand [topic]
- [ ] Set up [local service] for development
- [ ] Run [specific test] to verify environment
```

## Step 9: Verify with the Explore Agent's Results (1 min)

When the Explore agent finishes, compare its findings with your mental model:

- Did it find entry points you missed?
- Are there key directories you overlooked?
- Any test patterns you should know about?

Update your mental model with any gaps.

## Step 10: Pick Your First Task (optional)

You're now ready to contribute. Choose one of:

1. **Read a failing test** — understand what needs to be built
2. **Pick a small bug** — make a meaningful first contribution
3. **Review a recent PR** — deepen your understanding of patterns
4. **Run the dev server** — see the app in action, identify UX

## Timing Checklist

| Step | Time | Total |
|------|------|-------|
| 1. Dispatch Explore agent | 2 min | 2 min |
| 2. Read README | 2 min | 4 min |
| 3. Check package.json / config | 1 min | 5 min |
| 4. Find project instructions | 1 min | 6 min |
| 5. Identify entry points | 1.5 min | 7.5 min |
| 6. Read 3 recent PRs | 2.5 min | 10 min |
| 7. Run tests (optional) | — | optional |
| 8. Write mental model | Async with Explore agent | — |
| 9. Review Explore results | 1 min | bonus |
| 10. Pick first task | — | bonus |

## Pro Tips

- **Use the Explore agent** — It's faster than you. Let it run in parallel.
- **Skim, don't read deeply** — You're building a map, not becoming an expert yet. Deep dives happen task-by-task.
- **Look at tests to understand API** — Tests show you how code is *meant* to be used, not just what it does.
- **Find the "boring" file** — Most projects have a `constants.ts`, `config.py`, or `.env.example`. It tells you what the system actually needs.
- **Check for generated code** — Look for `*.generated.*` or `_generated.ts` files. Don't edit these; they're machine-generated.
- **Identify the DX** — How easy is it to run locally? If there's a `scripts/setup.sh` or Makefile, that's valuable.

## When You Get Stuck

If something is unclear after this workflow:

1. Search the codebase for examples: `grep -r "function_name"` or `find . -name "*pattern*"`
2. Look at tests for that module — they show concrete usage
3. Check the CHANGELOG or recent commits that touched that code
4. Ask a teammate (now you've done your homework and can ask smart questions)

## Estimated Expert Level After This Workflow

- ✅ Can understand new issues and pick them up
- ✅ Know how to run tests and verify changes
- ✅ Can navigate the codebase confidently
- ✅ Can follow team conventions for PRs
- ❌ Not yet expert on deep subsystems (learn task-by-task as needed)

---

**Next:** Pick your first task and use the `/batch` command or individual agent if it's complex enough to benefit from planning.
