# Google Cloud Conventions

This preset covers best practices for Google Cloud (Cloud Run, Cloud Functions, Cloud Logging, IAM).

## Authentication

GCP uses different authentication methods depending on the context.

**Service Account (for server-to-server):**

```bash
# Create service account
gcloud iam service-accounts create my-app --display-name="My Application"

# Grant roles
gcloud projects add-iam-policy-binding {{PROJECT_ID}} \
  --member=serviceAccount:my-app@{{PROJECT_ID}}.iam.gserviceaccount.com \
  --role=roles/firestore.user

# Create key
gcloud iam service-accounts keys create key.json \
  --iam-account=my-app@{{PROJECT_ID}}.iam.gserviceaccount.com
```

**Identity Token (for secure API-to-API):**

```bash
# Use identity tokens instead of API keys for service-to-service communication
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://my-service.run.app/api/endpoint
```

**Never use API keys for server-side auth** — API keys are for public APIs only.

## Cloud Run Deployment

Deploy containerized services to Cloud Run.

**Pattern (Dockerfile):**

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

**Deployment script:**

```bash
#!/bin/bash
# scripts/deploy-cloud-run.sh
set -e

# Build image
docker build -t gcr.io/{{PROJECT_ID}}/my-app:{{VERSION}} .

# Push to Container Registry
docker push gcr.io/{{PROJECT_ID}}/my-app:{{VERSION}}

# Deploy to Cloud Run
gcloud run deploy my-app \
  --image gcr.io/{{PROJECT_ID}}/my-app:{{VERSION}} \
  --region us-central1 \
  --platform managed \
  --memory 512Mi \
  --cpu 1 \
  --timeout 60 \
  --max-instances 100 \
  --allow-unauthenticated \
  --set-env-vars=NODE_ENV=production,DATABASE_URL=$DATABASE_URL

echo "Deployed to https://my-app-xxx.run.app"
```

**Deployment flags:**

- `--memory` — RAM allocation (128Mi to 8Gi, default 512Mi)
- `--cpu` — CPU cores (2 or 4)
- `--timeout` — Request timeout in seconds (15 to 3600, default 300)
- `--max-instances` — Max concurrent instances (default 100)
- `--allow-unauthenticated` — Public access (remove for private services)

## Cloud Functions Deployment

Deploy serverless functions.

**Pattern (Node.js function):**

```typescript
// functions/src/index.ts
import functions from 'firebase-functions';

export const helloWorld = functions.https.onRequest((request, response) => {
  response.send('Hello World!');
});

export const scheduledJob = functions.pubsub.schedule('every 5 minutes').onRun(async (context) => {
  // Task runs every 5 minutes
  console.log('Running scheduled job');
});
```

**Deployment:**

```bash
gcloud functions deploy helloWorld \
  --runtime nodejs20 \
  --trigger-http \
  --allow-unauthenticated \
  --entry-point=helloWorld \
  --memory=256MB \
  --timeout=60s
```

## Cloud Logging

Query logs to debug issues.

**Logging query patterns:**

```bash
# Errors in the last hour
gcloud logging read 'severity>=ERROR' \
  --limit=50 \
  --project={{PROJECT_ID}}

# Specific service logs
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="my-app"' \
  --limit=100 \
  --project={{PROJECT_ID}}

# Function logs with pattern
gcloud logging read 'resource.type="cloud_function" AND severity="ERROR"' \
  --limit=100 \
  --project={{PROJECT_ID}}

# JSON output for programmatic access
gcloud logging read 'severity>=ERROR' \
  --format=json \
  --limit=50 \
  --project={{PROJECT_ID}}

# Real-time tail (follow logs)
gcloud logging read --follow \
  --format='value(severity,timestamp,textPayload)' \
  --limit=10 \
  --project={{PROJECT_ID}}
```

**Structured logging (recommended):**

