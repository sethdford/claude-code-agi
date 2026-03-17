# Twitter Thread: claude-code-agi

## Thread: "I open-sourced the config that makes Claude Code act like an AGI agent"

---

**Tweet 1 (Hook)**

I open-sourced a config system that transforms Claude Code from a smart autocomplete into an autonomous agent that remembers, learns, and improves over time.

No new APIs. No proprietary tools. Just good configuration design.

Here's what it does:

🧵

---

**Tweet 2 (Problem)**

Claude Code is powerful. But out of the box, it's amnesic. Every session, you start over. You explain the same errors. You repeat the same patterns. You ask permission for every action.

It's like hiring a genius who forgets everything between meetings.

---

**Tweet 3 (Memory)**

Capability 1: Persistent Memory

Every mistake gets captured automatically. Next session, the agent learns from it.

If it hits a TypeError, memory says: "Last time this happened in users.ts, use optional chaining"

Patterns compound. Code gets better.

---

**Tweet 4 (Autonomy)**

Capability 2: Pre-Approved Permissions

Define what's safe (run tests, lint, make edits). Define what requires approval (delete files, deploy to prod).

No more "Should I run tests?" interrupts.

Agent works. You get results.

---

**Tweet 5 (Parallelism)**

Capability 3: Team Coordination

Dispatch 5+ agents simultaneously, each in its own git worktree.

One explores the codebase. One plans the architecture. One builds the feature. One reviews the code. One deploys.

All parallel. No conflicts.

---

**Tweet 6 (Learning)**

Capability 4: Self-Improvement

When an agent discovers a useful pattern, it captures it as a rule.

Next agent on React code? Reads the rule. Applies the pattern. Velocity increases.

Knowledge compounds over time.

---

**Tweet 7 (Efficiency)**

Capability 5: Context Optimization

Token usage = cost. The system auto-compacts at 70% context.

Summarizes completed work. Preserves relevant context. Result: 40-50% token savings on complex tasks.

More work per dollar.

---

**Tweet 8 (Results)**

Real example: Autonomous bug fix

Bug report: "Sign-up fails for names with apostrophes"

You give one instruction. Agent runs in background (Ctrl+B). 2 hours later: PR #347 ready, test fix verified, all tests pass.

Human time invested: 30 seconds.

---

**Tweet 9 (Installation)**

One-liner to get started:

```
git clone https://github.com/sethdford/claude-code-agi.git ~/.claude/config
source ~/.claude/config/install.sh
```

Includes 12 language presets, 10 workflow recipes, agent templates, hooks.

---

**Tweet 10 (CTA)**

This is where coding assistants stop being tools and start being agents.

Not hype. Tested configs. Working code.

⭐ github.com/sethdford/claude-code-agi

Fork it. Use it. Improve it.

---

## Alternative Shorter Version (7-tweet)

---

**Tweet 1**
I open-sourced a config that makes Claude Code act like an AGI agent. No APIs. No proprietary tools. Just configuration.

🧵 Here's what changed:

---

**Tweet 2**
Problem: Claude Code resets every session. It forgets, asks permission constantly, repeats patterns.

Solution: Capture memory, pre-approve actions, learn from mistakes.

---

**Tweet 3**
Capability 1: Persistent Memory

Every error → automatic capture → next session learns from it

Pattern: "Use optional chaining for profile?.email" (learned from your last mistake)

---

**Tweet 4**
Capability 2: Autonomy

Pre-approve safe operations (test, lint, commit). Block dangerous ones (delete, push to prod).

Agent executes. You get results. No interruptions.

---

**Tweet 5**
Capability 3: Parallelism

5+ agents working simultaneously in isolated git worktrees.

Explore, plan, build, review, deploy in parallel.

Feature done in 1/5th the time.

---

**Tweet 6**
Real result: Autonomous bug fix

Bug report → Agent works in background → 2 hours later: PR ready, tested, merged

Human investment: 30 seconds

---

**Tweet 7**
⭐ github.com/sethdford/claude-code-agi

12 language presets. 10 workflow recipes. Full docs.

This is where AI stops being a tool and starts being an agent.

---

## LinkedIn Post Preview

See `docs/social/linkedin-post.md`

## Hashtags

For all platforms:
#ClaudeCode #AI #Coding #Automation #DevTools #OpenSource #AGI #GitHub #SoftwareEngineering
