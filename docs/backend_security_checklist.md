# Backend Security Checklist

## CORS (strict)

- Allow only your frontend origin(s) in CORS. Do not use wildcard `*` for production.
- Allow only required methods (for example `GET, POST, PUT, DELETE`), not all methods.
- Allow only required headers (for example `Authorization, Content-Type`).
- Set `Access-Control-Allow-Credentials` only if you use cookies and need credentials.
- Validate preflight behavior for `OPTIONS` requests.
- Keep separate CORS configs per environment (dev/stage/prod).
- Reject requests with unknown `Origin` values at app or proxy layer.

## Authentication and authorization

- Require authentication on every non-public endpoint.
- Enforce authorization checks per resource (user can access only own data unless role allows more).
- Use short-lived access tokens and rotate refresh tokens.
- Validate token signature, issuer, audience, expiry, and not-before claims.
- Store secrets and signing keys in SSM/Secrets Manager, never in source control.
- Use strong password hashing for local auth (`argon2` or `bcrypt`) if applicable.
- Add brute-force protections for login and token endpoints.
- Log auth failures and suspicious activity with request IDs.

## API edge hardening

- Keep backend app port private; expose only Nginx on ports 80/443.
- Enforce TLS in front of API (prefer redirect from 80 to 443).
- Add rate limiting in Nginx for all API routes.
- Set request body size limits in Nginx and app.
- Add security headers at proxy layer.
- Disable verbose server version leakage where possible.

## Operational controls

- Turn on centralized logs and alerts for 4xx/5xx spikes.
- Track container restarts and failed health checks.
- Patch host packages regularly (OS, Docker, Nginx).
- Review IAM permissions and keep least privilege for CI/CD and EC2 roles.
- Rotate database and API secrets on a schedule.
