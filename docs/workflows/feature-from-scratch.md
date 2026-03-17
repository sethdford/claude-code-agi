# Workflow: Build a Feature From Zero

**Goal:** Build a new feature from requirements through production deployment, following TDD and maintaining code quality.

**Context:** You've been given a feature requirement and a target codebase. You need to deliver working, tested, production-ready code.

## Phase 1: Brainstorm (15 min)

Before writing code, understand the problem deeply.

### 1.1: Define Requirements

Ask yourself (or the stakeholder):

- **What is the user trying to do?** (not the technical implementation)
- **What are the acceptance criteria?** (testable outcomes)
- **What are the edge cases?** (null values, errors, rate limits, permissions)
- **What are the constraints?** (timeline, performance, backwards compatibility)
- **What data is involved?** (inputs, outputs, side effects)

**Capture this in a brief requirements doc:**

```markdown
# Feature: [Name]

## User Story
As a [role], I want to [action] so that [outcome]

## Acceptance Criteria
- [ ] User can [action] from [location]
- [ ] [Condition] triggers [behavior]
- [ ] Error handling: [scenario] shows [message]
- [ ] Performance: [metric] stays under [threshold]

## Edge Cases
- Null/missing data: [handling]
- User without permission: [handling]
- Rate limiting: [handling]
- Concurrent actions: [handling]

## Out of Scope
- [Thing we're not building]
- [Thing we can defer]

## Success Metrics
- [ ] All acceptance criteria pass
- [ ] 80% test coverage
- [ ] No performance regression
- [ ] Deploys without errors
```

### 1.2: Identify Dependencies

What does this feature depend on?

- **External services?** (APIs, databases, third-party tools)
- **Existing code?** (models, services, utilities)
- **Team members?** (who needs to review?)
- **Infrastructure?** (new database tables, environment variables)

**Time-saving trick:** If dependencies aren't met, build a mock or stub first. Don't block on someone else's work.

### 1.3: Brainstorm Trade-offs

For each major decision, list pros/cons:

| Decision | Option A | Option B | Pick | Why |
|----------|----------|----------|------|-----|
| Where to store state? | Redux | Context API | Context | Simpler for this scope |
| API or local-first? | REST API | Local cache first | Cache first | Better UX on slow networks |
| UI library? | Custom components | Material-UI | Custom | Matches brand guidelines |

## Phase 2: Plan (20 min)

### 2.1: Design the API Surface

**If building a backend feature:**

```typescript
// Define the request/response contract
POST /api/users
{
  "name": string,
  "email": string,
  "role": "admin" | "user"
}

200 Response:
{
  "id": string,
  "name": string,
  "email": string,
  "createdAt": ISO8601,
  "role": "admin" | "user"
}

400 Error:
{
  "error": "Invalid email format"
}

401 Error:
{
  "error": "Unauthorized"
}
```

**If building a frontend feature:**

```typescript
// Define the component interface
<UserForm
  onSubmit={(data) => void}
  loading={boolean}
  error={string | null}
/>

// Define state shape
type FormState = {
  name: string;
  email: string;
  role: "admin" | "user";
  isLoading: boolean;
  error: string | null;
}
```

### 2.2: Identify Files to Create/Modify

Create a manifest:

```markdown
## Files

### Create
- `src/api/users.ts` — User API service
- `src/models/user.ts` — User model and validation
- `src/components/UserForm.tsx` — Form UI
- `src/__tests__/api/users.test.ts` — API tests
- `src/__tests__/components/UserForm.test.tsx` — Component tests

### Modify
- `src/routes.tsx` — Add route for new page
- `src/types/index.ts` — Add User type
- `package.json` — Add any dependencies

### Defer
- Migration UI (next sprint)
- Bulk import (next sprint)
```

### 2.3: Design Test Strategy

For each file, plan what to test:

```markdown
## Test Strategy

### api/users.ts
- [ ] `createUser()` with valid data → returns user object
- [ ] `createUser()` with invalid email → throws validation error
- [ ] `createUser()` with duplicate email → throws 400
- [ ] Network error → retries up to 3 times
- [ ] 401 response → redirects to login

### components/UserForm.tsx
- [ ] Renders form with name, email, role inputs
- [ ] Submits with valid data → calls onSubmit
- [ ] Shows error message when onSubmit throws
- [ ] Disables submit button while loading
- [ ] Input validation: email field rejects invalid format

### components/UserPage.tsx
- [ ] Loads users on mount
- [ ] Displays list of users
- [ ] Opens form when "Create" is clicked
- [ ] Refreshes list after successful creation
- [ ] Shows loading spinner while fetching
```

### 2.4: Get Stakeholder Buy-in (if applicable)

Share your plan with the team lead or stakeholder:

- "Does this implementation match what you expected?"
- "Are there edge cases I missed?"
- "Should we defer any work?"

**This saves rework later.**

