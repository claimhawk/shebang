# Context

## Relevant Files

### Core Implementation
- `src/auth/oauth/providers/google.provider.ts` - Google OAuth provider (NEW)
- `src/auth/oauth/providers/github.provider.ts` - GitHub OAuth provider (NEW)
- `src/auth/oauth/oauth-manager.ts` - OAuth flow manager (NEW)
- `src/auth/oauth/token-storage.ts` - Redis token storage (NEW)
- `src/auth/oauth/types.ts` - TypeScript type definitions (NEW)
- `src/api/routes/auth/oauth.ts` - OAuth endpoints (NEW)
- `src/workers/oauth-token-refresh.ts` - Background token refresh (NEW)

### Existing Auth System
- `src/auth/jwt.ts` - JWT generation and validation (UNCHANGED)
- `src/auth/middleware.ts` - Auth middleware (UNCHANGED)
- `src/models/User.ts` - User model (MODIFIED - added oauth_providers field)
- `src/api/routes/auth.ts` - Existing auth routes (UNCHANGED)

### Database
- `migrations/003_add_oauth_support.sql` - OAuth schema migration (NEW)
- `migrations/003_rollback.sql` - Rollback script (NEW)

### Configuration
- `.env.example` - Updated with OAuth credentials (MODIFIED)
- `src/config/oauth.ts` - OAuth provider configs (NEW)

### Tests
- `tests/unit/auth/oauth/google.provider.test.ts` - Google provider tests (NEW)
- `tests/unit/auth/oauth/github.provider.test.ts` - GitHub provider tests (NEW)
- `tests/unit/auth/oauth/oauth-manager.test.ts` - Manager tests (NEW)
- `tests/unit/auth/oauth/token-storage.test.ts` - Storage tests (NEW)
- `tests/integration/auth/oauth-flow.test.ts` - Full flow tests (NEW)

## Key Functions

### Google OAuth Provider
```typescript
// src/auth/oauth/providers/google.provider.ts:15
export class GoogleOAuthProvider {
  getAuthorizationUrl(state: string): string {
    return `https://accounts.google.com/o/oauth2/v2/auth?${params}`;
  }

  async exchangeCodeForTokens(code: string): Promise<OAuthTokens> {
    const response = await axios.post('https://oauth2.googleapis.com/token', {
      code,
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      redirect_uri: this.config.callbackUrl,
      grant_type: 'authorization_code',
    });
    return {
      access_token: response.data.access_token,
      refresh_token: response.data.refresh_token,
      expires_at: new Date(Date.now() + response.data.expires_in * 1000),
    };
  }

  async refreshAccessToken(refreshToken: string): Promise<OAuthTokens> {
    const response = await axios.post('https://oauth2.googleapis.com/token', {
      refresh_token: refreshToken,
      client_id: this.config.clientId,
      client_secret: this.config.clientSecret,
      grant_type: 'refresh_token',
    });
    return {
      access_token: response.data.access_token,
      refresh_token: refreshToken, // Keep same refresh token
      expires_at: new Date(Date.now() + response.data.expires_in * 1000),
    };
  }

  async getUserInfo(accessToken: string): Promise<OAuthUserInfo> {
    const response = await axios.get('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    return {
      provider: 'google',
      provider_user_id: response.data.id,
      email: response.data.email,
      name: response.data.name,
      avatar_url: response.data.picture,
    };
  }
}
```

### OAuth Manager
```typescript
// src/auth/oauth/oauth-manager.ts:20
export class OAuthManager {
  async generateState(): Promise<string> {
    const state = crypto.randomBytes(32).toString('hex');
    // Store in Redis with 10-minute TTL
    await redis.setex(`oauth:state:${state}`, 600, '1');
    return state;
  }

  async validateState(state: string): Promise<boolean> {
    const exists = await redis.get(`oauth:state:${state}`);
    if (exists) {
      await redis.del(`oauth:state:${state}`); // One-time use
      return true;
    }
    return false;
  }

