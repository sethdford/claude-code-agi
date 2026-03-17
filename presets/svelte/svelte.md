# SvelteKit Preset

SvelteKit conventions for Claude Code agents building or maintaining SvelteKit applications.

## Project Structure

```
src/
├── routes/          # Page components and API routes
│   ├── +page.svelte # Root page
│   ├── +layout.svelte # Root layout
│   ├── [slug]/      # Dynamic route segment
│   └── api/         # API routes (+server.ts)
├── lib/             # Shared utilities, components, stores
│   ├── components/  # Reusable Svelte components
│   ├── stores/      # Svelte stores (writable, readable, derived)
│   ├── db.ts        # Database client
│   └── utils.ts     # Helper functions
├── app.html         # HTML shell
└── app.css          # Global styles

static/             # Static assets (images, fonts)
tests/              # Vitest tests
├── unit/
├── integration/
└── e2e/

svelte.config.js    # SvelteKit configuration
vite.config.ts      # Vite configuration
```

## Page Layout Pattern

### Page with Load Function

```svelte
<!-- src/routes/+page.svelte -->
<script lang="ts">
  import type { PageData } from './$types';

  export let data: PageData;
  let title: string = data.title;
</script>

<svelte:head>
  <title>{title}</title>
</svelte:head>

<main class="container">
  <h1>{title}</h1>
  <p>{data.description}</p>
</main>

<style>
  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }
</style>
```

### Server Load Function

```typescript
// src/routes/+page.server.ts
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ locals }) => {
  const posts = await locals.db.post.findMany();

  return {
    title: 'My Blog',
    description: 'Welcome to my blog',
    posts
  };
};
```

### Universal Load Function

```typescript
// src/routes/+page.ts
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ fetch }) => {
  const response = await fetch('/api/posts');
  const posts = await response.json();

  return {
    posts
  };
};
```

## Dynamic Routes

```
src/routes/
├── [slug]/
│   ├── +page.svelte
│   └── +page.server.ts    # load() receives { params: { slug } }
└── [...path]/             # Catch-all route (greedy)
```

### Dynamic Page Example

```typescript
// src/routes/posts/[slug]/+page.server.ts
import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, locals }) => {
  const post = await locals.db.post.findUnique({
    where: { slug: params.slug }
  });

  if (!post) {
    throw error(404, 'Post not found');
  }

  return { post };
};
```

## API Routes

### Basic API Endpoint

```typescript
// src/routes/api/posts/+server.ts
import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ locals }) => {
  const posts = await locals.db.post.findMany();
  return json(posts);
};

export const POST: RequestHandler = async ({ request, locals }) => {
  const body = await request.json();

  try {
    const post = await locals.db.post.create({
      data: {
        title: body.title,
        slug: body.slug,
        content: body.content
      }
    });

    return json(post, { status: 201 });
  } catch (err) {
    return json({ error: 'Failed to create post' }, { status: 400 });
  }
};
```

### API Route with Auth Middleware

```typescript
// src/routes/api/admin/posts/+server.ts
import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, locals }) => {
  // Check authentication
  if (!locals.user || !locals.user.isAdmin) {
    throw error(401, 'Unauthorized');
  }

  const body = await request.json();

  try {
    const post = await locals.db.post.create({
      data: {
        title: body.title,
        authorId: locals.user.id
      }
    });

    return json(post, { status: 201 });
  } catch (err) {
    return json({ error: 'Failed to create post' }, { status: 400 });
  }
};
```

## Stores

### Writable Store

```typescript
// src/lib/stores/counter.ts
import { writable } from 'svelte/store';

export const count = writable(0);
```

### Usage in Component

```svelte
<script>
  import { count } from '$lib/stores/counter';
</script>

<p>Count: {$count}</p>
<button on:click={() => count.update(n => n + 1)}>
  Increment
</button>
```

### Derived Store

```typescript
// src/lib/stores/user.ts
import { writable, derived } from 'svelte/store';

export const user = writable({
  firstName: 'John',
  lastName: 'Doe'
});

export const fullName = derived(user, $user => {
  return `${$user.firstName} ${$user.lastName}`;
});
```

