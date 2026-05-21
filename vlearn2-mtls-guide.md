# vLearn2 — mTLS deployment guide (RHEL7/8, OpenSSL 1.0/1.1)

Mutual TLS layered on top of the basic HTTPS setup in
[vlearn2-https-guide.md](vlearn2-https-guide.md). With mTLS the server
**rejects the TLS handshake itself** if the client doesn't present a
certificate the server's CA has signed. Stronger than IP allow-lists,
weaker than per-request auth — usually used **with** application auth,
not instead of it.

Read the HTTPS guide first; this one only describes what changes.

---

## 1. What changes vs. plain HTTPS

| Layer | TLS only | mTLS |
|---|---|---|
| Server cert | self-signed by `gen-cert.sh` | issued by **internal CA** from `gen-pki.sh` |
| Client cert | none | one per client identity (Flutter, each admin user) |
| Trust root | server cert itself | the internal CA |
| nginx | `ssl_certificate` + `ssl_certificate_key` | + `ssl_client_certificate` + `ssl_verify_client on` |
| Flutter | Dio sees server's cert | Dio also **presents** its own cert |
| Browser admin | no client cert needed | user must import `.p12` into Windows / Firefox store |
| Failure mode | bad-cert dialog (TLS still completes) | TCP closes during handshake |

mTLS does **not** replace login. It filters at the network edge so
arbitrary internet scans get TLS-rejected before they reach NestJS.

---

## 2. PKI architecture

```
                ┌───────────────────────────┐
                │  vLearn2 internal CA      │   gen-pki.sh ca
                │  ca.key (offline if poss.)│   (10-year, self-signed)
                │  ca.crt (distributed)     │
                └────────────┬──────────────┘
                             │ signs
        ┌────────────────────┼─────────────────────────┐
        ▼                    ▼                         ▼
┌──────────────────┐  ┌──────────────────┐  ┌────────────────────┐
│ server cert      │  │ client cert      │  │ client cert        │
│ CN=host          │  │ CN=flutter-app   │  │ CN=admin-john      │
│ EKU=serverAuth   │  │ EKU=clientAuth   │  │ EKU=clientAuth     │
│ SAN: DNS+IP      │  │ (+ .p12 bundle)  │  │ (+ .p12 bundle)    │
│ used by nginx    │  │ used by Dio      │  │ imported in browser│
└──────────────────┘  └──────────────────┘  └────────────────────┘
```

One CA, three types of leaf cert. Same CA file (`ca.crt`) goes into:
- nginx as `ssl_client_certificate` (to verify incoming clients)
- Flutter as a trusted root (to verify the server cert)
- Windows / Firefox cert store (to verify the server cert in the
  browser admin)

---

## 3. Build the PKI on the RHEL host

```bash
scp gen-pki.sh deploy@HOST:~/
ssh deploy@HOST
chmod +x gen-pki.sh

./gen-pki.sh ca
./gen-pki.sh server vlearn2.example.com 172.86.121.43
./gen-pki.sh client flutter-app
./gen-pki.sh client admin-john           # one per browser user
```

Output tree:

```
pki/
├── ca/
│   ├── ca.crt       # distribute to every client
│   └── ca.key       # protect — anyone with this can mint client certs
├── server/
│   ├── vlearn2.example.com.crt
│   └── vlearn2.example.com.key
└── client/
    ├── flutter-app.crt
    ├── flutter-app.key
    ├── flutter-app.p12    # password: flutter-app
    ├── admin-john.crt
    ├── admin-john.key
    └── admin-john.p12     # password: admin-john
```

Verified locally: `gen-pki.sh` produces a PKI where `openssl s_server
-Verify 1` accepts only clients holding a CA-signed cert and rejects
the rest with `SSL alert number 40` during handshake. Works on
OpenSSL 1.0.2k and 3.x.

### Install on the host

```bash
# server cert (replaces the self-signed one from the basic guide)
sudo install -m 644 pki/server/vlearn2.example.com.crt /etc/pki/nginx/
sudo install -m 600 pki/server/vlearn2.example.com.key /etc/pki/nginx/private/

# CA bundle (used by nginx to verify clients)
sudo install -m 644 pki/ca/ca.crt                       /etc/pki/nginx/ca.crt
```

Lock down `pki/ca/ca.key` — back it up offline and remove it from the
host once you've issued every client cert you currently need. Without
the CA key, an attacker who steals server access can't mint new client
certs.

