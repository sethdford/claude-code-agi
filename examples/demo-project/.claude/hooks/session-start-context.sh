#!/usr/bin/env bash
# Injects recent session summaries and production health into session context
set -euo pipefail

LOG_DIR=".claude/session-logs"
PROJECT_URL="https://example.com"

echo "=== PREVIOUS SESSION CONTEXT ==="

# Show last 3 session summaries
if [ -d "$LOG_DIR" ]; then
  for f in $(ls -t "$LOG_DIR"/*.md 2>/dev/null | head -3); do
    echo "--- $(basename "$f") ---"
    cat "$f"
    echo ""
  done
else
  echo "No previous sessions found."
fi

echo "=== OPEN PLANS ==="
# Check for incomplete plans
for plan in docs/plans/*.md 2>/dev/null || true; do
  if [ -f "$plan" ]; then
    unchecked=$(grep -c '^\s*- \[ \]' "$plan" 2>/dev/null || echo 0)
    if [ "$unchecked" -gt 0 ]; then
      echo "  $(basename "$plan"): $unchecked unchecked items"
    fi
  fi
done

echo "=== PRODUCTION HEALTH ==="
# Quick health check (non-blocking, 5s timeout)
curl -s --max-time 5 "$PROJECT_URL" -o /dev/null -w "Site: HTTP %{http_code} (%{time_total}s)" 2>/dev/null || echo "Site: unreachable"
echo ""
