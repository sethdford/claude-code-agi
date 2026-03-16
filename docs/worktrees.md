# Git Worktrees for Parallel Development

Git worktrees are isolated working directories tied to different branches in the same repository. They let you work on multiple features simultaneously without checking out and losing context.

## What Worktrees Are

A worktree is a lightweight clone of your git repository that:

- Shares the same `.git` directory (single git database)
- Can check out a different branch independently
- Has its own working directory and file state
- Allows parallel work without branch conflicts

**Key benefit:** Switch between tasks instantly without losing uncommitted changes.

## When to Use Worktrees

| Scenario | Use Worktree | Alternative |
|----------|--------------|-------------|
| Parallel feature work (you + teammate) | ✓ Worktree | Separate clones (slower) |
| Parallel pipelines (automation/AI) | ✓ Worktree | git stash (loses context) |
| Safe experimentation (try idea, revert easily) | ✓ Worktree | git reset --hard (destructive) |
| Agent isolation (prevent merge conflicts) | ✓ Worktree | Different agents same dir (conflicts) |
| Long-running task + active feature work | ✓ Worktree | Branch + stash (painful context switching) |
| PR review while feature in-flight | ✓ Worktree | git stash (loses work) |

## Creating Worktrees with Claude Code

### Easy: Built-in `--worktree` Flag

```bash
shipwright pipeline start --issue 42 --worktree
```

This automatically:
1. Creates a new git worktree
2. Checks out a branch based on the issue
3. Runs the full pipeline (plan → design → build → test → review → merge)
4. Auto-cleans the worktree if no changes remain

**Or with a named worktree:**

```bash
shipwright pipeline start --issue 42 --worktree=feature-auth
```

Worktree is created at `.claude/worktrees/feature-auth/`.

### Using EnterWorktree Tool

For manual worktree control:

```bash
# Create and enter a worktree
/worktree create auth-refactor
```

This:
- Creates `.claude/worktrees/auth-refactor/`
- Checks out a new branch `auth-refactor`
- Switches your session into it

You're now in the worktree. Edit files, run commands, commit normally.

### Exit the Worktree

When done:

```bash
/worktree exit --keep
```

Options:
- `--keep` — Keep worktree and branch (continue work later)
- `--remove` — Delete worktree and branch (clean up)

## Named Worktrees

Name your worktrees for clarity:

```bash
shipwright pipeline start --goal "Refactor auth" --worktree=auth-refactor
```

or

```bash
/worktree create auth-refactor
```

**Naming convention:**
- Feature: `feature-name`
- Bug fix: `fix-issue-123`
- Agent role: `researcher`, `impl-a`, `reviewer`

## Subagent Isolation with Worktrees

In a team, each agent should work in its own worktree:

```yaml
# In your task definition
agents:
  - name: impl-a
    role: "Implement authentication"
    isolation: worktree
    worktree_name: impl-a-auth
    files_owned: ["src/auth/", "src/middleware/"]

  - name: impl-b
    role: "Implement database"
    isolation: worktree
    worktree_name: impl-b-database
    files_owned: ["src/db/", "src/models/"]
```

Each agent gets:
- Separate worktree (no conflicts)
- Separate branch
- Isolated file ownership

When each agent finishes, merge their branches sequentially:

```bash
git merge impl-a-auth
git merge impl-b-database
```

## Disk Space Management: Symlink node_modules

Worktrees can consume significant disk space. Symlink shared dependencies:

```bash
# In your setup script or manually
cd .claude/worktrees/feature-a
rm -rf node_modules
ln -s ../../node_modules ./node_modules
```

**Result:**
- Main repo: `node_modules/` (100 MB)
- Feature-a: `node_modules/` → symlink (0 MB)
- Feature-b: `node_modules/` → symlink (0 MB)
- Total disk: 100 MB (not 300 MB)

**Caution:** If the main `node_modules/` gets deleted, all worktrees break. Keep them separate during heavy development:

```bash
# If you need truly isolated node_modules:
cd .claude/worktrees/feature-a
npm install  # Creates isolated node_modules in worktree only
```

## Running Pipelines in Parallel

Create 3 independent worktrees, run 3 pipelines simultaneously:

