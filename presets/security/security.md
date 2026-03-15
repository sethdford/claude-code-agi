# Security Conventions

This preset covers security best practices: rate limiting, authentication, input validation, secrets management, and API security.

## Rate Limiting

All API endpoints must be rate limited. Use industry-standard limits based on endpoint type.

**Rate limit guidelines:**

- **GET endpoints:** 30 requests per 60 seconds
- **POST endpoints:** 5-10 requests per 60 seconds
- **Webhooks:** 60 requests per 60 seconds
- **Report/AI operations:** 3-5 requests per hour
- **Authentication endpoints:** 5-10 per hour (prevent brute force)

**Pattern (implementation):**

```typescript
// lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

export async function rateLimit(
  request: Request,
  options: { maxRequests: number; windowMs: number },
) {
  const ip = request.headers.get('x-forwarded-for') || 'unknown';
  const key = `${ip}:${new URL(request.url).pathname}`;

  try {
    const { success } = await redis.incr(key);
    await redis.expire(key, Math.ceil(options.windowMs / 1000));

    return !success || (await redis.get(key)) > options.maxRequests;
  } catch {
    // Fail open (allow request) if rate limit service is down
    return false;
  }
}
```

**Pattern (API route):**

```typescript
// app/api/items/route.ts
export async function GET(request: NextRequest) {
  const limited = await rateLimit(request, {
    maxRequests: 30,
    windowMs: 60000,
  });

  if (limited) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  // Handle request...
}
```

## Authentication

Never expose authentication details. Enforce auth on protected routes.

**Pattern (portal/admin routes):**

```typescript
// middleware.ts
export async function middleware(request: NextRequest) {
  // Check for authorization header
  const auth = request.headers.get('authorization');
  if (!auth?.startsWith('Bearer ')) {
    return NextResponse.json({ error: 'Missing authorization' }, { status: 401 });
  }

  // Verify token
  const token = auth.split(' ')[1];
  const decoded = await verifyIdToken(token);
  if (!decoded) {
    return NextResponse.json({ error: 'Invalid token' }, { status: 403 });
  }

  // Continue request
  return NextResponse.next();
}

export const config = {
  matcher: ['/api/admin/:path*', '/api/portal/:path*'],
};
```

**Pattern (public routes with auth optional):**

```typescript
export async function GET(request: NextRequest) {
  // Extract auth if present
  const auth = request.headers.get('authorization')?.split(' ')[1];
  let userId: string | undefined;

  if (auth) {
    const decoded = await verifyIdToken(auth);
    userId = decoded?.uid;
  }

  // Fetch data (optionally scoped to user)
  const items = userId ? await db.items.getByUserId(userId) : await db.items.getPublic();

  return NextResponse.json(items);
}
```

## Input Validation

Always validate and sanitize user input. Never trust client-provided data.

**Pattern (JSON parsing):**

```typescript
// ❌ DON'T: Unsafe parsing
const body = await request.json();

// ✅ DO: Safe parsing with error handling
let body;
try {
  body = await request.json();
} catch {
  return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
}
```

**Pattern (schema validation):**

```typescript
import { z } from 'zod';

const CreateItemSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
  tags: z.array(z.string()).max(10),
});

export async function POST(request: NextRequest) {
  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }

  const validation = CreateItemSchema.safeParse(body);
  if (!validation.success) {
    return NextResponse.json(
      { error: 'Validation failed', details: validation.error.errors },
      { status: 400 },
    );
  }

  // Use validated data
  const item = await db.items.create(validation.data);
  return NextResponse.json(item, { status: 201 });
}
```

**Pattern (URL parameter validation):**

```typescript
export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params;

  // Validate ID format
  if (!/^\d+$/.test(id)) {
    return NextResponse.json({ error: 'Invalid ID' }, { status: 400 });
  }

  const item = await db.items.get(parseInt(id));
  if (!item) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 });
  }

  return NextResponse.json(item);
}
```

## Data Protection

**Never expose sensitive data:**

- Never log passwords, tokens, API keys
- Don't expose database errors to clients
- Never echo user input directly
- Mask PII in logs and error messages

**Pattern (safe error handling):**

```typescript
try {
  const result = await operation();
  return NextResponse.json(result);
} catch (error) {
  // ❌ DON'T: Log entire error with stack
  // console.error(error);

  // ✅ DO: Log safely with context
  console.error({
    timestamp: new Date().toISOString(),
    operation: 'myOperation',
    userId: request.headers.get('x-user-id'),
    message: error instanceof Error ? error.message : 'Unknown error',
    // Never log the stack or raw error
  });

  // Return generic error to client
  return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
}
```

## Secrets Management

**Rules:**

