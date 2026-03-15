#!/usr/bin/env bash
# Injects recent session summaries and production health into session context
set -euo pipefail

LOG_DIR="/Users/sethford/Documents/aim/.claude/session-logs"

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
for plan in /Users/sethford/Documents/aim/docs/plans/*.md; do
  if [ -f "$plan" ]; then
    unchecked=$(grep -c '^\s*- \[ \]' "$plan" 2>/dev/null || echo 0)
    if [ "$unchecked" -gt 0 ]; then
      echo "  $(basename "$plan"): $unchecked unchecked items"
    fi
  fi
done

echo "=== PRODUCTION HEALTH ==="
# Quick health check (non-blocking, 5s timeout)
curl -s --max-time 5 https://gettheconsultant.com/ -o /dev/null -w "Site: HTTP %{http_code} (%{time_total}s)" 2>/dev/null || echo "Site: unreachable"
echo ""
curl -s --max-time 5 https://us-central1-johnb-2025.cloudfunctions.net/health -o /dev/null -w "Functions: HTTP %{http_code}" 2>/dev/null || echo "Functions: unreachable"
echo ""
