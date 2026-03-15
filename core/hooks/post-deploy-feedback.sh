#!/usr/bin/env bash
# Records deploy outcomes for cross-session learning
set -euo pipefail

FEEDBACK_FILE="/Users/sethford/Documents/aim/.claude/deploy-history.md"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT=$(cd /Users/sethford/Documents/aim && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Quick smoke test
SITE_STATUS=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" https://gettheconsultant.com/ 2>/dev/null || echo "000")
FUNC_STATUS=$(curl -s --max-time 10 -o /dev/null -w "%{http_code}" https://us-central1-johnb-2025.cloudfunctions.net/health 2>/dev/null || echo "000")

cat >> "$FEEDBACK_FILE" << EOF

## Deploy ${TIMESTAMP} (${COMMIT})
- Site: HTTP ${SITE_STATUS}
- Functions: HTTP ${FUNC_STATUS}
- Result: $([ "$SITE_STATUS" = "200" ] && [ "$FUNC_STATUS" = "200" ] && echo "SUCCESS" || echo "ISSUES DETECTED")
EOF

echo "Deploy feedback recorded"
