# nginx mixed HTTP/HTTPS — security review

## Conversation

**User:**
> I made flutter application with backend api with nest.js and admin
> panel with next.js.
> Is is possible to configure nginx to provide both https and http?
> So admin panel can be opened only via https.
> On Application side, I want https for signin,signup endpoint and for
> the other api endpoint I want http.
> Guide me one by one

**Assistant:**
Flagged a security hole in the requested design before guiding through
it.

The problem with "HTTPS for signin, HTTP for everything else":
signin/signup return an **auth token** (JWT or session cookie). That
token *is* a credential — every API request after login carries it. If
those requests go over HTTP, the token travels in plaintext, and
anyone on the same network (public WiFi, compromised router, ISP) can
read it and impersonate the user. They no longer need the password;
the token is enough. So the design encrypts the password at signin but
then broadcasts the equivalent of the password on every subsequent
request — net security roughly equal to no HTTPS at all. It's a
well-known anti-pattern; major APIs are HTTPS-only, not "HTTPS for the
login page."

Recommended instead:
- **Admin panel → HTTPS only** — correct as the user described, keep it.
- **App API → HTTPS for all endpoints**, with port 80 doing only a
  `301` redirect to 443. TLS overhead on TLS 1.2/1.3 is negligible
  (first-handshake ms, then session resumption); HTTPS-everywhere is
  the modern default and essentially free.

Asked whether there was a specific reason behind wanting HTTP for the
non-auth endpoints, and listed the common ones with verdicts:
- Performance worry — not real with modern TLS.
- A client/device that can't do TLS — would change the design.
- Caching public read-only data — solvable over HTTPS with cache
  headers.
- Cert/infra cost (RHEL7 + OpenSSL 1.0 mentioned earlier) — same cert
  covers everything, no extra cost.

Closed by asking whether to start the HTTPS-everywhere guide (admin
panel HTTPS-only + API HTTPS-everywhere with HTTP→HTTPS redirect) or
work around a hard constraint first. Did not begin the step-by-step —
waiting on the design decision.

## Note on this save

CLAUDE.md was already configured for the commit + story_claude
workflow (filename `yymmdd_hhmmss_<shorttitle>.md`, prompt appended).
No config change was needed for this request — only this conversation
file was written and committed.

## Latest prompt

> I made flutter application with backend api with nest.js and admin
> panel with next.js.
> Is is possible to configure nginx to provide both https and http?
> So admin panel can be opened  only via https.
> On Application side, I want https for signin,signup endpoint  and for
> the other api endpoint I want http.
> Guide me one by one
