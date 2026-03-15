#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${BLUE}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║         Claude Code AGI Setup         ║"
echo "  ╠═══════════════════════════════════════╣"
echo "  ║  Autonomous Agent Configuration Kit   ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Target directory
if [ -n "${1:-}" ]; then
  TARGET_DIR="$1"
else
  read -p "Target project directory [$(pwd)]: " TARGET_DIR
  TARGET_DIR="${TARGET_DIR:-$(pwd)}"
fi

TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}Directory not found: $TARGET_DIR${NC}"
  exit 1
fi

echo -e "${GREEN}Target: $TARGET_DIR${NC}"

# Step 2: Project name
DEFAULT_NAME="$(basename "$TARGET_DIR")"
read -p "Project name [$DEFAULT_NAME]: " PROJECT_NAME
PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_NAME}"

# Step 3: Production URL
read -p "Production URL (for health checks, leave empty to skip): " PROJECT_URL
PROJECT_URL="${PROJECT_URL:-}"

# Step 4: GCP Project ID
read -p "GCP Project ID (leave empty to skip): " PROJECT_ID
PROJECT_ID="${PROJECT_ID:-}"

# Step 5: Presets
echo ""
echo -e "${BOLD}Select presets (comma-separated, or 'none'):${NC}"
echo "  1) firebase   - Firestore, Cloud Functions patterns"
echo "  2) nextjs     - Next.js App Router, API routes"
echo "  3) vitest     - Vitest testing conventions"
echo "  4) gcloud     - GCP deployment patterns"
echo "  5) security   - Rate limiting, auth, secrets"
echo "  a) all        - Install all presets"
read -p "Presets [none]: " PRESET_INPUT
PRESET_INPUT="${PRESET_INPUT:-none}"

# Step 6: Agents
echo ""
read -p "Install example agents (code-reviewer, security-reviewer)? [Y/n]: " INSTALL_AGENTS
INSTALL_AGENTS="${INSTALL_AGENTS:-Y}"

echo ""
echo -e "${BOLD}${BLUE}Installing...${NC}"

# Create directories
mkdir -p "$TARGET_DIR/.claude/hooks"
mkdir -p "$TARGET_DIR/.claude/rules"
mkdir -p "$TARGET_DIR/.claude/session-logs"
mkdir -p "$TARGET_DIR/docs/plans"

# Copy core files
cp "$SCRIPT_DIR/core/CLAUDE.md" "$TARGET_DIR/.claude/CLAUDE.md"
cp "$SCRIPT_DIR/core/settings.json" "$TARGET_DIR/.claude/settings.json"
cp "$SCRIPT_DIR/core/.claudeignore" "$TARGET_DIR/.claudeignore"
cp "$SCRIPT_DIR/core/.mcp.json" "$TARGET_DIR/.mcp.json"
cp "$SCRIPT_DIR/core/lessons.md" "$TARGET_DIR/.claude/lessons.md"
cp "$SCRIPT_DIR/core/deploy-history.md" "$TARGET_DIR/.claude/deploy-history.md"
echo -e "  ${GREEN}+${NC} Core config files"

# Copy hooks
if [ -d "$SCRIPT_DIR/core/hooks" ]; then
  cp "$SCRIPT_DIR/core/hooks/"*.sh "$TARGET_DIR/.claude/hooks/" 2>/dev/null || true
  chmod +x "$TARGET_DIR/.claude/hooks/"*.sh 2>/dev/null || true
fi
echo -e "  ${GREEN}+${NC} Session memory hooks (start, end, deploy, compact)"

# Copy core rules
if [ -d "$SCRIPT_DIR/core/rules" ]; then
  cp "$SCRIPT_DIR/core/rules/"*.md "$TARGET_DIR/.claude/rules/" 2>/dev/null || true
fi
echo -e "  ${GREEN}+${NC} Core rules (self-improvement, tool-creation, monitoring)"

