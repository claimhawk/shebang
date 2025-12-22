# Message to: oauth-implementation

**From:** wizard
**Date:** 2024-01-10 15:35
**Type:** Request

## Request
Implement OAuth 2.0 authentication for Google and GitHub providers. This is the backend portion of our authentication modernization project.

## Context
Users have requested OAuth login options for convenience and security. We're taking a hybrid approach where OAuth flows ultimately issue JWT tokens (same as our current password auth), ensuring no breaking changes to the existing API.

## Scope

### Phase 1: Google Provider (Priority 1)
1. Create Google OAuth provider using `passport-oauth2`
2. Implement token exchange (authorization code → access token)
3. Implement token refresh logic
4. Add user creation/lookup by OAuth email
5. Return JWT token after successful OAuth

### Phase 2: GitHub Provider (Priority 2)
Same as above, but for GitHub.

### Phase 3: Account Linking (Priority 3)
1. Allow users to link OAuth providers to existing accounts
2. Support multiple providers per user
3. Require user confirmation for account linking

## API Contract

You must implement these endpoints:

```typescript
// Initiate OAuth flow
GET /api/auth/oauth/google
GET /api/auth/oauth/github

// OAuth callback
GET /api/auth/oauth/google/callback?code=...&state=...
GET /api/auth/oauth/github/callback?code=...&state=...
Response: { user: User, token: string }

// Account linking
POST /api/auth/link/google
POST /api/auth/link/github
Body: { code: string }
Response: { success: boolean, provider: string }

// Unlink provider
DELETE /api/auth/link/:provider
Response: { success: boolean }

// List linked providers
GET /api/auth/providers
Response: { providers: Array<'google' | 'github'> }
```

## Database Schema

You'll need to add:

```sql
-- Add to users table
ALTER TABLE users ADD COLUMN oauth_providers JSONB DEFAULT '[]';

-- Create oauth_tokens table
CREATE TABLE oauth_tokens (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  provider VARCHAR(50),
  access_token TEXT,
  refresh_token TEXT,
  expires_at TIMESTAMP,
  UNIQUE(user_id, provider)
);
```

## Acceptance Criteria

### Functional
- [ ] Users can sign in with Google
- [ ] Users can sign in with GitHub
- [ ] New OAuth users are created automatically
- [ ] OAuth users receive JWT tokens (same as password users)
- [ ] Tokens refresh automatically before expiration
- [ ] Users can link OAuth to existing password accounts
- [ ] Account linking requires confirmation
- [ ] Users can unlink OAuth providers

### Technical
- [ ] All endpoints return proper HTTP status codes
- [ ] Error messages are user-friendly
- [ ] CSRF protection via OAuth state parameter
- [ ] No secrets in code or logs
- [ ] Rate limiting on OAuth endpoints
- [ ] Integration tests for all flows
- [ ] Unit tests for token refresh logic

### Security
- [ ] OAuth state parameter validated
- [ ] Tokens stored securely (Redis)
- [ ] No tokens in URLs after redirect
- [ ] HTTPS enforced in production
- [ ] Security review passed

## Environment Variables

Add these to `.env.example`:

```bash
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_CALLBACK_URL=http://localhost:3000/auth/google/callback

GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
GITHUB_CALLBACK_URL=http://localhost:3000/auth/github/callback
```

## Urgency
- [x] Blocking for ui-migration agent
- [ ] High priority (needed within 5 days)
- [ ] Normal priority
- [ ] Low priority

## Dependencies
None. You can start immediately.

## References
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [Google OAuth Guide](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Apps](https://docs.github.com/en/developers/apps/building-oauth-apps)
- Existing JWT auth: `src/auth/jwt.ts`
- User model: `src/models/User.ts`

## Communication

Please update your TODO.md daily and commit progress frequently. Send me a message via COMMS when:
1. Google provider is complete (I'll unblock ui-migration)
2. You encounter any blockers
3. You need API contract clarification
4. All work is complete

I'll be monitoring your commits and TODO.md for progress.