## Phase 3: TDD — Write Failing Tests First (30 min)

Now write tests *before* implementing features. This forces clarity and acts as living documentation.

### 3.1: Write API Tests

```typescript
// src/__tests__/api/users.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as api from '../../api/users';

describe('User API', () => {
  describe('createUser', () => {
    it('creates a user with valid data', async () => {
      const result = await api.createUser({
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user'
      });

      expect(result.id).toBeDefined();
      expect(result.name).toBe('John Doe');
      expect(result.email).toBe('john@example.com');
    });

    it('throws error with invalid email', async () => {
      expect(async () => {
        await api.createUser({
          name: 'John Doe',
          email: 'invalid-email',
          role: 'user'
        });
      }).rejects.toThrow('Invalid email');
    });

    it('throws error with duplicate email', async () => {
      expect(async () => {
        await api.createUser({
          name: 'John Doe',
          email: 'taken@example.com',
          role: 'user'
        });
      }).rejects.toThrow('Email already exists');
    });

    it('retries on network error', async () => {
      const fetchSpy = vi.spyOn(global, 'fetch').mockRejectedValueOnce(new Error('Network error'));
      const result = await api.createUser({
        name: 'John Doe',
        email: 'john@example.com',
        role: 'user'
      });
      expect(fetchSpy).toHaveBeenCalledTimes(2); // 1 failure + 1 retry
    });
  });

  describe('getUsers', () => {
    it('returns list of users', async () => {
      const users = await api.getUsers();
      expect(Array.isArray(users)).toBe(true);
      expect(users.length).toBeGreaterThan(0);
    });
  });
});
```

### 3.2: Write Component Tests

```typescript
// src/__tests__/components/UserForm.test.tsx
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { UserForm } from '../../components/UserForm';

describe('UserForm', () => {
  it('renders form with inputs', () => {
    render(<UserForm onSubmit={vi.fn()} loading={false} error={null} />);

    expect(screen.getByLabelText('Name')).toBeInTheDocument();
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByLabelText('Role')).toBeInTheDocument();
  });

  it('calls onSubmit with form data', async () => {
    const onSubmit = vi.fn();
    render(<UserForm onSubmit={onSubmit} loading={false} error={null} />);

    fireEvent.change(screen.getByLabelText('Name'), { target: { value: 'John Doe' } });
    fireEvent.change(screen.getByLabelText('Email'), { target: { value: 'john@example.com' } });
    fireEvent.click(screen.getByRole('button', { name: /submit/i }));

    expect(onSubmit).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'John Doe',
        email: 'john@example.com'
      })
    );
  });

  it('disables submit button while loading', () => {
    render(<UserForm onSubmit={vi.fn()} loading={true} error={null} />);

    expect(screen.getByRole('button', { name: /submit/i })).toBeDisabled();
  });

  it('shows error message', () => {
    render(<UserForm onSubmit={vi.fn()} loading={false} error="Email already exists" />);

    expect(screen.getByText('Email already exists')).toBeInTheDocument();
  });
});
```

### 3.3: Verify Tests Fail

Run the tests — they should all fail (because the code doesn't exist yet):

```bash
npm test
# or
pnpm test
```

**This is expected.** We're writing the spec first.

## Phase 4: Build — Implement to Make Tests Pass (60 min)

Now implement the feature to make tests pass. Focus on correctness, not optimization.

### 4.1: Implement API Service

```typescript
// src/api/users.ts
import { User, CreateUserInput } from '../types';

const BASE_URL = 'https://api.example.com';

export async function createUser(input: CreateUserInput): Promise<User> {
  // Validate input
  if (!input.email.includes('@')) {
    throw new Error('Invalid email');
  }

  // Make API call with retry logic
  let attempt = 0;
  while (attempt < 3) {
    try {
      const response = await fetch(`${BASE_URL}/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(input)
      });

      if (response.status === 400) {
        const error = await response.json();
        throw new Error(error.message);
      }

      if (response.status === 401) {
        window.location.href = '/login';
        throw new Error('Unauthorized');
      }

      if (!response.ok) {
        throw new Error('Network error');
      }

      return response.json();
    } catch (err) {
      attempt++;
      if (attempt >= 3) throw err;
      await new Promise(r => setTimeout(r, 1000 * attempt)); // Exponential backoff
    }
  }

  throw new Error('Failed after retries');
}

export async function getUsers(): Promise<User[]> {
  const response = await fetch(`${BASE_URL}/users`);
  if (!response.ok) throw new Error('Failed to fetch users');
  return response.json();
}
```

### 4.2: Implement Component

```typescript
// src/components/UserForm.tsx
import { useState } from 'react';

export interface UserFormProps {
  onSubmit: (data: any) => Promise<void>;
  loading: boolean;
  error: string | null;
}