```bash
# Terminal 1
shipwright pipeline start --issue 42 --worktree=impl-a

# Terminal 2
shipwright pipeline start --issue 43 --worktree=impl-b

# Terminal 3
shipwright pipeline start --issue 44 --worktree=impl-c
```

All three run in parallel:
- Issue 42 builds in `.claude/worktrees/impl-a/` (branch: `impl-a`)
- Issue 43 builds in `.claude/worktrees/impl-b/` (branch: `impl-b`)
- Issue 44 builds in `.claude/worktrees/impl-c/` (branch: `impl-c`)

**Key point:** No conflicts because each works on its own branch in its own directory.

### Merging Parallel Work

After all pipelines complete, merge back to main:

```bash
git checkout main
git merge impl-a        # Issue 42 changes
git merge impl-b        # Issue 43 changes
git merge impl-c        # Issue 44 changes
git push origin main
```

Or merge via pull requests (safer):

```bash
git push origin impl-a
git push origin impl-b
git push origin impl-c
# Then create PRs on GitHub for review
```

## Worktree Limitations

### 1. Shared `.git` Directory

All worktrees share the same git database. This means:

- **Can't rebase/force-push from one worktree** if another has uncommitted changes on that branch
- **Worktrees block git operations** (e.g., you can't rebase `main` in one worktree while another has `main` checked out)

**Solution:** Each worktree checks out its own branch. Never share branches across worktrees.

### 2. Checking Out Same Branch in Two Worktrees

```bash
# ✗ Bad: Two worktrees on same branch
cd .claude/worktrees/feature-a
git checkout main      # OK in feature-a

cd .claude/worktrees/feature-b
git checkout main      # ERROR: main is already checked out in feature-a
```

**Solution:** Each worktree uses a unique branch:
- feature-a checks out `feature-a-branch`
- feature-b checks out `feature-b-branch`

### 3. No Nested Worktrees

You can't create a worktree inside a worktree:

```bash
cd .claude/worktrees/feature-a
/worktree create nested    # ✗ Error
```

**Solution:** Create all worktrees at the root level.

## Manual Worktree Commands (Advanced)

If you need fine-grained control without Claude Code automation:

### Create a Worktree Manually

```bash
git worktree add .claude/worktrees/my-feature -b my-feature-branch
cd .claude/worktrees/my-feature
```

### List All Worktrees

```bash
git worktree list
```

**Output:**
```
/Users/me/my-repo       abc123 [main]
/Users/me/my-repo/.claude/worktrees/feature-a  def456 [feature-a-branch]
/Users/me/my-repo/.claude/worktrees/feature-b  ghi789 [feature-b-branch]
```

### Remove a Worktree (After Merging)

```bash
# First, ensure all changes are merged back to main
git merge feature-a-branch

# Then remove the worktree
git worktree remove .claude/worktrees/feature-a
```

### Repair a Broken Worktree

If a worktree gets corrupted:

```bash
git worktree repair
```

Or remove and recreate:

```bash
git worktree remove .claude/worktrees/broken
git worktree add .claude/worktrees/fixed -b fixed-branch
```

## Real-World Example: Running 3 Agents in Parallel

**Goal:** Refactor 3 modules in parallel (auth, API, database).

**Setup (Terminal 1):**
```bash
cd /path/to/repo

# Terminal 1: Agent 1 (Auth)
shipwright pipeline start --goal "Refactor auth" --worktree=agent-auth

# Output:
# Creating worktree: .claude/worktrees/agent-auth/
# Branch: agent-auth
# Starting pipeline: plan → design → build → test → review
```

**Setup (Terminal 2):**
```bash
cd /path/to/repo

# Terminal 2: Agent 2 (API)
shipwright pipeline start --goal "Refactor API" --worktree=agent-api

# Output:
# Creating worktree: .claude/worktrees/agent-api/
# Branch: agent-api
# Starting pipeline...
```

**Setup (Terminal 3):**
```bash
cd /path/to/repo

# Terminal 3: Agent 3 (Database)
shipwright pipeline start --goal "Refactor database" --worktree=agent-db

# Output:
# Creating worktree: .claude/worktrees/agent-db/
# Branch: agent-db
# Starting pipeline...
```

**Monitoring:**
```bash
git worktree list
# Shows all three active worktrees and their branches

# Check progress in one worktree
cd .claude/worktrees/agent-auth
git log --oneline | head -5
# See commits being made by Agent 1
```

**After All Pipelines Complete:**

All three agents finish their work in parallel (took ~30 minutes instead of 90):

```bash
# Review and merge back to main
git checkout main
git merge agent-auth    # ✓ Merge auth refactor
git merge agent-api     # ✓ Merge API refactor
git merge agent-db      # ✓ Merge database refactor

# If conflicts:
git mergetool  # Or manually resolve

git push origin main
```

**Cleanup:**
```bash
shipwright cleanup --force
# Removes all worktrees and branches
```

## Worktree vs git stash vs Separate Clone

| Operation | Worktree | git stash | Separate Clone |
|-----------|----------|-----------|-----------------|
| Create new branch without losing changes | ✓ Fast (seconds) | ✓ But cumbersome | ✗ Slow (minutes) |
| Switch between tasks instantly | ✓ Yes | ✗ No (need to stash/pop) | ✗ No (need git checkout) |
| Parallel work on same repo | ✓ Native | ✗ No (share branch) | ✓ Works but wasteful |
| Disk space | ✗ Moderate (share .git) | ✓ Zero (same dir) | ✗ High (duplicate repo) |
| Learning curve | Medium | Low | Very low |
| Recovery if things go wrong | ✓ Good (git worktree repair) | ✗ Bad (stash can be lost) | ✓ OK (just delete clone) |

## Best Practices

### 1. Name Worktrees Clearly

```bash
# ✓ Good
--worktree=feature-auth-redesign
--worktree=fix-issue-1234
--worktree=agent-researcher

# ✗ Bad
--worktree=wt1
--worktree=tmp
--worktree=dev
```

### 2. Each Agent Gets Its Own Worktree

Prevents merge conflicts:

```yaml
agents:
  - name: impl-a
    isolation: worktree
    worktree_name: impl-a

  - name: impl-b
    isolation: worktree
    worktree_name: impl-b
```

### 3. Clean Up After Work

Remove worktrees when done:

```bash
git worktree remove .claude/worktrees/feature-auth
git branch -D feature-auth
```

Or let the auto-cleanup handle it:

```bash
shipwright cleanup --force
```

### 4. Commit Often in Worktrees

Make frequent commits so work is easy to review:

```bash
# In a worktree
git add src/auth/
git commit -m "refactor: simplify auth flow"

git add src/middleware/
git commit -m "refactor: add auth middleware"
```

When merging, the commits are preserved:

```bash
git log main..agent-auth  # See all commits from worktree
```

### 5. Use Unique Branch Names

Avoid ambiguity:

```bash
# ✓ Good
git worktree add .claude/worktrees/agent-1 -b auth-refactor-agent-1

# ✗ Bad
git worktree add .claude/worktrees/wt1 -b auth-refactor  # Unclear
```

## Troubleshooting

### Worktree is "Locked"

Error: `fatal: unable to create '...' (file exists).`

**Cause:** Worktree was deleted but git still thinks it exists.

**Fix:**
```bash
git worktree repair
git worktree list
git worktree remove --force .claude/worktrees/broken
```

### Can't Check Out Branch in Another Worktree

Error: `fatal: 'main' is already checked out at...`

**Cause:** You're trying to check out a branch that's already checked out in another worktree.

**Fix:** Each worktree uses a unique branch. Don't share branches:

```bash
# In worktree-a
git checkout feature-a      # ✓ Unique branch for worktree-a

# In worktree-b
git checkout feature-b      # ✓ Unique branch for worktree-b

# Later, merge both back to main:
git checkout main
git merge feature-a feature-b
```

### Worktree Disk Space Growing

```bash
# Check worktree sizes
du -sh .claude/worktrees/*/

# If too large, symlink node_modules
cd .claude/worktrees/agent-a
rm -rf node_modules
ln -s ../../node_modules ./node_modules
```

### Pipeline Fails in Worktree

Check the worktree's logs:

```bash
cd .claude/worktrees/agent-a
cat .claude/pipeline-state.md
cat .claude/last-error.log
```

Resume the pipeline:

```bash
shipwright pipeline resume
```

Or start fresh:

```bash
git reset --hard HEAD
shipwright pipeline start --issue X --worktree=agent-a
```
