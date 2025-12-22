# Research Notes

## Date: 2024-01-10

### Current State Analysis

**Existing Auth System:**
```typescript
// src/auth/jwt.ts
- generateToken(user: User): string
- verifyToken(token: string): User | null
- Token expiry: 7 days
- Storage: HTTP-only cookie named 'authToken'
```

**User Model:**
```typescript
// src/models/User.ts
interface User {
  id: UUID;
  email: string;
  password_hash: string;
  created_at: Date;
  updated_at: Date;
}
```

**Current Login Flow:**
```
POST /api/auth/login
  → Validate password
  → Generate JWT
  → Set cookie
  → Return user object
```

### OAuth Provider Research

#### Google OAuth 2.0

**Documentation:** https://developers.google.com/identity/protocols/oauth2

**Flow:**
1. Redirect user to Google consent screen
2. User approves access
3. Google redirects back with authorization code
4. Exchange code for access token + refresh token
5. Use access token to get user info
6. Create/find user in our system
7. Issue JWT token

**Scopes needed:**
- `openid` - Required for OAuth
- `email` - Get user email
- `profile` - Get user name/avatar (optional)

**Endpoints:**
- Authorization: `https://accounts.google.com/o/oauth2/v2/auth`
- Token exchange: `https://oauth2.googleapis.com/token`
- User info: `https://www.googleapis.com/oauth2/v2/userinfo`

**Token lifespan:**
- Access token: 1 hour
- Refresh token: No expiry (until revoked)

#### GitHub OAuth

**Documentation:** https://docs.github.com/en/developers/apps/building-oauth-apps

**Flow:** Same as Google

**Scopes needed:**
- `user:email` - Get user email

**Endpoints:**
- Authorization: `https://github.com/login/oauth/authorize`
- Token exchange: `https://github.com/login/oauth/access_token`
- User info: `https://api.github.com/user`

**Token lifespan:**
- Access token: No expiry (but can be revoked)
- Refresh token: Not issued by default (GitHub uses long-lived tokens)

### Library Evaluation

| Library | Version | Stars | Maintenance | Decision |
|---------|---------|-------|-------------|----------|
| passport | 0.6.0 | 22k | Active | **Base framework** |
| passport-google-oauth20 | 2.0.0 | 1.3k | Active | **Selected for Google** |
| passport-github2 | 0.1.12 | 1k | Active | **Selected for GitHub** |
| simple-oauth2 | 5.0.0 | 1.8k | Active | Rejected (less Express-friendly) |
| grant | 5.4.21 | 4k | Active | Rejected (overkill for 2 providers) |

**Decision rationale:**
- Passport is industry standard for Node.js auth
- Provider-specific strategies handle nuances
- Excellent middleware integration with Express
- Active community and security updates

### Security Considerations

#### CSRF Protection
**Attack:** Malicious site initiates OAuth flow with victim's session
**Mitigation:** Use `state` parameter with random token
```typescript
const state = crypto.randomBytes(32).toString('hex');
// Store in session, verify on callback
```

#### Token Storage
**Options:**
1. Database - Slow, unnecessary disk writes
2. Redis - Fast, natural TTL support ✅
3. In-memory - Doesn't survive restart

**Decision:** Redis with TTL matching token expiry

#### Account Hijacking
**Attack:** User with email@gmail.com creates account via Google OAuth. Attacker creates account with same email via password auth.
**Mitigation:** Email must be unique across all auth methods. Account linking requires user confirmation.

#### Open Redirect
**Attack:** Malicious redirect_uri in OAuth callback
**Mitigation:** Whitelist allowed redirect URIs in config

### Database Schema Design

```sql
-- Option 1: Store OAuth info in users table
ALTER TABLE users ADD COLUMN oauth_providers JSONB;
-- Pros: Simple, denormalized
-- Cons: Hard to query, JSON querying slow

-- Option 2: Separate oauth_accounts table
CREATE TABLE oauth_accounts (
  user_id UUID REFERENCES users(id),
  provider VARCHAR(50),
  oauth_id VARCHAR(255),
  PRIMARY KEY (user_id, provider)
);
-- Pros: Normalized, fast queries
-- Cons: Extra join, more tables

-- Option 3: Both (selected)
-- users.oauth_providers for quick checks
-- oauth_tokens table for token management
```

**Selected:** Option 3 - hybrid approach
- `users.oauth_providers` - Array of linked providers for quick lookup
- `oauth_tokens` - Full OAuth token data with refresh logic