  async findOrCreateUser(
    provider: 'google' | 'github',
    userInfo: OAuthUserInfo
  ): Promise<User> {
    // Find user by email
    let user = await User.findOne({ where: { email: userInfo.email } });

    if (!user) {
      // Create new user
      user = await User.create({
        email: userInfo.email,
        oauth_providers: [provider],
        password_hash: null, // OAuth users don't have password
      });
    } else if (!user.oauth_providers.includes(provider)) {
      // Link OAuth to existing user
      user.oauth_providers.push(provider);
      await user.save();
    }

    return user;
  }
}
```

### Token Storage
```typescript
// src/auth/oauth/token-storage.ts:10
export class OAuthTokenStorage {
  async storeTokens(
    userId: UUID,
    provider: string,
    tokens: OAuthTokens
  ): Promise<void> {
    const key = `oauth:tokens:${userId}:${provider}`;
    await redis.set(key, JSON.stringify(tokens));

    // Set TTL if token has expiry
    if (tokens.expires_at) {
      const ttl = Math.floor((tokens.expires_at.getTime() - Date.now()) / 1000);
      await redis.expire(key, ttl);
    }

    // Also store in database for persistence
    await OAuthToken.upsert({
      user_id: userId,
      provider,
      access_token: tokens.access_token,
      refresh_token: tokens.refresh_token,
      expires_at: tokens.expires_at,
    });
  }

  async getTokens(userId: UUID, provider: string): Promise<OAuthTokens | null> {
    const key = `oauth:tokens:${userId}:${provider}`;
    const data = await redis.get(key);

    if (data) {
      return JSON.parse(data);
    }

    // Fallback to database if not in Redis
    const dbToken = await OAuthToken.findOne({
      where: { user_id: userId, provider },
    });

    if (dbToken) {
      const tokens = {
        access_token: dbToken.access_token,
        refresh_token: dbToken.refresh_token,
        expires_at: dbToken.expires_at,
      };
      // Restore to Redis
      await redis.set(key, JSON.stringify(tokens));
      return tokens;
    }

    return null;
  }
}
```

## Important Snippets

### OAuth Routes
```typescript
// src/api/routes/auth/oauth.ts:15
// Initiate Google OAuth flow
router.get('/oauth/google', async (req, res) => {
  const googleProvider = new GoogleOAuthProvider(config.google);
  const oauthManager = new OAuthManager();

  const state = await oauthManager.generateState();
  const authUrl = googleProvider.getAuthorizationUrl(state);

  res.redirect(authUrl);
});

// Handle Google OAuth callback
router.get('/oauth/google/callback', async (req, res) => {
  const { code, state } = req.query;

  // Validate state (CSRF protection)
  const isValidState = await oauthManager.validateState(state);
  if (!isValidState) {
    return res.status(400).json({ error: 'Invalid state parameter' });
  }

  // Exchange code for tokens
  const googleProvider = new GoogleOAuthProvider(config.google);
  const tokens = await googleProvider.exchangeCodeForTokens(code);

  // Get user info from Google
  const userInfo = await googleProvider.getUserInfo(tokens.access_token);

  // Find or create user
  const user = await oauthManager.findOrCreateUser('google', userInfo);

  // Store OAuth tokens
  const tokenStorage = new OAuthTokenStorage();
  await tokenStorage.storeTokens(user.id, 'google', tokens);

  // Generate JWT (same as password auth)
  const jwtToken = generateToken(user);

  // Set cookie and return
  res.cookie('authToken', jwtToken, { httpOnly: true, secure: true });
  res.json({
    user: { id: user.id, email: user.email },
    token: jwtToken,
  });
});
```

### Database Schema
```sql
-- migrations/003_add_oauth_support.sql

-- Add OAuth providers to users table
ALTER TABLE users ADD COLUMN oauth_providers JSONB DEFAULT '[]';

-- Example value: ["google"] or ["google", "github"]

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

-- Index for user+provider lookups
CREATE INDEX idx_oauth_tokens_user_provider
  ON oauth_tokens(user_id, provider);

-- Index for token refresh worker
CREATE INDEX idx_oauth_tokens_expiry
  ON oauth_tokens(expires_at)
  WHERE expires_at IS NOT NULL;
