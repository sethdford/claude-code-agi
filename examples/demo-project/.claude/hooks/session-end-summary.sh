#!/usr/bin/env bash
# Writes a structured session summary for future sessions to read
set -euo pipefail

LOG_DIR=".claude/session-logs"
mkdir -p "$LOG_DIR"

# Read stdin (hook input JSON with session context)
INPUT=$(cat)

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FILENAME="${LOG_DIR}/$(date +%Y-%m-%d-%H%M%S).md"

cat > "$FILENAME" << EOF
---
timestamp: ${TIMESTAMP}
---

## Session Summary

Session ended at ${TIMESTAMP}.

### Git State
$(git log --oneline -5 2>/dev/null || echo "No git info")

### Recent Changes
$(git diff --stat HEAD~1 2>/dev/null | tail -5 || echo "No changes")
EOF

# Keep only last 10 session logs
ls -t "$LOG_DIR"/*.md 2>/dev/null | tail -n +11 | xargs rm -f 2>/dev/null || true

echo "Session summary saved to $FILENAME"