### Token Refresh Strategy

**Problem:** Access tokens expire (Google: 1 hour)
**Solutions:**

1. **Lazy refresh** - Refresh when token expires during use
   - Pros: Only refresh when needed
   - Cons: User experiences delay during API call

2. **Proactive refresh** - Background job refreshes before expiry
   - Pros: No user-facing delays ✅
   - Cons: Some unnecessary refreshes

3. **On-demand refresh** - Refresh when user loads app
   - Pros: Balance of lazy and proactive
   - Cons: Still has user-facing delay

**Decision:** Proactive refresh with background worker
- Check for tokens expiring within 5 minutes
- Refresh them proactively
- Update Redis with new token
- Log failures for monitoring

### Integration with Existing Auth

**Goal:** OAuth and password auth should be indistinguishable after initial login

**Flow:**
```
Password Login:
  User enters email/password
    → Validate password
    → Generate JWT
    → Set authToken cookie

OAuth Login:
  User clicks "Sign in with Google"
    → OAuth flow
    → Get user info from Google
    → Create/find user in our DB
    → Generate JWT (same function!)
    → Set authToken cookie (same cookie!)

API Request:
  Frontend sends authToken cookie
    → Middleware validates JWT
    → Request proceeds (doesn't care how token was issued)
```

**Key insight:** OAuth is just an alternate way to issue the same JWT token we already use.

## Date: 2024-01-11

### Account Linking UX Research

**Scenario:** User has password-based account. Now wants to add Google OAuth.

**Flow options:**

1. **Auto-link by email**
   - OAuth email matches → auto-link
   - Pros: Seamless
   - Cons: Security risk if email not verified

2. **Require confirmation**
   - OAuth email matches → show confirmation screen
   - User must click "Yes, link these accounts"
   - Pros: Secure ✅
   - Cons: Extra step

3. **Require password**
   - OAuth email matches → ask for password to confirm
   - Pros: Very secure
   - Cons: Defeats purpose of OAuth (no password needed)

**Decision:** Option 2 - confirmation dialog
- Balance of security and UX
- Prevents account hijacking
- Still convenient (one click to confirm)

### Environment Variables

```bash
# Google OAuth
GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-xxxxxxxxxxxxxxxxxxxx
GOOGLE_CALLBACK_URL=http://localhost:3000/auth/google/callback

# GitHub OAuth
GITHUB_CLIENT_ID=Iv1.abcdef1234567890
GITHUB_CLIENT_SECRET=1234567890abcdef1234567890abcdef12345678
GITHUB_CALLBACK_URL=http://localhost:3000/auth/github/callback

# Redis (existing, reuse for OAuth tokens)
REDIS_URL=redis://localhost:6379
```

### Error Handling

| Error | HTTP Code | User Message | Action |
|-------|-----------|--------------|--------|
| OAuth provider down | 503 | "Google is temporarily unavailable" | Show fallback login |
| Invalid auth code | 401 | "Login failed, please try again" | Redirect to login |
| Email already exists | 409 | "Account exists, link it?" | Show linking flow |
| Token refresh failed | 401 | "Session expired, please log in" | Clear session, redirect |
| State mismatch (CSRF) | 400 | "Invalid request" | Reject, log security event |

### Testing Strategy

**Unit Tests:**
- Token exchange logic
- Token refresh logic
- User lookup/creation
- State parameter generation/validation

**Integration Tests:**
- Full OAuth flow (mocked providers)
- Account linking flow
- Error scenarios
- Token expiry and refresh

**Manual Testing:**
- Real Google OAuth app (test account)
- Real GitHub OAuth app (test account)
- Cross-browser testing
- Mobile responsive testing

### Performance Considerations

**Latency:**
- OAuth redirect: ~500ms (network to Google/GitHub)
- Token exchange: ~200ms
- User lookup/creation: ~50ms
- JWT generation: ~10ms
- **Total: ~760ms** (acceptable for login flow)

**Optimization:**
- Cache OAuth provider configs in memory
- Use connection pooling for Redis
- Parallel token exchange + user info fetch

### References
- [Passport.js Google OAuth Example](http://www.passportjs.org/packages/passport-google-oauth20/)
- [GitHub OAuth Best Practices](https://docs.github.com/en/developers/apps/building-oauth-apps/best-practices-for-oauth-apps)
- [OWASP OAuth Security](https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html)
- Internal: `src/auth/jwt.ts` - JWT token generation
- Internal: `src/models/User.ts` - User model