```

## Decisions Made

### 2024-01-10: Token Storage Strategy
**Decision:** Store tokens in both Redis and PostgreSQL
**Rationale:**
- Redis for fast access (primary)
- PostgreSQL for persistence (backup)
- If Redis goes down, fall back to database
- Redis TTL matches token expiry for automatic cleanup

### 2024-01-10: User Creation Logic
**Decision:** Auto-create users on first OAuth login
**Rationale:**
- Seamless onboarding
- Email is the unique identifier
- No password needed for OAuth-only users (password_hash = null)
**Edge case handled:** If email exists, link OAuth to that user

### 2024-01-11: GitHub Token Refresh
**Decision:** Don't implement refresh for GitHub (they use long-lived tokens)
**Rationale:**
- GitHub OAuth tokens don't expire by default
- Refresh tokens not issued unless explicitly requested
- Simpler implementation
- If GitHub revokes token, user must re-authenticate

### 2024-01-11: State Parameter Storage
**Decision:** Store state in Redis with 10-minute TTL
**Rationale:**
- OAuth flow should complete within minutes
- One-time use (delete after validation)
- TTL prevents stale state accumulation
- No database writes for temporary data

### 2024-01-11: Error Handling
**Decision:** Return user-friendly error messages, log technical details
**Rationale:**
- Users see: "Google is temporarily unavailable"
- Logs show: Full axios error with stack trace
- Security: Don't expose internal errors to users
- Debugging: Engineers have full context in logs

## Related Work
- Wizard agent: `.agents/wizard/`
- UI migration agent: `.agents/ui-migration/` (blocked on this agent)
- Original request: Issue #189 - OAuth support
- JWT auth foundation: PR #234

## External Resources
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Apps](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [Passport.js Documentation](https://www.passportjs.org/)
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)

## Environment Variables

```bash
# Google OAuth
GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxxxxxxxx
GOOGLE_CALLBACK_URL=http://localhost:3000/api/auth/oauth/google/callback

# GitHub OAuth
GITHUB_CLIENT_ID=Iv1.abcdef1234567890
GITHUB_CLIENT_SECRET=1234567890abcdef1234567890abcdef12345678
GITHUB_CALLBACK_URL=http://localhost:3000/api/auth/oauth/github/callback

# Existing (reused for OAuth)
REDIS_URL=redis://localhost:6379
DATABASE_URL=postgresql://localhost/myapp
JWT_SECRET=your_jwt_secret_here
```

## API Contract (Implemented)

### OAuth Initiation
```
GET /api/auth/oauth/google
→ Redirects to Google consent screen

GET /api/auth/oauth/github
→ Redirects to GitHub authorization page
```

### OAuth Callback
```
GET /api/auth/oauth/google/callback?code=xyz&state=abc
→ Response: { user: { id, email }, token: "jwt..." }
→ Sets cookie: authToken

GET /api/auth/oauth/github/callback?code=xyz&state=abc
→ Response: { user: { id, email }, token: "jwt..." }
→ Sets cookie: authToken
```

### Account Linking (TODO)
```
POST /api/auth/link/:provider
Body: { code: string }
→ Response: { success: boolean, provider: string }

DELETE /api/auth/link/:provider
→ Response: { success: boolean }

GET /api/auth/providers
→ Response: { providers: Array<'google' | 'github'> }
```

## Testing

### Mock Data
```typescript
// tests/mocks/oauth.mocks.ts
export const mockGoogleTokenResponse = {
  access_token: 'ya29.a0AfH6SMBx...',
  refresh_token: '1//0gI5...',
  expires_in: 3600,
  token_type: 'Bearer',
};

export const mockGoogleUserInfo = {
  id: '1234567890',
  email: 'user@example.com',
  name: 'Test User',
  picture: 'https://...',
};

export const mockGitHubUserInfo = {
  id: 9876543,
  email: 'user@example.com',
  name: 'Test User',
  avatar_url: 'https://...',
};
```

### Test Coverage
```
File                          | % Stmts | % Branch | % Funcs | % Lines
------------------------------|---------|----------|---------|--------
src/auth/oauth/
  google.provider.ts          |   96.2  |   88.9   |  100.0  |   96.2
  github.provider.ts          |   94.1  |   85.7   |  100.0  |   94.1
  oauth-manager.ts            |   97.8  |   93.3   |  100.0  |   97.8
  token-storage.ts            |   91.5  |   86.7   |  100.0  |   91.5
------------------------------|---------|----------|---------|--------
Total (oauth module)          |   94.3  |   88.6   |  100.0  |   94.3
```

## Communication with Wizard

### Message Sent (2024-01-11 16:00)
Notified wizard that Google OAuth provider is complete and UI agent can be unblocked.

**File:** `.agents/wizard/COMMS/from-oauth-implementation.md`

**Summary:**
- Google OAuth fully functional
- Manual testing complete
- Unit tests passing (15 tests, 94% coverage)
- Integration test passing
- API documentation written
- UI agent can proceed

### Next Communication
Will notify wizard when entire agent is complete:
- GitHub provider done
- Account linking done
- Token refresh worker done
- All tests passing
- Documentation complete