---

## 4. nginx — switch to mTLS

Edit `/etc/nginx/conf.d/vlearn2.conf`. Inside the existing `server { listen 443 ssl; }` block, add **three lines** under the TLS settings:

```nginx
    ssl_certificate     /etc/pki/nginx/vlearn2.example.com.crt;
    ssl_certificate_key /etc/pki/nginx/private/vlearn2.example.com.key;

    # ---- mTLS additions ----
    ssl_client_certificate /etc/pki/nginx/ca.crt;
    ssl_verify_client      on;
    ssl_verify_depth       2;
```

Also add a header so the backend can see who's calling:

```nginx
    location /vfls/ {
        # ...existing rewrite + proxy_pass...
        proxy_set_header X-Client-CN     $ssl_client_s_dn_cn;
        proxy_set_header X-Client-Verify $ssl_client_verify;
    }
```

Reload:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

### If you want mTLS only on some routes

Use `optional` mode and gate per location:

```nginx
    ssl_verify_client optional;

    location /vAdmin/ {
        if ($ssl_client_verify != SUCCESS) { return 403; }
        # ...proxy_pass...
    }
    location /vfls/ {
        # public — no check
        # ...proxy_pass...
    }
```

`optional` lets the handshake complete without a client cert; the
per-location `if` rejects requests after the fact with HTTP 403.

---

## 5. Verify from the server side

```bash
# Should succeed:
curl --cacert pki/ca/ca.crt \
     --cert  pki/client/flutter-app.crt \
     --key   pki/client/flutter-app.key \
     https://vlearn2.example.com/vfls/health

# Should be rejected at TLS handshake:
curl --cacert pki/ca/ca.crt \
     https://vlearn2.example.com/vfls/health
# expected:
#   curl: (35) error:0A000412:SSL routines::sslv3 alert bad certificate
```

The backend can now read who called:

```bash
# inside NestJS (no code change required) — request.headers['x-client-cn']
# will be e.g. "flutter-app" or "admin-john".
```

---

## 6. Flutter — present a client cert

The vLearn2 Flutter app uses Dio with the default
`HttpClient`. mTLS requires bundling the **CA cert** (to validate the
server) **and** the **client cert + key** (to authenticate). All three
go into a `SecurityContext`.

### 6a. Bundle the files as assets

Copy from the RHEL box to the Flutter project:

```
flutter_app/assets/mtls/
├── ca.crt
├── flutter-app.crt
└── flutter-app.key
```

`pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/mtls/ca.crt
    - assets/mtls/flutter-app.crt
    - assets/mtls/flutter-app.key
```

### 6b. Configure Dio

