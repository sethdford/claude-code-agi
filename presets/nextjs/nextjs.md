# Next.js 15 Conventions

This preset covers best practices for Next.js 15+ with App Router, API routes, and full-stack patterns.

## App Router Structure

Use the App Router (not Pages Router). Organize by feature/domain:

**Pattern:**

```
app/
├── layout.tsx              # Root layout
├── page.tsx                # Root page
├── (auth)/
│   ├── layout.tsx
│   ├── login/page.tsx
│   └── signup/page.tsx
├── (dashboard)/
│   ├── layout.tsx
│   ├── page.tsx
│   ├── settings/page.tsx
│   └── [id]/page.tsx
├── api/
│   ├── auth/route.ts
│   ├── items/route.ts
│   ├── items/[id]/route.ts
│   └── webhooks/stripe/route.ts
└── .well-known/
    └── robots.txt
```

**Why:** Grouped layouts (`(auth)`) let you share layouts without affecting URL. Dynamic routes (`[id]`) are explicit.

## Page Components

Use async server components by default. Only use `'use client'` when necessary (interactivity, hooks).

**Pattern (Server Component):**

```typescript
// app/items/page.tsx
import { getItems } from '@/lib/data';

export const metadata = {
  title: 'Items',
  description: 'Browse all items',
};

export default async function ItemsPage() {
  const items = await getItems();
  return <ItemsList items={items} />;
}
```

**Pattern (Client Component):**

