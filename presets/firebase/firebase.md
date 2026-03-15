# Firebase Conventions

This preset covers best practices for Firebase (Firestore, Cloud Functions, authentication, deployment).

## Collection Names

Define a constant for collection names in your project. Never hardcode collection name strings throughout the codebase.

**Pattern:**

```typescript
// types/collections.ts
export const COLLECTIONS = {
  users: 'users',
  orders: 'orders',
  items: 'items',
  // ... all collections in one place
} as const;

// In code:
const usersRef = db.collection(COLLECTIONS.users);
```

**Why:** Makes refactoring safe. Single source of truth for collection structure.

## Cloud Functions Organization

Group Cloud Functions by domain/feature:

- **publicApi** — unauthenticated endpoints, rate limited (signup, contact forms, webhooks)
- **auth** — authentication flows, token management
- **crud** — create/read/update/delete operations
- **analytics** — data aggregation, reporting
- **scheduled** — cron jobs (daily/hourly cleanup, reports)
- **webhooks** — third-party integrations (Stripe, etc.)
- **health** — monitoring, liveness checks

**Pattern:**

```
src/
├── functions/
│   ├── public-api/
│   ├── auth/
│   ├── crud/
│   ├── analytics/
│   ├── scheduled/
│   ├── webhooks/
│   └── health/
```

## Deployment

**Never run `firebase deploy` directly.** Always use a deployment script that:

1. Validates environment (config, secrets, dependencies)
2. Builds/bundles all code
3. Runs smoke tests post-deploy
4. Records deployment state

**Pattern:**

```bash
#!/bin/bash
# scripts/deploy-functions.sh
set -e

# Validate
source .env || exit 1
firebase functions:config:get > /dev/null || exit 1

# Build
pnpm build

# Deploy
firebase deploy --only functions

# Smoke test
curl -f https://your-region-project.cloudfunctions.net/health || exit 1

echo "Deployment complete"
```

**Why:** Firebase resets memory, runtime env vars, and other settings on each deploy. A script ensures consistency and prevents silent failures.

## Firestore Rules

Security rules follow default-deny pattern: explicitly grant access, never rely on absence of rules.

**Pattern:**

```
match /{{collection}}/{document=**} {
  // Deny by default — only allow if next rule matches
  allow read, write: if false;
}

match /{{collection}}/{userId=**} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId && validateData();
}

function validateData() {
  // Custom validation logic
  return request.resource.data.keys().hasAll(['name', 'email']);
}
```

**Key rules:**

- Always validate data shape and types
- Use `request.auth.uid` for user scoping
- Reject requests from server SDKs in client code (use server-side Admin SDK only)
- Test rules with the emulator before deploying

## Indexes

Every composite query needs an index.

**Pattern:**

```json
{
  "indexes": [
    {
      "collectionId": "{{collection}}",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

**Why:** Without an index, Firestore rejects the query. Catch these early in development.

## Authentication Patterns

| Route Type       | Auth Check                      | Where to Implement        |
| ---------------- | ------------------------------- | ------------------------- |
| Private API      | Authorization header + JWT      | Middleware at route entry |
| Public API       | No auth, but rate limited       | Rate limit middleware     |
| Admin operations | Service account + custom claims | Admin SDK only            |

**Pattern (Next.js API route):**

```typescript
export async function POST(request) {
  // Verify auth
  const auth = request.headers.get('authorization');
  if (!auth) return new Response('Unauthorized', { status: 401 });

  const token = auth.split(' ')[1];
  const decoded = await verifyToken(token);
  if (!decoded) return new Response('Invalid token', { status: 403 });

  // Process request
  const result = await db.collection(COLLECTIONS.items).add(...);
  return Response.json(result);
}
```

**Pattern (Firebase Admin SDK):**

```typescript
import admin from 'firebase-admin';

const db = admin.firestore();
const doc = await db.collection(COLLECTIONS.items).add({
  // Only server-side code can write without Firestore rules validation
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

## Client SDK Usage

Never use Admin SDK in client-side code. Always go through a secure API endpoint.

**Wrong:**

```typescript
// ❌ DON'T: Admin SDK in browser
import admin from 'firebase-admin';
const db = admin.firestore();
await db.collection('items').add(...);
```

**Right:**

```typescript
// ✅ DO: Browser SDK with rules-enforced access
import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc } from 'firebase/firestore';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
await addDoc(collection(db, 'items'), {...});
// Firestore rules enforce access control
```

## Common Patterns

### Query with pagination

```typescript
const first = await db
  .collection(COLLECTIONS.items)
  .where('userId', '==', uid)
  .orderBy('createdAt', 'desc')
  .limit(10)
  .get();

const next = await db
  .collection(COLLECTIONS.items)
  .where('userId', '==', uid)
  .orderBy('createdAt', 'desc')
  .startAfter(first.docs[first.docs.length - 1])
  .limit(10)
  .get();
```

### Batch write with size limits

```typescript
const batch = db.batch();
let count = 0;
const batchSize = 500;

for (const doc of docs) {
  batch.set(db.collection(COLLECTIONS.items).doc(), doc);
  count++;

  if (count >= batchSize) {
    await batch.commit();
    batch = db.batch();
    count = 0;
  }
}

if (count > 0) await batch.commit();
```

### Real-time listener with cleanup

```typescript
const unsubscribe = db
  .collection(COLLECTIONS.items)
  .where('userId', '==', uid)
  .onSnapshot((snapshot) => {
    const items = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    // Update state
  });

// Clean up on unmount
return () => unsubscribe();
```

## Monitoring & Debugging

### Enable debug logging

```typescript
import { enableLogging } from 'firebase/firestore';
enableLogging(true); // Logs to console
```

### Check rules in the emulator

```bash
firebase emulators:start --only firestore
# Navigate to http://localhost:4000
```

### Monitor indexes

```bash
gcloud firestore indexes list --project={{PROJECT_ID}}
```

## Related Standards

- See `docs/standards/security/` for authentication and authorization patterns
- See `docs/standards/operations/` for incident response and runbooks
