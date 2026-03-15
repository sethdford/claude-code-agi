# Context Engineering: Token Optimization for Claude 4.6

Claude Opus 4.6 supports a **1M token context window**, but every token still costs money and dilutes model attention. This guide shows how to maximize signal while minimizing waste.

## 1. Use Plan Mode First

**Pattern:** Before complex tasks, enter Plan Mode (Shift+Tab twice) to separate thinking from execution.

**Benefits:**

- Reduces token consumption by 40-50% on analysis-heavy work
- Claude explores the codebase in read-only mode, then presents a plan
- You approve the plan before execution, reducing wasted exploration

**When to use:**

- Refactoring changes (3+ files touched)
- Architectural decisions (new module, data flow change)
- Debugging unfamiliar code
- Multi-step implementations

**How:**

```
1. Press Shift+Tab twice (or type "/plan" command)
2. Claude explores codebase with read-only tools
3. Claude presents a plan for approval
4. You review and approve (or iterate)
5. Claude executes the plan
```

## 2. Configure `.claudeignore`

**Pattern:** Exclude low-signal files and directories from automatic context loading, like `.gitignore`.

**Common exclusions:**

```
# Dependencies (large, not relevant)
node_modules/
.pnpm/
venv/
env/

# Build outputs (rebuilt, not source)
dist/
build/
.next/
.nuxt/
out/

# Dev files (not relevant to most tasks)
.DS_Store
*.log
.env
.env.local

# Large data files
*.csv
*.json (if >10MB)
data/
fixtures/large-data/

# Auto-generated (not hand-written)
*.min.js
*.min.css
.lock files (optional—depends on repo)
```

**Impact:** Reduces context by ~25% on typical Node.js projects.

**Check:**

```bash
wc -c .claudeignore  # See what's excluded
du -sh node_modules dist  # Check size of excluded dirs
```

## 3. Filter Before Injecting

**Pattern:** Never dump raw tool output into context. Extract only relevant fields.

**Wrong:**

```bash
# Don't do this—350 lines of irrelevant output
grep -r "import" src/
```

**Right:**

```bash
# Extract just what matters
grep -r "import.*firebase" src/ | grep "firestore" | head -20
# Or use Grep tool with filters
```

**Common filters:**

```bash
# Filter grep results to files only
grep -l "pattern" src/**/*.ts

# Extract just file names and line numbers
grep -n "TODO" src/ | cut -d: -f1-2

# Show only errors, ignore warnings
jq '.[] | select(.level=="error")' logs.json

# Get first 5 matches, not 500
grep "pattern" file.txt | head -5
```

## 4. Batch Independent Tool Calls

**Pattern:** Make parallel tool calls in a single turn, not sequential round-trips.

**Wrong (multiple turns):**

```
Turn 1: Read file A
Turn 2: Read file B
Turn 3: Read file C
```

**Right (single turn):**

```
Turn 1: Read files A, B, C in parallel
```

**Why:** Each round-trip adds framing overhead (~50 tokens per tool call definition, call/response wrapper).

**Example:**

```typescript
// Instead of 3 sequential calls:
const fileA = await read(pathA);
const fileB = await read(pathB);
const fileC = await read(pathC);

// Make parallel calls (if your tool supports it):
const [fileA, fileB, fileC] = await Promise.all([read(pathA), read(pathB), read(pathC)]);
```

## 5. Delegate Data-Heavy Work to Subagents

**Pattern:** Use the Agent tool to spawn subagents for operations that produce large intermediate results.

**Subagent benefits:**

- Runs on Haiku (cheap, fast)
- Produces summary only (not full output)
- Handles data-heavy codebase searches, log analysis, multi-file reads
- Only the final summary enters your context

**When to use:**

- "Find all API routes that don't have rate limiting" (scan 100 files, return 10)
- "Analyze logs for error patterns" (read 1000 lines, return summary)
- "List all TypeScript errors in the codebase" (parse 50 files, return 5 critical issues)

**Example:**

```markdown
Spawn an Explore agent to find all unhandled promise rejections in src/
Tell me which functions are missing error handling.
```

Result: Agent searches 100 files but returns only a 2-line summary.

## 6. Minimize Tool Definition Bloat

**Pattern:** When connecting MCP servers, only enable tools you actually need.

**How it works:**

- Tool definitions are injected into every API call (~100-500 tokens per tool)
- If you have 50 tools but use 5, you're wasting 45 tool definitions every call
- MCP Tool Search auto-activates when definitions exceed 10% of context

**Optimize by:**

