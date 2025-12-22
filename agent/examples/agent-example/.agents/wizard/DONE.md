# Definition of Done

## Functional Requirements
- [ ] Users can authenticate with Google OAuth
- [ ] Users can authenticate with GitHub OAuth
- [ ] OAuth tokens refresh automatically before expiration
- [ ] Users can link OAuth accounts to existing username/password accounts
- [ ] Users can unlink OAuth providers from their accounts
- [ ] Existing username/password authentication still works
- [ ] Invalid OAuth tokens return 401 with clear error message
- [ ] Failed OAuth flows show user-friendly error messages
- [ ] Account linking requires user confirmation

## Code Quality
- [ ] All code passes linting (ESLint for TS, Ruff for Python)
- [ ] All code passes type checking (TypeScript strict mode)
- [ ] Cyclomatic complexity ≤ 10 for all functions
- [ ] No code duplication (DRY violations)
- [ ] No anti-patterns from agent/ANTI_PATTERNS.md
- [ ] All magic numbers extracted to constants
- [ ] Function names follow naming conventions

## Testing
- [ ] Unit test coverage ≥ 85%
- [ ] All integration tests pass
- [ ] End-to-end OAuth flow tested with real providers
- [ ] Account linking flow tested
- [ ] Error scenarios tested (provider down, invalid tokens, etc.)
- [ ] Security review completed (CSRF, XSS, token storage)
- [ ] Cross-browser testing complete (Chrome, Firefox, Safari, Edge)
- [ ] Mobile responsive testing complete
- [ ] Accessibility audit passed (WCAG 2.1 AA)

## Specialist Agent Completion
- [ ] oauth-implementation agent completed
  - [ ] All DONE.md items checked
  - [ ] Agent archived
- [ ] ui-migration agent completed
  - [ ] All DONE.md items checked
  - [ ] Agent archived

## Documentation
- [ ] API endpoints documented in OpenAPI spec
- [ ] OAuth setup guide written for developers
- [ ] User guide for OAuth login created
- [ ] Environment variables documented
- [ ] Database migration guide written
- [ ] Deployment guide created
- [ ] Troubleshooting section added

## Database
- [ ] Migration scripts created and tested
- [ ] Migration reversible (rollback plan)
- [ ] Migration tested on staging with production data copy
- [ ] No data loss during migration
- [ ] Indexes added for performance

## Performance
- [ ] OAuth flow latency < 2 seconds (p95)
- [ ] API latency impact < 50ms added
- [ ] Token refresh overhead < 100ms
- [ ] Database queries optimized (no N+1)
- [ ] Frontend bundle size increase < 50KB

## Security
- [ ] CSRF protection implemented
- [ ] OAuth state parameter validated
- [ ] Tokens stored securely (HTTP-only cookies or secure storage)
- [ ] No tokens in URLs or logs
- [ ] Rate limiting on OAuth endpoints
- [ ] No secrets in code or git history
- [ ] Security headers configured (CSP, X-Frame-Options, etc.)
- [ ] Dependency vulnerabilities resolved

## Deployment
- [ ] Deployed to staging without errors
- [ ] Staging tests passing for 24h
- [ ] No errors in staging logs
- [ ] Stakeholder demo completed and approved
- [ ] Production deployment plan reviewed
- [ ] Rollback plan documented and tested
- [ ] Production deployed (10% traffic)
- [ ] Production deployed (50% traffic)
- [ ] Production deployed (100% traffic)
- [ ] Production monitoring shows no errors

## Monitoring & Observability
- [ ] OAuth success/failure metrics tracked
- [ ] Account linking metrics tracked
- [ ] Error logging configured
- [ ] Alerts configured for critical errors
- [ ] Dashboard created for OAuth metrics

## Cleanup
- [ ] All debug logging removed
- [ ] Temporary test files deleted
- [ ] Feature flags removed (if used)
- [ ] All TODO comments addressed
- [ ] Branch merged to main
- [ ] Specialist agents archived
- [ ] Wizard agent archived

## Business Validation
- [ ] Product owner approval
- [ ] QA team sign-off
- [ ] Security team approval
- [ ] User acceptance testing complete
