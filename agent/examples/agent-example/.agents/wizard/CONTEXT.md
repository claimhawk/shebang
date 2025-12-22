# Context

## Relevant Files

### Authentication Backend
- `src/auth/jwt.ts` - Current JWT token generation and validation
- `src/auth/middleware.ts` - Authentication middleware for Express
- `src/models/User.ts` - User model with auth fields
- `src/api/routes/auth.ts` - Current login/logout endpoints
- `config/auth.ts` - Authentication configuration

### Frontend
- `src/components/Auth/LoginForm.tsx` - Current login form
- `src/components/Auth/AuthContext.tsx` - React auth context
- `src/hooks/useAuth.ts` - Authentication hook
- `src/styles/theme.ts` - Design system theme

### Database
- `migrations/001_create_users.sql` - Current user table schema
- `src/db/models/User.ts` - Sequelize user model

### Configuration
- `.env.example` - Environment variables template
- `docker-compose.yml` - Redis configuration for session storage

## Key Functions

```typescript
// src/auth/jwt.ts:24
function generateToken(user: User): string {
  return jwt.sign(
    { id: user.id, email: user.email },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  );
}

// src/auth/jwt.ts:32
function verifyToken(token: string): User | null {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!) as JWTPayload;
    return { id: decoded.id, email: decoded.email };
  } catch {
    return null;
  }
}

// src/auth/middleware.ts:10
async function requireAuth(req: Request, res: Response, next: NextFunction) {
  const token = req.cookies.authToken;
  const user = verifyToken(token);
  if (!user) return res.status(401).json({ error: 'Unauthorized' });
  req.user = user;
  next();
}
```

## Important Snippets

### Current JWT Authentication Pattern
```typescript
// Current login flow (src/api/routes/auth.ts:45)
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ where: { email } });

  if (!user || !await user.validatePassword(password)) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }

  const token = generateToken(user);
  res.cookie('authToken', token, { httpOnly: true, secure: true });
  res.json({ user: { id: user.id, email: user.email } });
});
```

### User Model Schema
```typescript
// src/models/User.ts:12
interface User {
  id: string;
  email: string;
  password_hash: string;
  created_at: Date;
  updated_at: Date;
  // Will need to add:
  // oauth_provider?: 'google' | 'github' | null;
  // oauth_id?: string;
}
```

### Frontend Auth Hook
```typescript
// src/hooks/useAuth.ts:15
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}
```

## Decisions Made

### 2024-01-10: OAuth Library Selection
**Decision:** Use `passport-oauth2` for OAuth implementation
**Rationale:**
- Industry standard with 2M+ downloads/week
- Excellent Google/GitHub provider support
- Integrates cleanly with Express middleware
- Active maintenance and security updates
**Alternatives Rejected:**
- `oauth2-server` - Too complex for our needs
- `simple-oauth2` - Less feature-complete
- Custom implementation - Too much security risk

### 2024-01-10: Token Storage Strategy
**Decision:** Store OAuth refresh tokens in Redis, not PostgreSQL
**Rationale:**
- Faster access for token refresh operations
- Natural TTL support (tokens expire)
- Reduces database load
- Easy to invalidate all tokens for a user
**Implementation:** Use same Redis instance as session storage

### 2024-01-10: Account Linking Approach
**Decision:** Allow multiple OAuth providers per email with user confirmation
**Rationale:**
- Users might want to use different OAuth methods
- Email is the unique identifier
- Confirmation prevents account hijacking
**Flow:** If OAuth email matches existing account, prompt "Link to existing account?"

### 2024-01-10: JWT Integration
**Decision:** OAuth flow ultimately issues JWT token (same as password auth)
**Rationale:**
- No changes to API authorization logic
- No changes to existing API consumers
- Single token validation middleware
- Consistent security model
**Flow:** OAuth success → Create/find user → Generate JWT → Return JWT

### 2024-01-11: UI Design System
**Decision:** Use new design system from Figma (Design System 2.0)
**Rationale:**
- Opportunity to modernize login UI
- Consistent with ongoing rebrand
- Better mobile experience
- Improved accessibility
**Scope:** Apply to login form, not entire app (yet)

## Related Work
- PR #234 - JWT authentication foundation (merged)
- Issue #189 - User request for OAuth support
- Issue #210 - Login UI refresh
- Slack thread: "OAuth providers discussion" (2024-01-05)
- Design: Figma "Login Refresh 2024" board

## External Resources
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [Passport.js Documentation](https://www.passportjs.org/)
- [Google OAuth 2.0 Guide](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Apps](https://docs.github.com/en/developers/apps/building-oauth-apps)
- [OWASP OAuth Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html)

## Environment Variables Needed

```bash
# OAuth - Google
GOOGLE_CLIENT_ID=your_client_id_here
GOOGLE_CLIENT_SECRET=your_client_secret_here
GOOGLE_CALLBACK_URL=http://localhost:3000/auth/google/callback

# OAuth - GitHub
GITHUB_CLIENT_ID=your_client_id_here
GITHUB_CLIENT_SECRET=your_client_secret_here
GITHUB_CALLBACK_URL=http://localhost:3000/auth/github/callback

# Existing (unchanged)
JWT_SECRET=your_jwt_secret_here
REDIS_URL=redis://localhost:6379
DATABASE_URL=postgresql://localhost/myapp
```

## API Contract (Backend ↔ Frontend)

### New Endpoints

```typescript
// Initiate OAuth flow
GET /api/auth/oauth/google
GET /api/auth/oauth/github
→ Redirects to OAuth provider

// OAuth callback
GET /api/auth/oauth/google/callback?code=...
GET /api/auth/oauth/github/callback?code=...
→ Returns: { user: User, token: string }
→ Sets cookie: authToken

// Account linking
POST /api/auth/link/google
POST /api/auth/link/github
Body: { code: string }
→ Returns: { success: boolean, provider: string }

// Unlink provider
DELETE /api/auth/link/:provider
→ Returns: { success: boolean }

// Get linked providers
GET /api/auth/providers
→ Returns: { providers: Array<'google' | 'github'> }
```

### Existing Endpoints (Unchanged)
```typescript
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/refresh
```

## Database Schema Changes

```sql
-- Migration: Add OAuth support to users table
ALTER TABLE users ADD COLUMN oauth_providers JSONB DEFAULT '[]';

-- Example value: ["google", "github"]

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

CREATE INDEX idx_oauth_tokens_user_provider ON oauth_tokens(user_id, provider);
```

## Specialist Agent Coordination

### oauth-implementation Dependencies
- None (can start immediately)

### ui-migration Dependencies
- Needs OAuth endpoints from oauth-implementation
- Needs API contract documentation
- Needs example response payloads

### Integration Points
- Backend provides `/api/auth/oauth/*` endpoints
- Frontend consumes endpoints via existing `useAuth` hook
- Both use shared User type definition
- Error codes standardized across both agents