- Never commit `.env` files with real secrets
- Use `.env.example` to document required vars
- Store secrets in environment variables or a secrets manager
- Rotate secrets regularly
- Never echo tokens starting with `sk-` or `sk_`

**Pattern (.env.example):**

```
# Public (safe to commit)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXXXX

# Secret (never commit)
DATABASE_URL=postgresql://...
API_SECRET=your-secret-key
STRIPE_SECRET_KEY=sk_...
```

**Pattern (runtime validation):**

```typescript
// lib/env.ts
import { z } from 'zod';

const EnvSchema = z.object({
  DATABASE_URL: z.string().url(),
  API_SECRET: z.string().min(32),
  NODE_ENV: z.enum(['development', 'production']),
});

const env = EnvSchema.parse(process.env);
export default env;
```

## CORS & Same-Origin Policy

Configure CORS carefully to prevent unauthorized access.

**Pattern:**

```typescript
// app/api/route.ts
export async function GET(request: NextRequest) {
  const origin = request.headers.get('origin');
  const allowedOrigins = ['https://example.com', 'https://app.example.com'];

  if (!allowedOrigins.includes(origin || '')) {
    return NextResponse.json({ error: 'CORS not allowed' }, { status: 403 });
  }

  const response = NextResponse.json({ data: 'ok' });
  response.headers.set('Access-Control-Allow-Origin', origin);
  response.headers.set('Access-Control-Allow-Credentials', 'true');
  return response;
}
```

## Webhook Security

Verify webhook signatures to prevent request spoofing.

**Pattern (Stripe):**

```typescript
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);

export async function POST(request: NextRequest) {
  const signature = request.headers.get('stripe-signature');
  const body = await request.text();

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, process.env.STRIPE_WEBHOOK_SECRET);
  } catch {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 403 });
  }

  // Handle event
  if (event.type === 'payment_intent.succeeded') {
    const intent = event.data.object as Stripe.PaymentIntent;
    // Process payment...
  }

  return NextResponse.json({ received: true });
}
```

**Pattern (generic HMAC verification):**

```typescript
import crypto from 'crypto';

export async function POST(request: NextRequest) {
  const signature = request.headers.get('x-signature');
  const body = await request.text();

  // Compute HMAC
  const computed = crypto
    .createHmac('sha256', process.env.WEBHOOK_SECRET!)
    .update(body)
    .digest('hex');

  // Compare (timing-safe)
  if (!crypto.timingSafeEqual(signature!, computed)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 403 });
  }

  // Process webhook...
  return NextResponse.json({ ok: true });
}
```

## SQL Injection Prevention

Use parameterized queries. Never concatenate user input into SQL.

**Pattern (unsafe - DON'T DO THIS):**

```typescript
// ❌ NEVER do this
const result = await db.query(`SELECT * FROM users WHERE id = ${userId}`);
```

**Pattern (safe - use parameterized queries):**

```typescript
// ✅ DO this
const result = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// Or with an ORM
const user = await db.user.findUnique({
  where: { id: userId },
});
```

## XSS Prevention

Sanitize user-generated content before displaying.

**Pattern:**

```typescript
import DOMPurify from 'isomorphic-dompurify';

export async function POST(request: NextRequest) {
  const { content } = await request.json();

  // Sanitize HTML
  const clean = DOMPurify.sanitize(content, {
    ALLOWED_TAGS: ['p', 'br', 'strong', 'em', 'a'],
    ALLOWED_ATTR: { a: ['href', 'title'] },
  });

  // Store sanitized content
  await db.posts.create({ content: clean });
  return NextResponse.json({ ok: true });
}
```

## Content Security Policy

Set CSP headers to mitigate XSS and injection attacks.

**Pattern (middleware.ts):**

```typescript
export async function middleware(request: NextRequest) {
  const response = NextResponse.next();

  response.headers.set(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
  );

  response.headers.set('X-Content-Type-Options', 'nosniff');

  response.headers.set('X-Frame-Options', 'DENY');

  return response;
}
```

## Security Checklist

Before deploying, verify:

- [ ] All endpoints are rate limited
- [ ] Authentication is enforced on protected routes
- [ ] All user input is validated with a schema
- [ ] No secrets committed to code
- [ ] Error messages don't leak implementation details
- [ ] Webhook signatures are verified
- [ ] SQL queries are parameterized
- [ ] User-generated content is sanitized
- [ ] CORS is configured (if applicable)
- [ ] CSP headers are set
- [ ] Dependencies have no known vulnerabilities (`npm audit`)
- [ ] HTTPS is enforced (in production)

## Related Standards

- See `docs/standards/operations/` for security incident response
- See `docs/standards/compliance/` for data protection and privacy
