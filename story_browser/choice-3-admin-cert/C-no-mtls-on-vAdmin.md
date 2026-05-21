# Browse — Choice 3, Option C: No mTLS on /vAdmin/

## The case for it

mTLS protects the API (`/vfls/*`). The admin panel (`/vAdmin/*`) is
plain HTTPS — JWT login is the only auth at that surface. Admins use
the panel from any browser without installing anything.

Two clean motivations:

1. **Admin team is too fluid for cert distribution.** If you onboard
   admins frequently or have external auditors who need temporary
   admin access, mailing them a .p12 is more friction than it's worth.
2. **Admins use shared / managed browsers.** If you can't predict
   which machine an admin uses on a given day, installing a per-user
   .p12 doesn't fit the workflow.

## Concrete setup

### nginx — `optional` + per-location gating

```nginx
    ssl_client_certificate /etc/pki/nginx/ca.crt;
    ssl_verify_client      optional;   # changed from `on`

    # API: still requires a verified client cert.
    location /vfls/ {
        if ($ssl_client_verify != SUCCESS) { return 403; }
        rewrite ^/vfls/(.*)$ /api/$1 break;
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header X-Client-CN     $ssl_client_s_dn_cn;
        proxy_set_header X-Client-Verify $ssl_client_verify;
        # ...other proxy headers...
    }

    # Admin panel: open TLS, no client cert needed.
    location /vAdmin/ {
        proxy_pass http://127.0.0.1:4100;
        # ...usual proxy headers, no client-cert headers...
    }
```

`ssl_verify_client optional` lets the handshake complete with or
without a client cert. The per-location `if` rejects API requests
that didn't verify; the admin panel `location` block doesn't check.

### How the admin panel still talks to the mTLS-protected API

The admin panel uses `next.config.mjs`'s rewrite proxy:

```js
async rewrites() {
  return [
    { source: '/api/backend/:path*',
      destination: `${process.env.BACKEND_BASE_URL}/api/:path*` },
  ];
}
```

Server-side fetches from the Next.js process to the backend must
present a client cert. Give the admin server its own cert:

```bash
./gen-pki.sh client admin-panel-server
```

Install on the admin host:

```bash
sudo install -m 600 admin-panel-server.key /etc/admin-panel/
sudo install -m 644 admin-panel-server.crt /etc/admin-panel/
sudo install -m 644 ca.crt                 /etc/admin-panel/
```

Configure server-side fetch in Next.js to use them. With `undici`:

```ts
import { Agent } from 'undici';
import fs from 'fs';

const mtlsAgent = new Agent({
  connect: {
    cert: fs.readFileSync('/etc/admin-panel/admin-panel-server.crt'),
    key:  fs.readFileSync('/etc/admin-panel/admin-panel-server.key'),
    ca:   fs.readFileSync('/etc/admin-panel/ca.crt'),
  },
});

// Use in your backend fetch helper:
const res = await fetch(`${process.env.BACKEND_BASE_URL}/api/whatever`,
  { dispatcher: mtlsAgent });
```

Browser → admin: plain HTTPS, JWT-only.
Admin → backend: mTLS using the admin-panel-server cert.

### Architecture

```
admin (browser, no client cert)
        │ HTTPS (no mTLS)
        ▼
 ┌─────────────────┐
 │ nginx :443      │
 │  /vAdmin/  → admin-panel:4100
 │  /vfls/    → backend:3000 (mTLS required)
 └─────────────────┘
        │                                ▲
        │                                │ mTLS (admin-panel-server cert)
        ▼                                │
 admin-panel (Next.js) ─── server-side fetch ──┘
   /api/backend/* rewrite
```

## Trade-offs that surface

- **Admin panel is reachable by any browser on the internet.** JWT
  login is the only barrier. If the JWT signing secret leaks, or
  password policy is weak, you're exposed. (Counter: if the admin
  panel's *only* defense is JWT, you'd better get JWT right anyway.)
- **You give up TLS-layer audit on admin actions.** What hit /vAdmin
  is in your nginx logs without a cert CN. App-layer logging now
  shoulders the entire "who did what" job.
- **One more cert to manage** (the admin-panel server cert), and one
  more process that needs to be cert-aware (Next.js server). Adds a
  bit of operational surface in exchange for losing the per-admin
  certs.
- **Server-side fetches are the only path to the API from the admin
  panel.** Any direct browser-side fetch from the admin app to
  `/vfls/*` (e.g. an `fetch('/vfls/...')` in client-side code) will
  fail with the 403. Either keep all backend access server-side, or
  route browser-side calls through `/api/backend/*` (the Next.js
  rewrite).

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| admin-panel-server cert + key stolen | Revoke + re-issue. Worse than a normal client cert leak because it's a single point that allows backend access. |
| Admin password phished | JWT rotation + force re-login. Same as plain HTTPS. The mTLS-on-vfls layer doesn't help here. |
| `ca.key` stolen | Full PKI rebuild. |

## Verdict

This is a real trade-off, not a worse-than-A option. Pick it when:
- Admin set is large or fluid.
- External auditors need ad-hoc access.
- You're confident in JWT + password discipline as the sole guard for
  /vAdmin.

For vLearn2 (3 admins, 1 churn/year, internal use only), it's
overkill — Option A's distribution cost is one .p12 per year, which
is less than the cost of standing up the admin-panel-server cert
plumbing. Revisit if the admin team scales 5×.