### Custom Store Factory

```typescript
// src/lib/stores/timer.ts
import { writable } from 'svelte/store';

function createTimer() {
  const { subscribe, set, update } = writable(0);

  let interval: NodeJS.Timeout;

  return {
    subscribe,
    start: () => {
      interval = setInterval(() => update(n => n + 1), 1000);
    },
    stop: () => {
      clearInterval(interval);
    },
    reset: () => set(0)
  };
}

export const timer = createTimer();
```

## Form Actions

### Server-Side Form Handling

```typescript
// src/routes/posts/new/+page.server.ts
import { redirect } from '@sveltejs/kit';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async () => {
  return {};
};

export const actions: Actions = {
  default: async ({ request, locals }) => {
    const formData = await request.formData();

    try {
      const post = await locals.db.post.create({
        data: {
          title: formData.get('title') as string,
          content: formData.get('content') as string,
          slug: formData.get('title')?.toString().toLowerCase().replace(/\s+/g, '-')
        }
      });

      throw redirect(303, `/posts/${post.slug}`);
    } catch (err) {
      return {
        success: false,
        error: 'Failed to create post'
      };
    }
  }
};
```

### Form Component with Actions

```svelte
<!-- src/routes/posts/new/+page.svelte -->
<script lang="ts">
  import type { ActionData } from './$types';

  export let form: ActionData;
</script>

<form method="POST">
  <input
    type="text"
    name="title"
    placeholder="Post title"
    required
  />

  <textarea
    name="content"
    placeholder="Post content"
    required
  ></textarea>

  <button type="submit">Create Post</button>

  {#if form?.error}
    <p class="error">{form.error}</p>
  {/if}
</form>

<style>
  form {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    max-width: 600px;
  }

  .error {
    color: #e74c3c;
  }
</style>
```

### Named Actions

```typescript
// src/routes/admin/posts/[id]/+page.server.ts
export const actions: Actions = {
  edit: async ({ request, params }) => {
    const formData = await request.formData();
    // Update post
  },
  delete: async ({ params }) => {
    // Delete post
  }
};
```

```svelte
<form method="POST" action="?/edit">
  <!-- Edit form -->
</form>

<form method="POST" action="?/delete">
  <button type="submit">Delete</button>
</form>
```

## Server-Side Rendering (SSR)

### Disabling SSR for a Page

```typescript
// src/routes/dashboard/+page.ts
export const ssr = false;

export const load: PageLoad = async ({ fetch }) => {
  // Only runs on client
};
```

### Disabling SSR Globally

```javascript
// svelte.config.js
export default {
  kit: {
    ssr: false
  }
};
```

## Hooks

### Handle Hook

```typescript
// src/hooks.server.ts
import type { Handle } from '@sveltejs/kit';
import { redirect } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
  // Check authentication
  const user = await getUserFromSession(event.cookies);
  event.locals.user = user;

  // Block access to admin routes
  if (event.url.pathname.startsWith('/admin') && !user?.isAdmin) {
    throw redirect(302, '/login');
  }

  return resolve(event);
};
```

### Sequence Hook

```typescript
// src/hooks.server.ts
import { handle as authHandle } from './auth';
import { handle as loggingHandle } from './logging';

export const handle = sequence(authHandle, loggingHandle);
```

## Layout Pattern

### Root Layout

```svelte
<!-- src/routes/+layout.svelte -->
<script>
  import Header from '$lib/components/Header.svelte';
  import Footer from '$lib/components/Footer.svelte';
  import '../app.css';
</script>

<Header />

<main>
  <slot />
</main>

<Footer />

<style>
  main {
    min-height: 100vh;
  }
</style>
```

### Nested Layout

```svelte
<!-- src/routes/admin/+layout.svelte -->
<script>
  import Sidebar from '$lib/components/Sidebar.svelte';
</script>

<div class="admin-layout">
  <Sidebar />
  <div class="content">
    <slot />
  </div>
</div>

<style>
  .admin-layout {
    display: grid;
    grid-template-columns: 200px 1fr;
    gap: 1rem;
  }
</style>
```

