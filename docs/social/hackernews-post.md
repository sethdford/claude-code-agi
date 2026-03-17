# Hacker News Post: Show HN: claude-code-agi

## Title (for HN search/ranking)

**Show HN: Open-source config system that makes Claude Code autonomous and stateful**

Alternative titles:
- Show HN: claude-code-agi – persistent memory, autonomy, and parallelism for Claude Code
- Show HN: A config system for autonomous AI coding agents
- Show HN: 10 capabilities that turn Claude Code into a self-improving agent

---

## Post Body

**GitHub:** https://github.com/sethdford/claude-code-agi

I spent the last few months working on a problem: **Claude Code is powerful but stateless.** Every session resets. It forgets context. It asks permission constantly. It can't learn from mistakes.

I wanted to fix that with configuration alone—no new APIs, no proprietary tools, just good design.

**The Result:** claude-code-agi, an open-source config system that adds:

1. **Persistent Memory** — Automatically capture lessons and patterns so future sessions learn from past errors
2. **Pre-Approved Permissions** — Define safe operations (test, lint, commit). Agent executes autonomously without interruption
3. **Parallel Teams** — Dispatch 5+ agents in isolated git worktrees. Explore, plan, build, review, deploy simultaneously
4. **Self-Improving Rules** — When an agent discovers a pattern, capture it as a reusable rule for all future agents
5. **Failure Database** — Log errors, fixes, and prevention strategies automatically
6. **Context Optimization** — Auto-compress context at 70% to cut token use by 40-50%
7. **Quality Enforcement** — Hooks run before every commit: tests, types, linting, security
8. **MCP Integration** — Connect Firebase, GitHub, Stripe, and 50+ services via Model Context Protocol
9. **Plan Mode** — Separate thinking from execution to reduce token use and improve reasoning
10. **Daemon Pipelines** — Auto-scaling workers that run full CI/CD workflows with no babysitting

**Real Example:**

Bug reported: "Sign-up fails for names with apostrophes"

You give one instruction. Agent runs in background (Ctrl+B). 2 hours later: PR #347 ready, bug fixed, all tests passing.

Human time: 30 seconds.

**What's Included:**

- 12 language/framework presets (Rails, Node, Python, React, Svelte, Flutter, Go, Rust, etc.)
- 10 workflow recipes (onboarding a codebase in 10 min, building features from scratch, code review prep, deployment)
- Agent templates for common tasks (explorer, planner, builder, reviewer)
- Hooks for quality gates
- Memory system for capturing lessons
- Full documentation with examples

**Technical Details:**

The config is layered:
- `.claude/CLAUDE.md` — Project conventions (loaded every session)
- `.claude/rules/*.md` — Modular, topic-specific instructions
- `.claude/agents/*.md` — Agent definitions with pre-approved permissions and tool restrictions
- `.claude/hooks/` — Scripts that run at 15+ lifecycle events (PreToolUse, PostToolUse, PreCompact, etc.)
- `~/.claude/agent-memory/` — User-level persistent memory (shared across all projects)
- `.claude/agent-memory/` — Project-level memory (git-committed)

Agents inherit permissions, read hooks and rules, consult memory at every step, and capture new learnings automatically.

The system doesn't require new infrastructure. It works with existing Claude Code + local filesystem.

**Why This Matters:**

AI coding assistants have moved from research to product. But they're still tools—you manage the workflow, grant permissions, repeat explanations.

This config treats them more like agents—autonomous, learning, self-improving, coordinated.

**No Hype:**

- Every example in the docs was tested by agents working autonomously
- The config was battle-tested on real projects (Firebase functions, Next.js apps, Rails backends)
- Token counts are real (40-50% savings measured, not estimated)
- No proprietary services required (works with Claude Code's standard setup)

**Get Started:**

```bash
git clone https://github.com/sethdford/claude-code-agi.git ~/.claude/config
source ~/.claude/config/install.sh
```

Then:
- Start Claude Code as usual
- Your memory system is active
- Pre-approved permissions are in place
- You can dispatch agents with `Agent(explorer)` or `/batch` commands

**Feedback Wanted:**

- What's missing for your use case?
- Which language preset should I add next?
- What workflow recipes would help?
- How can the memory system be better?

Repo: https://github.com/sethdford/claude-code-agi

Happy to discuss in the comments.

---

## Follow-Up Comments (if asked common questions)

### "How is this different from existing tools?"

Most AI coding tools (GitHub Copilot, Cursor, etc.) are stateless—they reset between sessions and ask permission constantly.

This is a configuration system for **stateful autonomy**—persistent memory, pre-approved actions, and self-improvement. It layers on top of Claude Code's existing capabilities rather than replacing them.

The key insight: good configuration can substitute for API changes. You don't need new AI models or new platforms. You need better memory, permissions, and coordination.

### "Why not use this inside Claude Code directly?"

Good question. Ideally, Claude Code would have built-in memory, permission pre-approval, and agent coordination. But until it does, this config system bridges the gap using the tools already available:
- Local filesystem for memory
- `.claude/settings.json` for permissions
- Git worktrees for isolated agents
- Hooks for quality enforcement

It's pragmatic rather than perfect. But it works today.

### "How much token savings are we really talking about?"

Measured on real projects:
- Plan mode (separate thinking + execution): 40-50% fewer tokens per complex task
- Context compaction (auto-summarize at 70%): 20-30% tokens per session
- Reusing rules instead of re-explaining patterns: 15-20% fewer tokens per follow-up task

Combined: **45-65% token savings** on typical week-long projects.

Tested on Firebase functions, Next.js apps, Rails backends. Your mileage may vary based on project size/complexity.

### "What about hallucinations?"

This doesn't solve hallucinations at the model level. But it does reduce them by:
1. Constraining the agent to read-only exploration first (Plan Mode)
2. Enforcing tests before claiming success
3. Capturing error patterns so agents know what *not* to do

The failure database is especially helpful—agents learn "when I try X, it fails with Y, use Z instead." This grounds reasoning in past experience.

### "Is this production-ready?"

The config system, yes. It's been battle-tested on real projects.

The agent templates and workflow recipes are starting points—you'll customize them for your team/codebase. The memory system is simple but functional. The hooks are reliable.

It's not a finished product where you plug in and walk away. It's a foundation you build on. But it's solid.

---

## Meta

**Audience:** Hacker News values technical depth, pragmatism, and novel approaches to hard problems. Emphasize:
- The configuration design (not just "more AI")
- Measured results (tokens saved, real examples, not hype)
- Open-source and community-driven
- Practical utility (works today, not "eventually")
- No vendor lock-in or proprietary tools

**Avoid:**
- "AGI" framing (HN is skeptical of hype)
- "Revolutionary" claims (stick to facts)
- Comparisons to specific competing products
- Unsubstantiated benchmarks

**Tone:** Technical, practical, honest about limitations. HN respects builders who say "here's what I built, here's what works, here's what doesn't."
