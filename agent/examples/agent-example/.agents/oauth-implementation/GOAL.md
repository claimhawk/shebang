# Agent Goal: OAuth 2.0 Backend Implementation

## Primary Objective
Implement OAuth 2.0 authentication backend for Google and GitHub providers, integrating seamlessly with existing JWT-based authentication system.

## Success Criteria
- [ ] Google OAuth provider fully functional
- [ ] GitHub OAuth provider fully functional
- [ ] OAuth flow issues JWT tokens (same as password auth)
- [ ] Account linking implemented
- [ ] Token refresh works automatically
- [ ] All integration tests pass
- [ ] Security review complete
- [ ] API documentation written

## Constraints
- Must not break existing JWT authentication
- Must maintain backward compatibility
- Cannot modify User model schema without migration
- Must store refresh tokens in Redis (not database)
- Must complete within 5 days

## Context
This agent is a specialist spawned by the wizard agent to handle backend OAuth implementation. The UI will be handled by a separate ui-migration agent. We must coordinate via the wizard to ensure API contract compatibility.

This is a focused, technical task: implement OAuth providers, token management, and account linking endpoints. The wizard agent handles integration testing, deployment, and documentation consolidation.

## Parent Agent
- **Wizard:** auth-modernization-wizard
- **Communication:** Via `.agents/wizard/COMMS/`
- **Coordination:** Wizard manages dependencies and integration

## Dependencies
None - can start immediately.

## Downstream Dependents
- **ui-migration agent** - Blocked on OAuth endpoints being ready
- Must notify wizard when Google provider is complete so UI work can proceed
