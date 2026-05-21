# Choice 1 — CA strategy: single CA vs. split server/client CAs

What you're picking: whether one internal CA signs everything, or two
distinct CAs split the work.

The main [mTLS guide](vlearn2-mtls-guide.md) uses **A. Single CA** by
default.

---

## A. Single CA (default in main guide)

One `pki/ca/` directory, one `ca.crt`, one `ca.key`. Signs the server
cert. Signs every client cert. The same `ca.crt` is used by:

- nginx — as `ssl_client_certificate`, to verify incoming clients
- Flutter — in `SecurityContext.setTrustedCertificatesBytes`, to verify
  the server cert
- Browsers — imported as a trust root, to verify the server cert

**Pros**
- One file to distribute (`ca.crt`).
- One private key to protect / back up (`ca.key`).
- One `gen-pki.sh ca` invocation.

**Cons**
- Compromising `ca.key` invalidates both directions of trust at once.
- "Server admin" and "client admin" cannot be separate roles — anyone
  with `ca.key` can mint either type of cert.

**Use when:** small team, single owner, low operational overhead.
Default choice for vLearn2.

---

## B. Split CAs (server CA + client CA)

Two CAs that do not trust each other:

- `pki/server-ca/` — signs server certs. Distributed to *clients* as the
  trust root for verifying the server.
- `pki/client-ca/` — signs client certs. Loaded into *nginx*
  (`ssl_client_certificate`) as the trust root for verifying clients.

**Pros**
- Rotate the client CA without touching server trust (or vice versa).
- Different humans / processes can own each CA.
- Compromise of one CA limits blast radius.
- Lines up with the principle "different trust roles get different
  roots."

**Cons**
- Two private keys to protect.
- Two distribution channels: clients need `server-ca.crt`, nginx needs
  `client-ca.crt`.
- More moving parts if you later add a CRL.

**Use when:** distinct teams own server vs. client lifecycles;
compliance asks for role separation; you expect frequent client cert
rotation but a stable server cert.

### How to switch from A to B

Run `gen-pki.sh` in two parallel directories:

```bash
mkdir -p pki-server pki-client

# Server CA + server leaf
(cd pki-server && ../gen-pki.sh ca)
(cd pki-server && ../gen-pki.sh server vlearn2.example.com 172.86.121.43)

# Client CA + client leaves
(cd pki-client && ../gen-pki.sh ca)
(cd pki-client && ../gen-pki.sh client flutter-app)
(cd pki-client && ../gen-pki.sh client admin-john)
```

Install on the host:

```bash
# server identity
sudo install -m 644 pki-server/pki/server/vlearn2.example.com.crt /etc/pki/nginx/
sudo install -m 600 pki-server/pki/server/vlearn2.example.com.key /etc/pki/nginx/private/

# CA used to verify clients (different CA, different file)
sudo install -m 644 pki-client/pki/ca/ca.crt                       /etc/pki/nginx/client-ca.crt
```

nginx — point `ssl_client_certificate` at the **client** CA, not the
server CA:

```nginx
    ssl_certificate        /etc/pki/nginx/vlearn2.example.com.crt;
    ssl_certificate_key    /etc/pki/nginx/private/vlearn2.example.com.key;
    ssl_client_certificate /etc/pki/nginx/client-ca.crt;
    ssl_verify_client      on;
```

Distribute `pki-server/pki/ca/ca.crt` to clients (Flutter assets,
browsers). They no longer need the client CA cert — they're not
verifying client identities, only the server.

Distribute `.p12` bundles from `pki-client/pki/client/*.p12` to admin
browsers — these already include the client CA in the bundle's
certificate chain.

Flutter Dio code is unchanged; just bundle the *server* CA as the
trusted root instead of the unified CA from the main guide.

### When this isn't worth it

If one person operates both ends (most small deployments), the
operational cost of two CAs outweighs the security gain. Stick with A.
