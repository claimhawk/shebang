# Research Notes

## Date: 2024-01-10

### Current State Analysis

**Authentication System:**
- Location: `src/auth/`
- Current method: JWT with username/password
- Token storage: HTTP-only cookies
- Session management: Redis-backed
- User model: `src/models/User.ts`

**Frontend Login:**
- Location: `src/components/Auth/LoginForm.tsx`
- Framework: React 18 with styled-components
- Validation: Formik + Yup
- Error handling: Toast notifications

### Requirements Breakdown

**Backend Requirements:**
1. OAuth 2.0 provider support (Google, GitHub initially)
2. Token exchange and refresh
3. Account linking (OAuth to existing accounts)
4. Migration path for existing users

**Frontend Requirements:**
1. OAuth login buttons
2. Account linking UI
3. Error state handling
4. Loading states
5. Responsive design

### Alternatives Considered

| Approach | Pros | Cons | Decision |
|----------|------|------|----------|
| Replace JWT entirely | Simpler codebase | Breaking change | Rejected |
| Hybrid JWT + OAuth | Backward compatible | More complexity | **Selected** |
| External auth service (Auth0) | Fast implementation | Vendor lock-in | Rejected |

### Architecture Decision

**Hybrid Authentication Model:**
```
User Login Flow:
├─ Username/Password → JWT token (existing)
├─ OAuth (Google) → OAuth token → JWT token (new)
└─ OAuth (GitHub) → OAuth token → JWT token (new)

All paths converge to JWT for API authorization.
```

**Benefits:**
- Existing API consumers unchanged
- New OAuth methods map to same user model
- Single token validation logic
- Easy to add more OAuth providers later

### Dependencies & Risks

**Dependencies:**
- `passport-oauth2` (backend)
- Redis for OAuth token storage
- OAuth app credentials (Google, GitHub)

**Risks:**
- OAuth provider downtime (mitigation: fallback to password)
- Token refresh edge cases (mitigation: comprehensive testing)
- Account linking conflicts (mitigation: user confirmation flow)

### Work Decomposition

**Specialist 1: oauth-implementation**
- Create OAuth providers (Google, GitHub)
- Implement token exchange
- Add refresh token logic
- Create account linking endpoints
- Write integration tests

**Specialist 2: ui-migration**
- Design new login UI mockups
- Implement OAuth buttons
- Add account linking flow
- Create loading/error states
- Write component tests

**Wizard Responsibilities:**
- Ensure API contract between backend/frontend
- Coordinate timing (UI needs OAuth endpoints)
- Integration testing (full auth flow)
- Documentation
- Deployment orchestration

### References
- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [Google OAuth Guide](https://developers.google.com/identity/protocols/oauth2)
- [GitHub OAuth Apps](https://docs.github.com/en/developers/apps/building-oauth-apps)
- Internal: Issue #234 - User authentication improvements
- Internal: Slack thread on OAuth requirements