export function UserForm({ onSubmit, loading, error }: UserFormProps) {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    role: 'user' as const
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await onSubmit(formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <label htmlFor="name">Name</label>
        <input
          id="name"
          value={formData.name}
          onChange={(e) => setFormData({ ...formData, name: e.target.value })}
          required
        />
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          value={formData.email}
          onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          required
        />
      </div>

      <div>
        <label htmlFor="role">Role</label>
        <select
          id="role"
          value={formData.role}
          onChange={(e) => setFormData({ ...formData, role: e.target.value as any })}
        >
          <option value="user">User</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      <button type="submit" disabled={loading}>
        {loading ? 'Creating...' : 'Create User'}
      </button>

      {error && <div style={{ color: 'red' }}>{error}</div>}
    </form>
  );
}
```

### 4.3: Verify Tests Pass

```bash
npm test
# All tests should now pass
```

## Phase 5: Review — Self-Review + Peer Review (20 min)

### 5.1: Self-Review Checklist

Before requesting a review, audit your own code:

- [ ] Code is readable and follows team conventions
- [ ] No `console.log()` or debugging statements left
- [ ] No hardcoded values (use constants instead)
- [ ] Error messages are helpful to the user
- [ ] Tests pass locally: `npm test`
- [ ] Build works: `npm run build`
- [ ] No TypeScript errors: `npx tsc --noEmit`
- [ ] Code is formatted: `npm run format`
- [ ] No security issues (no hardcoded secrets, no SQL injection, etc.)
- [ ] Performance: No N+1 queries, no unnecessary re-renders
- [ ] Accessibility: Form labels, ARIA attributes, keyboard navigation

### 5.2: Dispatch Code-Reviewer Agent

Use a specialized code-review agent to catch issues before human review:

```markdown
Agent(code-reviewer)
- Model: Sonnet (higher quality)
- Read-only mode
- maxTurns: 2

## Task: Review Feature Implementation

Focus on:
1. **Correctness**: Do tests prove the code works?
2. **Safety**: Are there security or data issues?
3. **Performance**: N+1 queries, unnecessary re-renders?
4. **Readability**: Variable names, function length, comments?
5. **Testing**: Are edge cases covered?

Return:
- List of issues found (if any)
- Suggestions for improvement
- Approval or request for changes
```

### 5.3: Fix Issues

Address code-reviewer feedback before pushing.

## Phase 6: Commit & Push (5 min)

```bash
# Stage files
git add -A

# Write descriptive commit message
git commit -m "feat: add user creation feature

- Implement createUser API with validation
- Add UserForm component with error handling
- Add comprehensive test coverage for edge cases
- Includes retry logic for network errors"

# Push to feature branch
git push origin feature/add-users
```

## Phase 7: Open PR (5 min)

Open a pull request on GitHub/GitLab with:

```markdown
## Description
Add user creation feature, allowing admins to create new user accounts with validation.

## Changes
- API service for user creation with retry logic
- UserForm component with form validation
- 95% test coverage

## Testing
- [x] All tests pass locally
- [x] Manual testing: form validation, error handling, success flow
- [x] Edge cases: null inputs, network errors, duplicate email

## Screenshots
[Include before/after if UI-heavy]

## Checklist
- [x] Tests pass
- [x] No console.log statements
- [x] Follows team conventions
- [x] Ready for review
```

## Phase 8: Deploy (10 min)

Once reviewed and approved:

```bash
# Pull latest main
git checkout main
git pull origin main

# Merge feature branch
git merge feature/add-users

# Follow team's deploy process
./scripts/deploy.sh  # or equivalent
```

## Timing Summary

| Phase | Task | Time | Total |
|-------|------|------|-------|
| 1 | Brainstorm | 15 min | 15 min |
| 2 | Plan | 20 min | 35 min |
| 3 | Write tests | 30 min | 65 min |
| 4 | Implement | 60 min | 125 min |
| 5 | Review | 20 min | 145 min |
| 6 | Commit | 5 min | 150 min |
| 7 | PR | 5 min | 155 min |
| 8 | Deploy | 10 min | 165 min |

**Total: ~2.5 hours for a small-to-medium feature**

## Key Principles

✅ **Test-first**: Write tests before code. They're your spec.
✅ **Fail explicitly**: Run tests *before* implementing. Red → Green → Refactor.
✅ **Self-review**: Catch obvious issues before asking humans.
✅ **Commit narrative**: Your commit message should explain *why*, not just *what*.
✅ **Deploy with confidence**: If tests pass and code review approves, deploy with confidence.

## When You Get Stuck

- **Test won't pass?** Read the error message carefully. It's telling you what's wrong.
- **Don't know how to implement?** Look at similar code in the codebase. Follow the pattern.
- **Edge case you missed?** Add it to the test first, then implement the fix.
- **Performance concern?** Profile first (don't guess). Add a performance test.

---

**Next:** Deploy to production, monitor logs, and celebrate. Then pick the next feature.
