# Vitest Testing Conventions

This preset covers best practices for unit and integration testing with Vitest.

## Framework Choice

Use Vitest for all tests. Never use Jest.

**Why Vitest:**

- Faster startup and execution
- Native ESM support
- Better TypeScript integration
- Simpler configuration

## Test Structure

Organize tests alongside source code in `__tests__` directories or with `.test.ts` suffix.

**Pattern:**

```
src/
├── lib/
│   ├── api.ts
│   └── __tests__/
│       └── api.test.ts
├── components/
│   ├── Button.tsx
│   └── __tests__/
│       └── Button.test.tsx
└── __tests__/
    └── integration/
        └── user-flow.test.ts
```

## Test Setup

**Pattern (vitest.config.ts):**

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./vitest.setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
      exclude: ['node_modules/', 'dist/', 'coverage/'],
    },
  },
});
```

**Pattern (vitest.setup.ts):**

```typescript
import { vi } from 'vitest';

// Global test setup
global.fetch = vi.fn();

// Mock environment variables
process.env.API_URL = 'http://localhost:3000';
```

## Assertion Patterns

Use consistent assertion patterns. Vitest provides built-in matchers.

**Pattern (basic assertions):**

```typescript
describe('math operations', () => {
  it('adds numbers', () => {
    expect(2 + 2).toBe(4);
  });

  it('validates string', () => {
    expect('hello').toMatch(/hello/);
    expect('hello').toHaveLength(5);
  });

  it('checks arrays', () => {
    expect([1, 2, 3]).toContain(2);
    expect([1, 2, 3]).toHaveLength(3);
  });

  it('validates objects', () => {
    const user = { name: 'Alice', email: 'alice@example.com' };
    expect(user).toEqual({ name: 'Alice', email: 'alice@example.com' });
    expect(user).toHaveProperty('name');
  });

  it('throws errors', () => {
    expect(() => {
      throw new Error('Oops');
    }).toThrow('Oops');
  });
});
```

## Mocking

Use `vi.fn()`, `vi.mock()`, and `vi.spyOn()` for mocking.

**Pattern (function mocks):**

```typescript
import { vi, describe, it, expect } from 'vitest';
import { fetchUser } from './api';

vi.mock('./api', () => ({
  fetchUser: vi.fn(),
}));

describe('user service', () => {
  it('fetches user', async () => {
    const mockUser = { id: 1, name: 'Alice' };
    vi.mocked(fetchUser).mockResolvedValue(mockUser);

    const result = await fetchUser(1);

    expect(vi.mocked(fetchUser)).toHaveBeenCalledWith(1);
    expect(result).toEqual(mockUser);
  });
});
```

**Pattern (module mocks):**

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('firebase-admin/firestore');
vi.mock('firebase-admin/app');

import admin from 'firebase-admin';

describe('database', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('gets document', async () => {
    const mockDoc = { data: () => ({ name: 'Alice' }) };
    vi.mocked(admin.firestore().collection).mockReturnValue({
      doc: vi.fn().mockReturnValue(mockDoc),
    } as any);

    const result = await admin.firestore().collection('users').doc('1').get();

    expect(result.data()).toEqual({ name: 'Alice' });
  });
});
```

**Pattern (spying on functions):**

```typescript
import { vi, describe, it, expect } from 'vitest';
import * as logger from './logger';

describe('logging', () => {
  it('logs messages', () => {
    const spy = vi.spyOn(logger, 'log');

    logger.log('test');

    expect(spy).toHaveBeenCalledWith('test');
    spy.mockRestore();
  });
});
```

## Web Component Testing

Test React/Vue/Svelte components with Vitest.

**Pattern (React component):**

```typescript
import { render, screen } from '@testing-library/react';
import { vi, describe, it, expect } from 'vitest';
import Button from './Button';

describe('Button', () => {
  it('renders button', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toHaveTextContent('Click me');
  });

  it('calls onClick handler', async () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Click</Button>);

    await screen.getByRole('button').click();

    expect(onClick).toHaveBeenCalled();
  });

  it('disables button', () => {
    render(<Button disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
});
```

## Async Testing

Handle async code with `async/await` or return promises.

**Pattern:**

```typescript
import { describe, it, expect } from 'vitest';

describe('async operations', () => {
  it('waits for promise', async () => {
    const result = await new Promise((resolve) => {
      setTimeout(() => resolve('done'), 10);
    });

    expect(result).toBe('done');
  });

  it('handles promise rejection', async () => {
    await expect(Promise.reject(new Error('Oops'))).rejects.toThrow('Oops');
  });

  it('timeout test', async () => {
    const result = await new Promise((resolve) => {
      setTimeout(() => resolve('done'), 100);
    });

    expect(result).toBe('done');
  }, 500); // 500ms timeout
});
```

