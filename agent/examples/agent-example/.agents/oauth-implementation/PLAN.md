# Implementation Plan

## Overview
Implement OAuth 2.0 backend for Google and GitHub providers. This is a focused backend task - UI implementation is handled by ui-migration agent, integration testing by wizard agent.

## Architecture

```
┌─────────────────────────────────────────────────┐
│           OAuth Flow Architecture               │
└─────────────────────────────────────────────────┘

1. User clicks "Sign in with Google"
   ↓
2. Redirect to Google OAuth consent screen
   ↓
3. User approves access
   ↓
4. Google redirects to /auth/google/callback?code=xyz
   ↓
5. Exchange code for access token
   ↓
6. Fetch user info from Google
   ↓
7. Create/find user in database
   ↓
8. Generate JWT token (same as password auth)
   ↓
9. Set authToken cookie and return user
```

## Modules to Create

### 1. OAuth Providers (`src/auth/oauth/providers/`)

**google.provider.ts**
```typescript
export class GoogleOAuthProvider {
  constructor(config: GoogleOAuthConfig);

  // Initialize OAuth flow, return redirect URL
  getAuthorizationUrl(state: string): string;

  // Exchange authorization code for tokens
  exchangeCodeForTokens(code: string): Promise<OAuthTokens>;

  // Refresh access token
  refreshAccessToken(refreshToken: string): Promise<OAuthTokens>;

  // Get user info from Google
  getUserInfo(accessToken: string): Promise<OAuthUserInfo>;
}
```

**github.provider.ts**
```typescript
export class GitHubOAuthProvider {
  constructor(config: GitHubOAuthConfig);

  getAuthorizationUrl(state: string): string;
  exchangeCodeForTokens(code: string): Promise<OAuthTokens>;
  // Note: GitHub uses long-lived tokens, no refresh needed
  getUserInfo(accessToken: string): Promise<OAuthUserInfo>;
}
```

### 2. OAuth Manager (`src/auth/oauth/oauth-manager.ts`)

**Responsibilities:**
- Manage OAuth state (CSRF protection)
- Coordinate provider interactions
- Handle user creation/lookup
- Generate JWT after OAuth success

```typescript
export class OAuthManager {
  // Generate and store state parameter
  generateState(): Promise<string>;

  // Validate state parameter
  validateState(state: string): Promise<boolean>;

  // Find or create user from OAuth info
  findOrCreateUser(
    provider: 'google' | 'github',
    userInfo: OAuthUserInfo
  ): Promise<User>;

  // Link OAuth to existing user
  linkOAuthToUser(
    userId: UUID,
    provider: string,
    oauthInfo: OAuthUserInfo
  ): Promise<void>;
}
```

### 3. Token Storage (`src/auth/oauth/token-storage.ts`)

**Responsibilities:**
- Store OAuth tokens in Redis
- Retrieve tokens by user ID and provider
- Handle token expiry and refresh

```typescript
export class OAuthTokenStorage {
  // Store tokens in Redis
  async storeTokens(
    userId: UUID,
    provider: string,
    tokens: OAuthTokens
  ): Promise<void>;

  // Get tokens from Redis
  async getTokens(
    userId: UUID,
    provider: string
  ): Promise<OAuthTokens | null>;

  // Delete tokens (unlink)
  async deleteTokens(
    userId: UUID,
    provider: string
  ): Promise<void>;

  // Get all tokens expiring soon
  async getExpiringTokens(
    withinMinutes: number
  ): Promise<Array<{userId: UUID, provider: string}>>;
}
```

### 4. Token Refresh Worker (`src/workers/oauth-token-refresh.ts`)

**Responsibilities:**
- Background job to refresh tokens before expiry
- Runs every minute
- Refreshes tokens expiring within 5 minutes

```typescript
export class OAuthTokenRefreshWorker {
  async start(): Promise<void>;
  async stop(): Promise<void>;

  private async refreshExpiringTokens(): Promise<void>;
}
```

### 5. Routes (`src/api/routes/auth/oauth.ts`)

```typescript
// Initiate OAuth flow
router.get('/oauth/:provider', async (req, res) => {
  // Generate state, get authorization URL, redirect
});

// OAuth callback
router.get('/oauth/:provider/callback', async (req, res) => {
  // Validate state, exchange code, create/find user, issue JWT
});

// Link OAuth to existing account
router.post('/link/:provider', requireAuth, async (req, res) => {
  // Exchange code, link to req.user
});

// Unlink OAuth provider
router.delete('/link/:provider', requireAuth, async (req, res) => {
  // Remove OAuth link, delete tokens
});

// List linked providers
router.get('/providers', requireAuth, async (req, res) => {
  // Return array of linked providers
});
```

