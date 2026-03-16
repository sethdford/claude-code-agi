# Docker Conventions

This preset covers best practices for Docker builds with security, performance, and production readiness.

## Multi-Stage Builds

Always use multi-stage builds to reduce final image size.

**Pattern (Node.js):**

```dockerfile
# Stage 1: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./
USER nodejs
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

**Pattern (Python):**

```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends build-essential
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
RUN useradd -m -u 1001 appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .
USER appuser
ENV PATH=/home/appuser/.local/bin:$PATH
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app:app", "--host", "0.0.0.0"]
```

**Pattern (Go):**

```dockerfile
# Stage 1: Build
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app .

# Stage 2: Runtime
FROM alpine:latest
WORKDIR /app
RUN addgroup -g 1001 -S appgroup && adduser -u 1001 -S appuser -G appgroup
COPY --from=builder /app/app .
USER appuser
EXPOSE 8080
CMD ["./app"]
```

Multi-stage builds can reduce image size by 90%. Never skip this step.

## Layer Caching Optimization

Order Dockerfile commands to maximize cache hits. Put stable commands first.

**Pattern:**

```dockerfile
FROM node:20-alpine

# Copy package files first (changes less frequently)
COPY package*.json ./

# Install dependencies (cached if package.json hasn't changed)
RUN npm ci --only=production

# Copy source code (changes frequently)
COPY . .

# Build (only if source changed)
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
```

Good layer ordering:
1. Base image
2. System dependencies (rarely change)
3. Package managers / build tools
4. Application dependencies (package.json, requirements.txt)
5. Source code (changes often)
6. Build / compile steps
7. Entry point / CMD

## Security Best Practices

**Always use non-root user:**

```dockerfile
RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appgroup
USER appuser
```

**Use minimal base images:**

- Prefer `-alpine` variants (Node, Python, Go)
- Or use distroless images: `gcr.io/distroless/base`

**Pattern (distroless):**

```dockerfile
FROM golang:1.21-alpine AS builder
COPY . .
RUN go build -o app .

FROM gcr.io/distroless/base:nonroot
COPY --from=builder /app /
EXPOSE 8080
CMD ["/app"]
```

**Scan for vulnerabilities:**

```bash
docker build -t myapp .
docker scan myapp                    # Requires Docker Desktop with Snyk
# Or use Trivy:
trivy image myapp
```

## .dockerignore

Reduce build context size by ignoring unnecessary files.

**Pattern (.dockerignore):**

```
node_modules
npm-debug.log
.git
.gitignore
.env
.env.local
.DS_Store
dist
build
coverage
.next
.venv
__pycache__
*.pyc
.pytest_cache
```

This reduces build context and speeds up builds significantly.

## Health Checks

Always define health checks for production containers.

**Pattern (Node.js):**

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm ci --only=production

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => r.statusCode === 200 || process.exit(1))"

EXPOSE 3000
CMD ["npm", "start"]
```

**Pattern (Python):**

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

EXPOSE 8000
CMD ["uvicorn", "app:app", "--host", "0.0.0.0"]
```

Health checks enable orchestrators to restart failed containers automatically.

## Docker Compose

Use `docker-compose.yml` for local development and testing.

**Pattern:**

```yaml
version: '3.9'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: development
      DATABASE_URL: postgresql://user:pass@db:5432/mydb
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  db_data:
```

**Run with:**

```bash
docker-compose up -d         # Start in background
docker-compose logs -f app   # Follow logs
docker-compose down          # Stop and remove
```

## Image Size Optimization

**Before optimization:**
```bash
$ docker images myapp
REPOSITORY   TAG       IMAGE ID     SIZE
myapp        latest    abc123       850MB  # Too large!
```

**After optimization:**
```bash
$ docker images myapp
REPOSITORY   TAG       IMAGE ID     SIZE
myapp        latest    def456       45MB   # Multi-stage + alpine
```

Techniques:
- Use `-alpine` base images (40-80% smaller)
- Use distroless images (70-90% smaller)
- Use multi-stage builds to exclude build artifacts
- Clean up package manager caches: `RUN apt-get clean && rm -rf /var/lib/apt/lists/*`

## Common Mistakes

1. **Running as root** — Always use a non-root user
2. **Large base images** — Use alpine or distroless
3. **Copying entire directory** — Use .dockerignore to exclude unnecessary files
4. **Not using multi-stage builds** — Always separate build and runtime
5. **No health checks** — Define health checks for production