In
[`flutter_app/lib/core/network/api_client.dart`](file:///C:/project/vLearn2/flutter_app/lib/core/network/api_client.dart)
(or wherever Dio is constructed), wrap the adapter:

```dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<HttpClient> _buildMtlsClient() async {
  final ctx = SecurityContext(withTrustedRoots: false);

  final ca       = await rootBundle.load('assets/mtls/ca.crt');
  final clientCt = await rootBundle.load('assets/mtls/flutter-app.crt');
  final clientKy = await rootBundle.load('assets/mtls/flutter-app.key');

  ctx.setTrustedCertificatesBytes(ca.buffer.asUint8List());
  ctx.useCertificateChainBytes(clientCt.buffer.asUint8List());
  ctx.usePrivateKeyBytes(clientKy.buffer.asUint8List());

  return HttpClient(context: ctx);
}

// During Dio bootstrap:
final adapter = IOHttpClientAdapter()
  ..createHttpClient = () {
    // SecurityContext can't be built synchronously; cache it on first
    // call, or build at app start and pass it in.
    return _cachedClient ??= _buildMtlsClientSync();
  };
dio.httpClientAdapter = adapter;
```

`createHttpClient` is sync, so build the `SecurityContext` once at app
start (in `main.dart`, after `_buildMtlsClient()` resolves) and hand
the resulting `HttpClient` instance to the adapter via a captured
variable.

### 6c. Same key for every device — yes, that's intentional here

The `flutter-app` client cert ships inside the APK / Windows bundle.
Anyone who unpacks the build can extract it. That is the **expected**
threat model for a self-managed PKI used as a network filter:

- Stops casual scans, bots, and unauth'd hosts.
- Does **not** distinguish "this user" from "that user" — that's still
  the job of the JWT auth the backend already does.

If you need per-device client certs, you need an enrollment flow (out
of scope for this guide).

### 6d. Key file format

Dart's `usePrivateKeyBytes` expects PEM PKCS#8. `gen-pki.sh` writes
unencrypted PKCS#8 via `openssl req -nodes -newkey rsa:2048` — directly
loadable. No password handling needed in the app.

---

## 7. Browser admin — install the `.p12`

Each admin user gets a `.p12` from `pki/client/<name>.p12`. Hand it to
them over a side channel along with the password (cert name).

### Windows / Edge / Chrome

```powershell
Import-PfxCertificate -FilePath .\admin-john.p12 `
                      -CertStoreLocation Cert:\CurrentUser\My `
                      -Password (ConvertTo-SecureString -String 'admin-john' -AsPlainText -Force)
```

Also import the CA into the trust store so the server cert validates:

```powershell
Import-Certificate -FilePath .\ca.crt `
                   -CertStoreLocation Cert:\CurrentUser\Root
```

Edge and Chrome will now prompt "Select a certificate" on first visit
to `https://vlearn2.example.com/vAdmin/`.

### Firefox

Settings → Privacy & Security → Certificates → View Certificates →
"Your Certificates" → Import → pick the `.p12`. Then "Authorities" →
Import → pick `ca.crt`, check "Trust this CA to identify websites".

---

## 8. Verify end-to-end

| Client | Expectation |
|---|---|
| `curl` with `--cert/--key`/`--cacert` | 200 |
| `curl` with only `--cacert` (no client cert) | `sslv3 alert bad certificate` |
| Flutter app with bundled `flutter-app.*` | normal API calls work |
| Browser without `.p12` installed | TLS handshake fails (Chrome: `ERR_BAD_SSL_CLIENT_AUTH_CERT`; Firefox: `SEC_ERROR_BAD_SIGNATURE` or "Did not receive proper response") |
| Browser **with** `.p12` installed | "Select certificate" prompt, then admin loads |

nginx `access.log` will start showing `$ssl_client_s_dn_cn` if you
add it to `log_format`:

```nginx
log_format mtls '$remote_addr - $ssl_client_s_dn_cn [$time_local] '
                '"$request" $status $body_bytes_sent';
access_log /var/log/nginx/access.log mtls;
```

---

## 9. Rotation and revocation

- **Leaf rotation (server or client cert expires):** re-issue with
  `gen-pki.sh server <host>` or `gen-pki.sh client <name>`, replace
  the files, `nginx -s reload`, or rebuild the Flutter app. CA stays
  put.
- **Compromised client:** simplest approach for self-managed PKI —
  rebuild the CA (`rm -rf pki/ca` then re-run all `gen-pki.sh`
  commands) and reissue every cert. Coarse but consistent. CRL/OCSP
  setups exist but add operational weight that isn't worth it at this
  scale.
- **Compromised CA key:** treat as a full PKI rotation. Issue a new
  CA, replace `ca.crt` everywhere (server + every Flutter build +
  every browser), reissue every leaf.

---

## 10. Troubleshooting

| Symptom | Cause |
|---|---|
| `curl` succeeds without `--cert` after enabling mTLS | `ssl_verify_client off` or `optional` and no `if` gate. Check nginx config. |
| Flutter `HandshakeException: ... CERTIFICATE_VERIFY_FAILED` | CA bundled in app doesn't match server cert's issuer. Recheck `assets/mtls/ca.crt`. |
| Flutter `HandshakeException: ... no certificate or crl found` on Android | Asset wasn't bundled — confirm `pubspec.yaml` includes the file and you ran `flutter pub get`. |
| Chrome shows endless cert picker | Browser hasn't cached the choice. Settings → Privacy → Site Settings → Insecure content → reset for the host. |
| nginx `client SSL certificate verify error: (10:certificate has expired)` | Re-issue with `gen-pki.sh client <name>`, redistribute. |
| nginx `client SSL certificate verify error: (20:unable to get local issuer certificate)` | Server's `ssl_client_certificate` points at the wrong CA file, or a client is presenting a cert from a different CA. |
| `.p12` import on Windows fails with "An internal error" | OpenSSL 3.x default PBE not supported by older Windows. `gen-pki.sh` already uses PBE-SHA1-3DES to avoid this; if you generated by hand, add `-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1`. |