### 6. Database Migration (`migrations/003_add_oauth_support.sql`)

```sql
-- Add OAuth providers array to users
ALTER TABLE users ADD COLUMN oauth_providers JSONB DEFAULT '[]';

-- Create oauth_tokens table
CREATE TABLE oauth_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL,
  access_token TEXT NOT NULL,
  refresh_token TEXT,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, provider)
);

-- Index for fast lookups
CREATE INDEX idx_oauth_tokens_user_provider
  ON oauth_tokens(user_id, provider);

-- Index for token refresh worker
CREATE INDEX idx_oauth_tokens_expiry
  ON oauth_tokens(expires_at)
  WHERE expires_at IS NOT NULL;
```

## Implementation Phases

### Phase 1: Foundation (Day 1)
**Goal:** Set up infrastructure

1. Create directory structure
   - `src/auth/oauth/providers/`
   - `src/auth/oauth/`

2. Install dependencies
   ```bash
   npm install passport passport-google-oauth20 passport-github2
   npm install -D @types/passport @types/passport-google-oauth20
   ```

3. Add TypeScript types
   ```typescript
   // src/auth/oauth/types.ts
   interface OAuthTokens {
     access_token: string;
     refresh_token?: string;
     expires_at?: Date;
   }

   interface OAuthUserInfo {
     provider: 'google' | 'github';
     provider_user_id: string;
     email: string;
     name?: string;
     avatar_url?: string;
   }
   ```

4. Database migration
   - Write migration SQL
   - Test on local database
   - Test on copy of staging database

### Phase 2: Google Provider (Days 2-3)
**Goal:** Complete Google OAuth implementation

1. Implement GoogleOAuthProvider
   - Authorization URL generation
   - Token exchange
   - Token refresh
   - User info fetching

2. Implement OAuthManager
   - State generation/validation
   - User lookup/creation
   - OAuth-to-JWT bridge

3. Implement OAuthTokenStorage
   - Redis storage logic
   - TTL handling

4. Add routes
   - `/oauth/google`
   - `/oauth/google/callback`

5. Manual testing
   - Create Google OAuth app
   - Test full flow
   - Verify JWT issued correctly

6. Write tests
   - Unit tests for provider
   - Integration test for full flow
   - Mock Google API responses

7. **Notify wizard: Google provider complete**

### Phase 3: GitHub Provider (Day 4)
**Goal:** Complete GitHub OAuth implementation

1. Implement GitHubOAuthProvider
   - Similar to Google, but no refresh logic
   - GitHub uses long-lived tokens

2. Add routes
   - `/oauth/github`
   - `/oauth/github/callback`

3. Manual testing
   - Create GitHub OAuth app
   - Test full flow

4. Write tests
   - Unit tests
   - Integration tests

### Phase 4: Account Linking (Day 4-5)
**Goal:** Allow users to link OAuth to existing accounts

1. Implement linking logic
   - POST `/link/:provider`
   - Verify email matches
   - Update user record
   - Store tokens

2. Implement unlinking
   - DELETE `/link/:provider`
   - Remove from user record
   - Delete tokens from Redis

3. Add provider list endpoint
   - GET `/providers`
   - Return array of linked providers

4. Write tests
   - Test linking success
   - Test linking failure (email mismatch)
   - Test unlinking

### Phase 5: Token Refresh & Polish (Day 5)
**Goal:** Complete token refresh and finalize

1. Implement OAuthTokenRefreshWorker
   - Background job every 60 seconds
   - Find tokens expiring within 5 minutes
   - Refresh them proactively
   - Update Redis with new tokens
   - Log failures

2. Add worker to app startup
   ```typescript
   // src/index.ts
   const refreshWorker = new OAuthTokenRefreshWorker();
   refreshWorker.start();
   ```

3. Error handling
   - Add try/catch to all routes
   - User-friendly error messages
   - Logging for debugging

4. Security review
   - CSRF state validation ✓
   - No secrets in logs ✓
   - Secure token storage ✓
   - Rate limiting

5. Documentation
   - API documentation (OpenAPI format)
   - Environment variables
   - Example requests/responses

## Data Flow

### OAuth Login Flow
```
Client                    Server                 OAuth Provider
  |                          |                          |
  |-- GET /oauth/google ---->|                          |
  |                          |-- Generate state         |
  |                          |-- Store state in session |
  |<-- Redirect to Google ---|                          |
  |                          |                          |
  |-------------- User authorizes on Google ----------->|
  |                          |                          |
  |<-- Redirect with code ---|                          |
  |                          |                          |
  |-- GET /callback?code --->|                          |
  |                          |-- Validate state         |
  |                          |-- Exchange code -------->|
  |                          |<-- Access + refresh -----|
  |                          |                          |
  |                          |-- Get user info -------->|
  |                          |<-- Email, name, etc. ----|
  |                          |                          |
  |                          |-- Find/create user       |
  |                          |-- Generate JWT           |
  |                          |-- Store OAuth tokens     |
  |<-- Set cookie, return ---|                          |
  |    {user, token}         |                          |
```

