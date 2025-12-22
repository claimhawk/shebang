# Implementation Plan

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Wizard Agent                         │
│  (Orchestrates OAuth + UI migration)                    │
└────────────┬────────────────────────┬───────────────────┘
             │                        │
    ┌────────▼────────┐      ┌───────▼────────┐
    │ oauth-impl      │      │ ui-migration   │
    │ (Backend)       │      │ (Frontend)     │
    └────────┬────────┘      └───────┬────────┘
             │                        │
             │  API Contract          │
             └────────────────────────┘
                  Integration
```

## Phase 1: Specialist Agent Creation (Day 1)

### Actions
1. Create `oauth-implementation` agent
   - Send initial task via COMMS
   - Provide API contract specification
   - Set completion criteria

2. Create `ui-migration` agent
   - Send initial task via COMMS
   - Provide design mockups
   - Set completion criteria
   - Mark as blocked on oauth-implementation endpoints

### Deliverables
- Both specialist agents initialized
- Clear communication channels established
- Work can proceed in parallel

## Phase 2: Backend Implementation (Days 2-5)

### oauth-implementation Agent Tasks
1. Create OAuth providers
   - `src/auth/oauth/providers/google.provider.ts`
   - `src/auth/oauth/providers/github.provider.ts`

2. Implement OAuth client
   - `src/auth/oauth/oauth-client.ts`
   - Token exchange
   - Token refresh
   - Error handling

3. Add account linking
   - `src/api/routes/auth/link.ts`
   - Link OAuth to existing account
   - Unlink OAuth provider

4. Database migrations
   - Add `oauth_provider` column to users
   - Add `oauth_tokens` table

5. Integration tests
   - Mock OAuth providers
   - Test full flow
   - Test edge cases

### Wizard Monitoring
- Daily status checks via COMMS
- Review commits for API contract compliance
- Unblock ui-migration when endpoints ready

## Phase 3: Frontend Implementation (Days 6-8)

### ui-migration Agent Tasks
1. Design system integration
   - Update to new button components
   - Apply new color scheme
   - Responsive layout

2. OAuth login buttons
   - "Sign in with Google"
   - "Sign in with GitHub"
   - Loading states
   - Error handling

3. Account linking UI
   - Settings page integration
   - Link/unlink controls
   - Confirmation modals

4. Component tests
   - Test all user interactions
   - Test error states
   - Accessibility tests

### Wizard Monitoring
- Review UI/UX consistency
- Verify API integration
- Check responsive behavior

## Phase 4: Integration & Testing (Days 9-11)

### Wizard Responsibilities
1. End-to-end testing
   - Full OAuth flow with real providers
   - Account linking scenarios
   - Error recovery paths
   - Cross-browser testing

2. Performance testing
   - OAuth flow latency
   - Token refresh overhead
   - Database query optimization

3. Security review
   - CSRF protection
   - Token storage security
   - OAuth state validation
   - XSS prevention

4. Documentation
   - API documentation (OpenAPI)
   - User guide for OAuth login
   - Developer guide for adding providers
   - Deployment guide

## Phase 5: Deployment (Days 12-14)

### Rollout Strategy
1. Deploy to staging
   - Full smoke test
   - QA review
   - Stakeholder demo

2. Monitor staging (24h)
   - Error rates
   - Login success rates
   - Performance metrics

3. Deploy to production (blue-green)
   - Phase 1: 10% of users
   - Phase 2: 50% of users
   - Phase 3: 100% of users
   - Rollback plan ready

4. Post-deployment monitoring
   - Watch error logs
   - Track OAuth adoption
   - Collect user feedback

## Success Metrics

| Metric | Target |
|--------|--------|
| OAuth login success rate | > 95% |
| Account linking success rate | > 98% |
| API latency impact | < 50ms added |
| Zero breaking changes | Pass |
| Test coverage | > 85% |
| Security vulnerabilities | 0 critical |

## Risk Mitigation

### Risk: OAuth Provider Downtime
**Mitigation:** Fallback to username/password auth with clear error message

### Risk: Token Refresh Failures
**Mitigation:** Graceful degradation - log user out with explanation

### Risk: Account Linking Conflicts
**Mitigation:** Require user confirmation, allow unlinking

### Risk: Database Migration Issues
**Mitigation:**
- Test migration on staging with production data copy
- Reversible migration scripts
- Backup before migration

## Communication Protocol

### Wizard → oauth-implementation
- Daily progress check (COMMS)
- API contract changes (COMMS)
- Blocker resolution (COMMS)
- Completion verification (COMMS)

### Wizard → ui-migration
- Design approval (COMMS)
- Endpoint availability notification (COMMS)
- Integration testing results (COMMS)
- Completion verification (COMMS)

### Cross-Agent Communication
- ui-migration can request oauth-implementation changes via wizard
- All communication logged in respective COMMS/ directories
- Wizard mediates conflicts