```bash
# In .mcp.json, explicitly list only needed tools
{
  "mcpServers": {
    "firebase": {
      "allowedTools": [
        "firestore_get_document",
        "firestore_list_documents",
        "firestore_update_document"
      ]
    }
  }
}
```

Or use MCP Tool Search:

```bash
# Enable dynamic tool loading
export ENABLE_TOOL_SEARCH=auto:20  # Load tools on demand if >20% of context
```

## 7. Prune Context Aggressively

**Pattern:** When context gets large, summarize completed work and discard intermediate artifacts.

**Before:**

```
Session history (500 tokens):
- Explored file A
- Found bug in file B
- Reviewed 10 similar files
- Identified pattern

Current context usage: 950k / 1M tokens
```

**After pruning:**

```
Summary: Bug fix requires updating 3 files. Pattern: all use deprecated API.

Current context usage: 200k / 1M tokens (re-expanded room for new work)
```

**How to prune:**

- Summarize progress in `tasks/todo.md`
- Save key findings to `.claude/lessons.md`
- Archive old chat history if session is long
- Use `/context` to see usage and identify what to cut

## 8. Prefer Targeted Reads Over Broad Scans

**Pattern:** Read specific line ranges instead of entire files. Use Grep with narrow patterns.

**Wrong (read 500-line file):**

```bash
read(/path/to/big-file.ts)  # All 500 lines loaded
```

**Right (read specific section):**

```bash
read(/path/to/big-file.ts, offset=100, limit=50)  # Lines 100-150 only
```

**Wrong (grep everything):**

```bash
grep -r "import" src/  # Matches 1000+ lines
```

**Right (grep with narrow pattern):**

```bash
grep -r "import.*firebase.*admin" src/  # Matches 15 lines
```

## 9. Use Structured Output for Inter-Agent Communication

**Pattern:** Keep task descriptions and messages concise for agent-to-agent communication.

**Wrong (verbose):**

```
Please analyze the following code snippet, which I found in the authentication module.
The module handles user login and token generation. Here's the full file with all
comments and historical context: [1000 words of code]
```

**Right (structured):**

```json
{
  "task": "review_auth_module",
  "file": "src/lib/auth.ts",
  "focus": "token_generation",
  "concerns": ["jwt_validation", "expiry_handling"]
}
```

## 10. Avoid the Last 20%

**Pattern:** Don't push sessions to context exhaustion. Divide work into context-sized chunks.

**Signs you're near the limit:**

- Context window warning appears
- Claude starts truncating explanations
- Tool outputs seem cut off

**When near limit:**

```
Current context: 850k / 1M tokens (85%)
→ Stop adding new tasks
→ Complete current task
→ Save progress to files
→ Start fresh session

Fresh session reads task progress from files, has full context window again
```

**Use `/context`** to visualize usage as a colored grid. If more than 85% is colored, wrap up.

## 11. Token Budget Planning

**Pattern:** Estimate token cost upfront, plan accordingly.

**Rough estimates:**

- Read a 100-line file: 100 tokens
- Parse full codebase (10k files): 5k-10k tokens
- Run test suite output: 500-2000 tokens
- Tool definition overhead: 50-500 tokens per tool
- Each round-trip conversation: 200-500 tokens

**Example budget:**

```
Task: "Refactor auth module"
Estimated tokens:
- Read current auth files (5 files × 200 lines): 1k tokens
- Grep for usage (1k lines of results): 1k tokens
- Tool definitions (20 tools): 2k tokens
- Conversation/thinking: 3k tokens
- Buffer: 3k tokens

Total: ~10k tokens. Well within budget. Safe to proceed.

Alternative:
Task: "Audit entire codebase for security issues"
Estimated tokens:
- Read all 500 source files: 50k tokens
- Tool definitions: 2k tokens
- Analysis: 5k tokens

Total: ~57k tokens. Still safe but use plan mode to reduce.
```

## Summary Checklist

Before starting a large task:

- [ ] `.claudeignore` configured (exclude node_modules, dist, etc.)
- [ ] Plan mode enabled for complex work (Shift+Tab x2)
- [ ] Grep/Read filters narrow before injecting results
- [ ] Tool calls batched in parallel, not sequential
- [ ] Data-heavy searches delegated to subagents
- [ ] Only essential MCP tools enabled
- [ ] `/context` shows <80% usage
- [ ] Work divided into context-sized chunks (~200k tokens)
- [ ] Progress saved to files before next session

## Related Resources

- Use `/context` to visualize real-time usage
- Environment variable: `CLAUDE_CODE_AUTOCOMPACT_PCT_OVERRIDE=70` (trigger compaction at 70%)
- Set `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` if memory is constrained
- Read CLAUDE.md "Context Engineering" for project-specific patterns