## Component Pattern

```svelte
<!-- src/lib/components/Card.svelte -->
<script lang="ts">
  export let title: string;
  export let description = '';
</script>

<article class="card">
  <h2>{title}</h2>
  {#if description}
    <p>{description}</p>
  {/if}
  <slot />
</article>

<style>
  .card {
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 1rem;
    background: white;
  }
</style>
```

## Testing with Vitest

### Unit Test

```typescript
// tests/unit/utils.test.ts
import { describe, it, expect } from 'vitest';
import { slugify } from '$lib/utils';

describe('slugify', () => {
  it('converts title to slug', () => {
    expect(slugify('Hello World')).toBe('hello-world');
  });

  it('handles special characters', () => {
    expect(slugify('Hello & World!')).toBe('hello-world');
  });
});
```

### Component Test

```typescript
// tests/unit/Card.test.ts
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/svelte';
import Card from '$lib/components/Card.svelte';

describe('Card', () => {
  it('renders title', () => {
    render(Card, { props: { title: 'Test' } });
    expect(screen.getByText('Test')).toBeInTheDocument();
  });

  it('renders slot content', () => {
    render(Card, {
      props: { title: 'Test' },
      slots: { default: 'Slot content' }
    });
    expect(screen.getByText('Slot content')).toBeInTheDocument();
  });
});
```

### Integration Test

```typescript
// tests/integration/posts.test.ts
import { describe, it, expect } from 'vitest';

describe('POST /api/posts', () => {
  it('creates a post', async () => {
    const response = await fetch('/api/posts', {
      method: 'POST',
      body: JSON.stringify({
        title: 'Test Post',
        content: 'Test content'
      })
    });

    expect(response.status).toBe(201);
    const post = await response.json();
    expect(post.title).toBe('Test Post');
  });
});
```

## Conventions

- **File-based routing**: Routes match directory structure
- **Data loading**: Use `+page.ts` for universal, `+page.server.ts` for server-only
- **API routes**: Use `+server.ts` with named exports (GET, POST, etc.)
- **Stores**: Use Svelte stores for shared state, place in `lib/stores/`
- **Components**: Prefix component files with capital letter, place in `lib/components/`
- **Types**: Use SvelteKit's generated `$types` for full type safety
- **Forms**: Use form actions for server-side validation and mutation
- **Layouts**: Nest layouts with `+layout.svelte`, compose with `<slot />`
- **Styling**: Use Svelte component styles by default, global styles in `app.css`
- **Error handling**: Use `throw error()` for HTTP errors in load functions
- **Redirects**: Use `throw redirect()` for navigation from load/action
- **Environment variables**: Use `$env/static/private` and `$env/dynamic/private` on server, `$env/static/public` on client
- **Assets**: Use `/` prefix for absolute imports, `$lib/` for library imports

## Configuration

### svelte.config.js

```javascript
import adapter from '@sveltejs/adapter-auto';

export default {
  kit: {
    adapter: adapter(),
    alias: {
      $components: 'src/lib/components'
    }
  }
};
```

### vite.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import sveltekit from '@sveltejs/kit/vite';

export default defineConfig({
  plugins: [sveltekit()],
  test: {
    globals: true,
    environment: 'jsdom'
  }
});
```

## Agent Task Template

```markdown
# SvelteKit Feature: [Name]

## Requirements
- [ ] Create page structure with routes
- [ ] Implement load function(s) with data
- [ ] Add form with server action
- [ ] Create reusable components
- [ ] Set up Svelte stores for state
- [ ] Add form validation
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Test in dev environment
- [ ] Check performance (bundle size, SSR)

## Files to Create/Modify
- `src/routes/...`
- `src/lib/components/...`
- `src/lib/stores/...`
- `tests/...`

## Testing
```bash
npm run test
npm run test:ui
```

## Verification
- [ ] All tests pass
- [ ] No TypeScript errors
- [ ] Pages load quickly
- [ ] Forms submit and validate
```
