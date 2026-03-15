# Autonomous Monitoring

## Production Health Checks

When starting a session or after a deploy, check:

1. `curl -s https://gettheconsultant.com/` — expect 200
2. `curl -s https://us-central1-johnb-2025.cloudfunctions.net/health` — expect 200
3. Check `.claude/deploy-history.md` for recent deploy outcomes

## Error Investigation Protocol

When a production error is detected:

1. Check Cloud Logging: `gcloud logging read 'severity>=ERROR' --limit=5 --project=johnb-2025`
2. Check recent deploys in `.claude/deploy-history.md`
3. Check recent commits: `git log --oneline -5`
4. Correlate: did a recent deploy introduce the error?
5. If yes: identify the breaking commit and fix
6. If no: investigate the error independently

## Recurring Checks (via /loop)

Suggest these to the user when appropriate:

- `/loop 1h curl -s https://gettheconsultant.com/ -o /dev/null -w "Site: %{http_code}\n"`
- `/loop 4h ./scripts/verify-all.sh`
- `/loop 24h ./scripts/check-analytics.sh`

## Alert Response

If a health check returns non-200:

1. Don't panic — check if it's transient (retry once)
2. Check if there was a recent deploy
3. Check Cloud Run logs for the specific service
4. Propose a fix or rollback