# Copy presets
if [ "$PRESET_INPUT" != "none" ]; then
  if [[ "$PRESET_INPUT" == *"a"* ]] || [[ "$PRESET_INPUT" == *"all"* ]]; then
    PRESETS="firebase nextjs vitest gcloud security"
  else
    PRESETS=""
    [[ "$PRESET_INPUT" == *"1"* ]] || [[ "$PRESET_INPUT" == *"firebase"* ]] && PRESETS="$PRESETS firebase"
    [[ "$PRESET_INPUT" == *"2"* ]] || [[ "$PRESET_INPUT" == *"nextjs"* ]] && PRESETS="$PRESETS nextjs"
    [[ "$PRESET_INPUT" == *"3"* ]] || [[ "$PRESET_INPUT" == *"vitest"* ]] && PRESETS="$PRESETS vitest"
    [[ "$PRESET_INPUT" == *"4"* ]] || [[ "$PRESET_INPUT" == *"gcloud"* ]] && PRESETS="$PRESETS gcloud"
    [[ "$PRESET_INPUT" == *"5"* ]] || [[ "$PRESET_INPUT" == *"security"* ]] && PRESETS="$PRESETS security"
  fi

  for preset in $PRESETS; do
    PRESET_DIR="$SCRIPT_DIR/presets/$preset"
    if [ -d "$PRESET_DIR" ]; then
      cp "$PRESET_DIR/"*.md "$TARGET_DIR/.claude/rules/" 2>/dev/null || true
      echo -e "  ${GREEN}+${NC} Preset: $preset"
    fi
  done
fi

# Copy agents
if [[ "$INSTALL_AGENTS" =~ ^[Yy] ]]; then
  mkdir -p "$TARGET_DIR/.claude/agents"
  if [ -d "$SCRIPT_DIR/agents" ]; then
    cp "$SCRIPT_DIR/agents/"*.md "$TARGET_DIR/.claude/agents/" 2>/dev/null || true
  fi
  echo -e "  ${GREEN}+${NC} Agents: code-reviewer, security-reviewer"
fi

# Replace placeholders
if [ -n "$PROJECT_NAME" ]; then
  find "$TARGET_DIR/.claude" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null | while read f; do
    sed -i.bak "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" "$f" 2>/dev/null || true
    rm -f "${f}.bak"
  done
fi

if [ -n "$PROJECT_URL" ]; then
  find "$TARGET_DIR/.claude" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null | while read f; do
    sed -i.bak "s|{{PROJECT_URL}}|$PROJECT_URL|g" "$f" 2>/dev/null || true
    rm -f "${f}.bak"
  done
fi

if [ -n "$PROJECT_ID" ]; then
  find "$TARGET_DIR/.claude" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null | while read f; do
    sed -i.bak "s|{{PROJECT_ID}}|$PROJECT_ID|g" "$f" 2>/dev/null || true
    rm -f "${f}.bak"
  done
fi

# Add to .gitignore if exists
GITIGNORE="$TARGET_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if ! grep -q '.claude/session-logs/' "$GITIGNORE" 2>/dev/null; then
    echo "" >> "$GITIGNORE"
    echo "# Claude Code AGI session logs (local only)" >> "$GITIGNORE"
    echo ".claude/session-logs/" >> "$GITIGNORE"
    echo -e "  ${GREEN}+${NC} Added session-logs to .gitignore"
  fi
else
  echo "" > "$GITIGNORE"
  echo "# Claude Code AGI session logs (local only)" >> "$GITIGNORE"
  echo ".claude/session-logs/" >> "$GITIGNORE"
  echo -e "  ${GREEN}+${NC} Created .gitignore with session-logs"
fi

echo ""
echo -e "${BOLD}${GREEN}Setup complete!${NC}"
echo ""
echo -e "Installed to: ${BOLD}$TARGET_DIR${NC}"
echo ""
echo -e "${BOLD}What was installed:${NC}"
echo "  .claude/CLAUDE.md          - Agent operating manual"
echo "  .claude/settings.json      - Auto mode + permissions + hooks"
echo "  .claude/hooks/             - Session memory + deploy tracking"
echo "  .claude/rules/             - Self-improvement + monitoring"
echo "  .claude/lessons.md         - Persistent knowledge base"
echo "  .claudeignore              - Context optimization"
echo "  .mcp.json                  - MCP server config"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. cd $TARGET_DIR"
echo "  2. Start Claude Code: claude"
echo "  3. Claude will start in auto mode with full context"
echo ""
echo -e "${YELLOW}Tip: Run '/context' to see how much context you're saving with .claudeignore${NC}"
