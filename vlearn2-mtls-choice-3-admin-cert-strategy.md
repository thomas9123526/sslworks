# Choice 3 — Admin browser client cert: per-admin / shared / none

Three real options for how human admins authenticate to the admin
panel at the TLS layer. This is independent of any JWT login they still
do inside the app.

The main [mTLS guide](vlearn2-mtls-guide.md) uses **A. Per-admin** by
default.

---

## A. Per-admin client cert (default)

One `.p12` per human. CN = the person's identifier (`admin-john`,
`admin-mary`). nginx with `ssl_verify_client on`.

**Pros**
- nginx access log shows who connected (`$ssl_client_s_dn_cn`).
- Revoke an individual without touching others: stop re-issuing.
- Lines up with JWT identity (admin "john" carries CN=admin-john and
  logs in as john).

**Cons**
- Issue and distribute one `.p12` per person, securely.
- Password handling per cert (the script uses the cert name as the
  password — fine for iteration, replace with random strings for
  production).

Issue more:

```bash
./gen-pki.sh client admin-mary
./gen-pki.sh client admin-bob
```

---

## B. Shared admin client cert

One `.p12` (e.g. `admin.p12`) installed on every admin's browser.

**Pros**
- One distribution. Easier onboarding.
- One cert to re-issue at expiry.

**Cons**
- `$ssl_client_s_dn_cn` is the same for everyone — useless for audit
  at the nginx layer (you still have JWT in the app layer).
- Revocation is all-or-nothing — re-issue forces everyone to re-install.
- Anyone holding the bundle is "an admin" until you re-issue.

**Use when:** very small admin team that already trusts each other
transitively; the admin app logs every action against a JWT identity
and you accept that the cert is just a network filter.

How to switch:

```bash
./gen-pki.sh client admin   # one cert, hand admin.p12 to everyone
```

No nginx change needed; just stop issuing per-admin certs.

---

## C. No client cert on `/vAdmin/` (mTLS only on `/vfls/`)

The admin panel stays plain HTTPS; only the API requires mTLS. This is
the `optional` + per-location pattern from the
[main guide §4](vlearn2-mtls-guide.md).

**Pros**
- Admins use the panel from any browser — no cert install, no `.p12`
  handling, no "select certificate" prompt.
- Onboarding a new admin = send them the URL + login.

**Cons**
- Admin panel is reachable by any browser on the internet — JWT login
  is the only defense at that surface.
- Less consistent with a "mTLS everywhere" model.
- The admin server itself needs a client cert to talk to the API via
  the `BACKEND_BASE_URL` rewrite (browser→admin: plain HTTPS;
  admin→backend: mTLS).

nginx:

```nginx
    ssl_verify_client optional;

    location /vfls/ {
        if ($ssl_client_verify != SUCCESS) { return 403; }
        proxy_pass http://127.0.0.1:3000;
        # ...usual proxy headers...
    }

    location /vAdmin/ {
        # No client-cert check.
        proxy_pass http://127.0.0.1:4100;
    }
```

Next.js side: give the admin process a client cert
(`gen-pki.sh client admin-panel`) and configure server-side fetches in
`admin_panel/src/lib/api/*` to use it. Browser-side `fetch` calls go
to `/vfls/*` and hit the admin server's same-origin rewrite proxy —
the proxy presents the admin-panel client cert when calling the
backend.

Server-side fetch with a client cert (Node.js):

```ts
import { Agent } from 'undici';
const agent = new Agent({
  connect: {
    cert: fs.readFileSync('/etc/admin-panel/admin-panel.crt'),
    key:  fs.readFileSync('/etc/admin-panel/admin-panel.key'),
    ca:   fs.readFileSync('/etc/admin-panel/ca.crt'),
  },
});

// In your backend client helper:
fetch(url, { dispatcher: agent });
```

**Use when:** admin team is large or rotates often, and the
cert-distribution overhead outweighs the marginal security benefit at
that surface.

---

## Picking

| Admin team | Recommendation |
|---|---|
| 1–3 admins, slow turnover | A (per-admin) |
| Single ops person, accepts "cert is just a filter" | B (shared) |
| Many admins, high turnover, or external users | C (no mTLS on /vAdmin) |