```typescript
'use client';

import { useState } from 'react';

export default function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

**Key rules:**

- Server components are the default — data fetching, database access, env vars
- Use `'use client'` only for interactivity (forms, hooks, event listeners)
- Never fetch in client components — use API routes or server actions
- Server components can't use browser APIs (localStorage, window)

## API Routes

All API routes must:

1. Handle `Content-Type` validation
2. Wrap JSON parsing in try-catch
3. Enforce rate limiting
4. Return proper status codes
5. Log requests for debugging

**Pattern (GET):**

```typescript
// app/api/items/route.ts
import { rateLimit } from '@/lib/rate-limit';
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  // Rate limit
  const limited = await rateLimit(request, {
    maxRequests: 30,
    windowMs: 60000,
  });
  if (limited) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  try {
    const items = await db.items.list();
    return NextResponse.json(items);
  } catch (error) {
    console.error('GET /api/items failed:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
```

**Pattern (POST):**

```typescript
// app/api/items/route.ts
export async function POST(request: NextRequest) {
  // Rate limit
  const limited = await rateLimit(request, {
    maxRequests: 5,
    windowMs: 60000,
  });
  if (limited) {
    return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
  }

  // Parse body safely
  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  // Validate
  if (!body.name || !body.email) {
    return NextResponse.json({ error: 'Missing required fields: name, email' }, { status: 400 });
  }

  try {
    const item = await db.items.create(body);
    return NextResponse.json(item, { status: 201 });
  } catch (error) {
    console.error('POST /api/items failed:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
```

**Pattern (Dynamic route):**

```typescript
// app/api/items/[id]/route.ts
export async function GET(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params;

  // Validate ID format
  if (!/^\d+$/.test(id)) {
    return NextResponse.json({ error: 'Invalid ID' }, { status: 400 });
  }

  try {
    const item = await db.items.get(id);
    if (!item) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }
    return NextResponse.json(item);
  } catch (error) {
    console.error(`GET /api/items/${id} failed:`, error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function PATCH(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params;

  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON body' }, { status: 400 });
  }

  try {
    const item = await db.items.update(id, body);
    return NextResponse.json(item);
  } catch (error) {
    console.error(`PATCH /api/items/${id} failed:`, error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params;

  try {
    await db.items.delete(id);
    return new NextResponse(null, { status: 204 });
  } catch (error) {
    console.error(`DELETE /api/items/${id} failed:`, error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
```

## Middleware & Auth

Use middleware to enforce authentication and authorization.

**Pattern (middleware.ts):**

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';
import { verifyAuth } from '@/lib/auth';

const publicRoutes = ['/', '/about', '/api/contact'];
const protectedRoutes = ['/dashboard', '/settings', '/api/admin'];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Allow public routes
  if (publicRoutes.some((route) => pathname.startsWith(route))) {
    return NextResponse.next();
  }

  // Check protected routes
  if (protectedRoutes.some((route) => pathname.startsWith(route))) {
    const token = request.headers.get('authorization')?.split(' ')[1];
    const decoded = await verifyAuth(token);

    if (!decoded) {
      return NextResponse.redirect(new URL('/login', request.url));
    }

    // Attach user info to request
    const requestHeaders = new Headers(request.headers);
    requestHeaders.set('x-user-id', decoded.userId);
    return NextResponse.next({ request: { headers: requestHeaders } });
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next|static).*)'], // Match all except Next.js internals
};
```

**Pattern (accessing user in route):**

```typescript
// app/api/admin/stats/route.ts
import { headers } from 'next/headers';

export async function GET(request: NextRequest) {
  const headersList = await headers();
  const userId = headersList.get('x-user-id');

  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  // Now fetch user-specific data
  const stats = await db.stats.getByUserId(userId);
  return NextResponse.json(stats);
}
```

## Rate Limiting

**Pattern (in-memory with Redis fallback):**

```typescript
// lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

const ratelimit = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, '10s'),
});

export async function rateLimit(
  request: NextRequest,
  options: { maxRequests: number; windowMs: number },
) {
  const ip = request.ip ?? '127.0.0.1';
  const key = `${ip}:${request.nextUrl.pathname}`;

  const { success } = await ratelimit.limit(key);
  return !success; // true if rate limited
}
```

## Server Actions

Use Server Actions for mutations (form submissions, button clicks).

**Pattern:**

```typescript
// app/items/actions.ts
'use server';

import { db } from '@/lib/db';
import { revalidatePath } from 'next/cache';

export async function createItem(formData: FormData) {
  const name = formData.get('name') as string;
  const email = formData.get('email') as string;

  if (!name || !email) {
    return { error: 'Missing required fields' };
  }

  try {
    const item = await db.items.create({ name, email });
    revalidatePath('/items'); // Refresh the page
    return { success: true, item };
  } catch (error) {
    console.error('createItem failed:', error);
    return { error: 'Failed to create item' };
  }
}
```

**Pattern (in a form):**

```typescript
// app/items/new/page.tsx
import { createItem } from '@/app/items/actions';

export default function NewItemPage() {
  return (
    <form action={createItem}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit">Create</button>
    </form>
  );
}
```

## Data Fetching

Use `fetch` in server components. Always add cache and revalidation tags.

**Pattern:**

```typescript
// app/dashboard/page.tsx
async function getDashboard() {
  const res = await fetch('https://api.example.com/dashboard', {
    next: { revalidate: 60 }, // Revalidate every 60 seconds
  });

  if (!res.ok) throw new Error('Failed to fetch dashboard');
  return res.json();
}

export default async function DashboardPage() {
  const dashboard = await getDashboard();
  return <Dashboard data={dashboard} />;
}
```

**Pattern (with error boundary):**

```typescript
'use client';

import { Suspense } from 'react';

async function UserProfile({ userId }: { userId: string }) {
  const res = await fetch(`/api/users/${userId}`);
  if (!res.ok) throw new Error('Failed to fetch user');
  const user = await res.json();
  return <div>{user.name}</div>;
}

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <UserProfile userId="123" />
    </Suspense>
  );
}
```

## Environment Variables

**Rules:**

- `NEXT_PUBLIC_*` — exposed to browser
- Unprefixed variables — server-only, not exposed to client
- Use `.env.local` for secrets (never commit)
- Use `.env.example` for reference

**Pattern (.env.example):**

```
# Server-only
DATABASE_URL="postgresql://..."
API_SECRET="secret-key-here"

# Client-side
NEXT_PUBLIC_API_URL="https://api.example.com"
NEXT_PUBLIC_GA_ID="UA-1234567-1"
```

## Testing

API routes use Vitest with mocked dependencies.

**Pattern:**

```typescript
import { GET } from '@/app/api/items/route';
import { NextRequest } from 'next/server';

vi.mock('@/lib/db');

describe('GET /api/items', () => {
  it('returns items', async () => {
    const request = new NextRequest('http://localhost/api/items');
    const response = await GET(request);
    const json = await response.json();

    expect(response.status).toBe(200);
    expect(json).toEqual([]);
  });

  it('returns 429 when rate limited', async () => {
    // Mock rate limit
    vi.mock('@/lib/rate-limit', () => ({
      rateLimit: vi.fn(() => Promise.resolve(true)),
    }));

    const request = new NextRequest('http://localhost/api/items');
    const response = await GET(request);

    expect(response.status).toBe(429);
  });
});
```

## Common Mistakes

1. **Fetching in client components** — Always move fetches to server components or API routes
2. **Forgetting rate limits** — Every API route needs rate limiting
3. **Not validating JSON** — Always wrap `request.json()` in try-catch
4. **Hardcoding secrets** — Use environment variables, never literals
5. **Mixing auth patterns** — Pick one (middleware + headers OR Server Actions) and stick with it

## Related Standards

- See `docs/standards/security/` for auth patterns
- See `docs/standards/engineering/` for TypeScript conventions