### Account Linking Flow
```
Client                    Server
  |                          |
  |-- POST /link/google ---->|
  |    {code: "xyz"}         |
  |                          |-- requireAuth middleware (user already logged in)
  |                          |-- Exchange code for tokens
  |                          |-- Get user info from Google
  |                          |-- Verify email matches logged-in user
  |                          |-- Update users.oauth_providers
  |                          |-- Store tokens in Redis
  |<-- {success: true} ------|
```

## Edge Cases

### 1. Email Already Exists (Different Auth Method)
**Scenario:** User has password account with email@example.com. Tries to login with Google OAuth using same email.

**Solution:**
- Check if email exists during OAuth callback
- If exists AND no OAuth link: show confirmation screen (handled by UI)
- If exists AND already linked: proceed normally
- If not exists: create new user

### 2. Token Refresh Failure
**Scenario:** OAuth refresh token is invalid/revoked.

**Solution:**
- Log error
- Delete tokens from Redis
- Next API call will fail auth
- User must re-authenticate via OAuth

### 3. Multiple OAuth Providers, Same Email
**Scenario:** User links both Google and GitHub with same email.

**Solution:**
- Allowed - store both providers in `oauth_providers` array
- User can login with either provider
- Both map to same user ID

### 4. OAuth Provider Downtime
**Scenario:** Google/GitHub API is down during login.

**Solution:**
- Catch API errors
- Return 503 Service Unavailable
- User sees "Google is temporarily unavailable, try password login"

### 5. State Parameter Mismatch (CSRF Attack)
**Scenario:** Attacker tries to inject malicious state parameter.

**Solution:**
- Validate state on callback
- If mismatch: return 400 Bad Request
- Log security event
- Do not proceed with OAuth flow

## Testing Strategy

### Unit Tests (23 tests)
```
GoogleOAuthProvider
  ✓ getAuthorizationUrl generates correct URL
  ✓ exchangeCodeForTokens exchanges code for tokens
  ✓ refreshAccessToken refreshes expired token
  ✓ getUserInfo fetches user info from Google
  ✓ handles API errors gracefully

GitHubOAuthProvider
  ✓ getAuthorizationUrl generates correct URL
  ✓ exchangeCodeForTokens exchanges code for tokens
  ✓ getUserInfo fetches user info from GitHub

OAuthManager
  ✓ generateState creates random 32-byte string
  ✓ validateState accepts valid state
  ✓ validateState rejects invalid state
  ✓ findOrCreateUser creates new user
  ✓ findOrCreateUser finds existing user
  ✓ linkOAuthToUser links OAuth to existing user

OAuthTokenStorage
  ✓ storeTokens stores tokens in Redis
  ✓ getTokens retrieves tokens from Redis
  ✓ deleteTokens removes tokens from Redis
  ✓ getExpiringTokens finds tokens expiring soon

OAuthTokenRefreshWorker
  ✓ refreshExpiringTokens refreshes tokens
  ✓ handles refresh failures
```

### Integration Tests (5 tests)
```
OAuth Flow
  ✓ Full Google OAuth login flow
  ✓ Full GitHub OAuth login flow
  ✓ Account linking flow
  ✓ Account unlinking flow
  ✓ Token refresh on expiry
```

### Manual Testing Checklist
- [ ] Google OAuth login with test account
- [ ] GitHub OAuth login with test account
- [ ] Link Google to existing password account
- [ ] Link GitHub to existing password account
- [ ] Unlink Google provider
- [ ] Unlink GitHub provider
- [ ] Verify tokens stored in Redis
- [ ] Verify JWT issued after OAuth success
- [ ] Test error: invalid authorization code
- [ ] Test error: Google API down (mock)
- [ ] Test CSRF protection (manipulate state parameter)

## Success Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Unit test coverage | ≥ 80% | TBD |
| Integration tests passing | 5/5 | TBD |
| API latency (OAuth flow) | < 1s p95 | TBD |
| Manual tests passing | 11/11 | TBD |
| Security vulnerabilities | 0 | TBD |

## Deliverables

- [ ] Google OAuth provider implementation
- [ ] GitHub OAuth provider implementation
- [ ] OAuth manager with state management
- [ ] Token storage in Redis
- [ ] Token refresh background worker
- [ ] Account linking endpoints
- [ ] Database migration
- [ ] Unit tests (≥80% coverage)
- [ ] Integration tests (5 tests)
- [ ] API documentation
- [ ] Environment variables documented