## API Route Testing

Test Next.js API routes with mocked dependencies.

**Pattern:**

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { GET, POST } from '@/app/api/items/route';
import { NextRequest } from 'next/server';

vi.mock('@/lib/db');
vi.mock('@/lib/rate-limit');

describe('GET /api/items', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns items', async () => {
    vi.mocked(rateLimit).mockResolvedValue(false);
    vi.mocked(db.items.list).mockResolvedValue([{ id: 1, name: 'Item 1' }]);

    const request = new NextRequest('http://localhost/api/items');
    const response = await GET(request);
    const json = await response.json();

    expect(response.status).toBe(200);
    expect(json).toEqual([{ id: 1, name: 'Item 1' }]);
  });

  it('returns 429 when rate limited', async () => {
    vi.mocked(rateLimit).mockResolvedValue(true);

    const request = new NextRequest('http://localhost/api/items');
    const response = await GET(request);

    expect(response.status).toBe(429);
  });

  it('returns 500 on error', async () => {
    vi.mocked(rateLimit).mockResolvedValue(false);
    vi.mocked(db.items.list).mockRejectedValue(new Error('DB error'));

    const request = new NextRequest('http://localhost/api/items');
    const response = await GET(request);

    expect(response.status).toBe(500);
  });
});

describe('POST /api/items', () => {
  it('creates item', async () => {
    vi.mocked(rateLimit).mockResolvedValue(false);
    vi.mocked(db.items.create).mockResolvedValue({
      id: 1,
      name: 'New Item',
    });

    const request = new NextRequest('http://localhost/api/items', {
      method: 'POST',
      body: JSON.stringify({ name: 'New Item' }),
    });

    const response = await POST(request);
    const json = await response.json();

    expect(response.status).toBe(201);
    expect(json).toEqual({ id: 1, name: 'New Item' });
  });

  it('returns 400 for invalid JSON', async () => {
    const request = new NextRequest('http://localhost/api/items', {
      method: 'POST',
      body: 'invalid json',
    });

    const response = await POST(request);

    expect(response.status).toBe(400);
  });
});
```

## Firebase Testing

Mock Firebase Admin SDK and Cloud Functions.

**Pattern (Cloud Functions):**

```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { onRequest } from 'firebase-functions/v2/https';

vi.mock('firebase-functions/v2/https', () => ({
  onRequest: vi.fn((_opts, handler) => handler),
}));

vi.mock('firebase-admin/firestore');
vi.mock('firebase-admin/app');

import admin from 'firebase-admin';
import { myFunction } from './my-function';

describe('myFunction', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('handles request', async () => {
    const mockDb = {
      collection: vi.fn().mockReturnValue({
        add: vi.fn().mockResolvedValue({ id: '123' }),
      }),
    };

    vi.mocked(admin.firestore).mockReturnValue(mockDb as any);

    const req = {
      body: { name: 'Test' },
      headers: { authorization: 'Bearer token' },
    };
    const res = {
      json: vi.fn(),
    };

    await myFunction(req as any, res as any);

    expect(res.json).toHaveBeenCalledWith({ id: '123' });
  });
});
```

## Coverage Requirements

Enforce minimum coverage thresholds:

- **Lines:** 80%
- **Functions:** 80%
- **Branches:** 75%
- **Statements:** 80%

**Pattern (vitest.config.ts):**

```typescript
export default defineConfig({
  test: {
    coverage: {
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
    },
  },
});
```

Run coverage report:

```bash
vitest --coverage
```

**Ignoring coverage for specific lines:**

```typescript
// vitest-ignore-next-line
const shouldNotBeTested = 1;

// Or
/* @vitest-ignore */
const anotherVar = 2;
```

## Common Mistakes

1. **Not clearing mocks between tests** — Always call `vi.clearAllMocks()` in `beforeEach`
2. **Mocking too broadly** — Mock only what's necessary; test real implementations where possible
3. **Forgetting async/await** — Mark test functions as `async` when testing async code
4. **Hardcoding test data** — Use factories or fixtures instead
5. **Testing implementation details** — Test behavior, not how functions work internally
6. **Flaky timeouts** — Never increase timeouts to fix flaky tests; find and fix the root cause

## Best Practices

1. **Test one thing per test** — Keep tests focused and isolated
2. **Use descriptive names** — Test names should explain what's being tested
3. **Arrange-Act-Assert pattern** — Organize tests into setup, action, verification
4. **DRY up test setup** — Use `beforeEach` and helper functions
5. **Mock external dependencies** — Database, APIs, timers, file systems
6. **Test error cases** — Don't just test the happy path

## Related Standards

- See `docs/standards/engineering/testing` for detailed testing strategies
- See `docs/standards/quality/` for code review and quality criteria