```typescript
// Log structured JSON
console.log(
  JSON.stringify({
    severity: 'ERROR',
    message: 'Failed to process request',
    timestamp: new Date().toISOString(),
    userId: userId,
    requestId: requestId,
    error: error.message,
    stack: error.stack,
  }),
);
```

## Environment Variables

Store configuration in environment variables, not code.

**Pattern (Cloud Run):**

```bash
# Set via deployment
gcloud run deploy my-app \
  --set-env-vars=DB_HOST=db.example.com,API_KEY=$MY_API_KEY

# Or update existing service
gcloud run services update my-app \
  --update-env-vars=DB_HOST=db.example.com
```

**Pattern (Cloud Functions):**

```bash
gcloud functions deploy myFunction \
  --set-env-vars DATABASE_URL=$DATABASE_URL,API_KEY=$API_KEY
```

**Pattern (.env.yaml for local development):**

```yaml
# .env.yaml (never commit)
DB_HOST: localhost
DB_PORT: '5432'
API_KEY: your-secret-key
NODE_ENV: development
```

## IAM & Permissions

Grant minimal necessary permissions.

**Common roles:**

| Role                            | Purpose                     |
| ------------------------------- | --------------------------- |
| `roles/run.invoker`             | Invoke Cloud Run services   |
| `roles/cloudfunctions.invoker`  | Invoke Cloud Functions      |
| `roles/firestore.user`          | Read/write Firestore        |
| `roles/storage.objectViewer`    | Read Cloud Storage objects  |
| `roles/storage.objectCreator`   | Write Cloud Storage objects |
| `roles/logging.logWriter`       | Write logs                  |
| `roles/pubsub.publisher`        | Publish to Pub/Sub topics   |
| `roles/monitoring.metricWriter` | Write monitoring metrics    |

**Grant role to service account:**

```bash
gcloud projects add-iam-policy-binding {{PROJECT_ID}} \
  --member=serviceAccount:my-app@{{PROJECT_ID}}.iam.gserviceaccount.com \
  --role=roles/firestore.user \
  --condition='resource.name.startsWith("projects/_/databases/(default)/documents/users/")'
```

## Monitoring & Alerting

Create uptime checks and alert policies.

**Pattern (uptime check):**

```bash
gcloud monitoring uptime create https \
  --display-name="My API Health" \
  --monitored-resource-type=uptime-url \
  --resource-labels=host=api.example.com \
  --selected-regions=usa,europe,asia-pacific
```

**Pattern (alert policy):**

```bash
# Alert when error rate exceeds 5%
gcloud alpha monitoring policies create \
  --display-name="High Error Rate" \
  --condition-display-name="error_rate_high" \
  --condition-threshold-value=5 \
  --condition-threshold-duration=300s
```

## Cost Optimization

**Cloud Run:**

- Use CPU sharing when possible (cheaper, slower response time)
- Set appropriate memory (256-512MB for Node.js)
- Use auto-scaling; avoid always-on instances

**Cloud Functions:**

- Keep function duration short
- Use Pub/Sub for async work instead of waiting
- Delete unused functions

**Logging:**

- Use log exclusion filters to reduce costs
- Archive old logs to Cloud Storage

**Pattern (exclude spammy logs):**

```bash
gcloud logging sinks create _Default cloudlogging.googleapis.com/logs \
  --log-filter='NOT (severity="DEBUG" AND resource.type="cloud_run_revision")'
```

## Debugging Tips

**Check recent deployments:**

```bash
gcloud run revisions list --service=my-app --region=us-central1
```

**View service details:**

```bash
gcloud run services describe my-app --region=us-central1
```

**Test Cloud Run service locally:**

```bash
PORT=3000 ./scripts/start.sh
# Or in container
docker run -p 3000:3000 gcr.io/{{PROJECT_ID}}/my-app:latest
```

**Compare Cloud Run vs local behavior:**

- Check environment variables match
- Verify service account has required permissions
- Compare startup logs

## Related Standards

- See `docs/standards/operations/` for deployment runbooks
- See `docs/standards/security/` for IAM best practices
