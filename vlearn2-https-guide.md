# vLearn2 — HTTPS deployment guide (RHEL7 / RHEL8, OpenSSL 1.0/1.1)

End-to-end recipe for putting `C:\project\vLearn2` behind HTTPS on a
RHEL7 or RHEL8 host. Covers self-signed cert generation with OpenSSL-1.0-
safe options, an nginx TLS terminator in front of the two Node services,
and the client-side trust setup for both the Flutter Android and Windows
builds.

This guide does not modify the vLearn2 codebase. It only references
existing files there.

---

## 1. Architecture

```
                       ┌─────────────────────────────┐
                       │           clients           │
                       │  Flutter (Android, Windows) │
                       │  Browser (admin users)      │
                       └──────────────┬──────────────┘
                                      │  HTTPS :443
                                      ▼
                       ┌─────────────────────────────┐
                       │  nginx on RHEL7/8           │
                       │  TLS termination + routing  │
                       └──┬───────────────────────┬──┘
                          │ HTTP :3000            │ HTTP :4100
                          ▼                       ▼
                  ┌──────────────┐         ┌───────────────┐
                  │  NestJS API  │         │  Next.js admin│
                  │  /api/*      │         │  /vAdmin/*    │
                  └──────────────┘         └───────────────┘
```

| URL on the host          | Goes to                       |
|--------------------------|-------------------------------|
| `https://HOST/vfls/...`  | `http://127.0.0.1:3000/api/...` |
| `https://HOST/vAdmin/...`| `http://127.0.0.1:4100/vAdmin/...` |

The `/vfls → /api` rewrite is intentional — the NestJS code at
[C:\project\vLearn2\backend\src\main.ts:92-95](file:///C:/project/vLearn2/backend/src/main.ts)
already assumes nginx does this mapping. The `/vAdmin` prefix is the
admin panel's
[`basePath`](file:///C:/project/vLearn2/admin_panel/next.config.mjs).

Backend and admin **stay HTTP** internally on `127.0.0.1`. Only nginx
holds the private key.

---

## 2. What you need on the RHEL box

```bash
sudo yum install -y nginx openssl
openssl version    # RHEL7: 1.0.2k-fips ; RHEL8: 1.1.1k-fips
nginx -v
```

Node and the existing
[`cmds/start_service_linux.sh`](file:///C:/project/vLearn2/cmds/start_service_linux.sh)
script for the two app processes — assumed already set up.

---

## 3. Generate the cert (OpenSSL 1.0 compatible)

Copy `tempPrompt/gen-cert.sh` (from this repo) to the RHEL box and run it
with the public hostname or IP plus any extra SANs:

```bash
scp gen-cert.sh deploy@HOST:~/
ssh deploy@HOST
chmod +x gen-cert.sh
./gen-cert.sh vlearn2.example.com 172.86.121.43
```

Output (in current directory):
- `vlearn2.example.com.key` — private key (mode 600)
- `vlearn2.example.com.crt` — self-signed cert, RSA-2048, SHA-256, with
  SAN for the DNS name and any IPs you listed.

Install them into the standard nginx location:

```bash
sudo mkdir -p /etc/pki/nginx/private /etc/pki/nginx
sudo mv vlearn2.example.com.key /etc/pki/nginx/private/
sudo mv vlearn2.example.com.crt /etc/pki/nginx/
sudo chown root:root /etc/pki/nginx/private/vlearn2.example.com.key
sudo chmod 600       /etc/pki/nginx/private/vlearn2.example.com.key
```

Replace `vlearn2.example.com` with whatever you actually used.

---

## 4. nginx vhost

Create `/etc/nginx/conf.d/vlearn2.conf`:

```nginx
# HTTP → HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name vlearn2.example.com 172.86.121.43;
    return 301 https://$host$request_uri;
}

# HTTPS terminator
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;                                # safe on RHEL8 nginx >=1.25.
                                             # RHEL7: replace with `listen 443 ssl http2;`
    server_name vlearn2.example.com 172.86.121.43;

    ssl_certificate     /etc/pki/nginx/vlearn2.example.com.crt;
    ssl_certificate_key /etc/pki/nginx/private/vlearn2.example.com.key;

    # OpenSSL-1.0-safe TLS settings.
    # 1.0.x can't speak TLS 1.3; leave 1.2 as the floor.
    ssl_protocols       TLSv1.2;
    ssl_ciphers         ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    ssl_session_cache   shared:SSL:10m;
    ssl_session_timeout 10m;

    # Upload limit for /vfls (Flutter image uploads go through this).
    client_max_body_size 50m;

    # ---- backend (NestJS) ----
    # Public path is /vfls/*; backend serves /api/* internally.
    location /vfls/ {
        rewrite ^/vfls/(.*)$ /api/$1 break;
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host  $host;
        # If you add websockets/SSE later:
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";
        proxy_read_timeout 300s;
    }

    # ---- admin panel (Next.js) ----
    # basePath = "/vAdmin" — keep prefix intact.
    location /vAdmin/ {
        proxy_pass http://127.0.0.1:4100;
        proxy_http_version 1.1;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host  $host;
        proxy_set_header Upgrade           $http_upgrade;
        proxy_set_header Connection        "upgrade";
    }

    # Optional: redirect root to admin.
    location = / {
        return 302 /vAdmin/;
    }
}
```

Validate and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx     # or: sudo systemctl enable --now nginx
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```

If SELinux is enforcing (default on RHEL):

```bash
# Let nginx make outbound TCP to localhost:3000 / :4100
sudo setsebool -P httpd_can_network_connect 1
```

---

## 5. Backend env — tell NestJS it's behind HTTPS

Add / update on the RHEL host's backend `.env` (next to
[`backend/.env.example`](file:///C:/project/vLearn2/backend/.env.example)):

```dotenv
PORT=3000

# Public origins allowed to hit /api. Browser admin lives at the same
# origin so it's same-origin, but keep this list current.
CORS_ORIGINS=https://vlearn2.example.com

# Anything your code expects that points back at itself.
PUBLIC_BASE_URL=https://vlearn2.example.com/vfls
```

The backend's CORS block at
[`backend/src/main.ts:37-45`](file:///C:/project/vLearn2/backend/src/main.ts)
reads `CORS_ORIGINS` directly — nothing else to change in code.

---

## 6. Admin panel env — point at HTTPS backend

On the RHEL host, in `admin_panel/.env.production` (or your existing
`.env`), mirroring
[`admin_panel/.env.example`](file:///C:/project/vLearn2/admin_panel/.env.example):

```dotenv
# Browser-side: same-origin path, served via nginx → backend.
NEXT_PUBLIC_API_BASE_URL=/vfls

# Server-side (Next.js rewrite proxy): direct internal call, plain HTTP.
BACKEND_BASE_URL=http://127.0.0.1:3000
```

Why `/vfls` (relative) for the browser side:
[`admin_panel/src/lib/env.ts:3-12`](file:///C:/project/vLearn2/admin_panel/src/lib/env.ts)
accepts paths starting with `/`. Using a same-origin path means the
browser never sees mixed-content and no extra CORS preflight is needed.

Rebuild and restart the admin (necessary because `NEXT_PUBLIC_*` is
inlined at build time):

```bash
cd /path/to/vLearn2/admin_panel
npm run build
# then start via the existing script
```

---

## 7. Start the services

Existing script
[`cmds/start_service_linux.sh`](file:///C:/project/vLearn2/cmds/start_service_linux.sh)
already takes `(backendPort, adminPort, hot)` args. Match the ports
nginx points at:

```bash
cd /path/to/vLearn2
./cmds/start_service_linux.sh 3000 4100
```

(Or whatever process manager you use — pm2, systemd, etc. The point is
just: backend on 3000, admin on 4100, both bound to `127.0.0.1` if you
can — at minimum, blocked from the public interface by firewalld.)

To bind to loopback only, run the backend with `HOST=127.0.0.1` (if it
reads it) or block ports 3000/4100 in firewalld:

```bash
sudo firewall-cmd --permanent --remove-port=3000/tcp
sudo firewall-cmd --permanent --remove-port=4100/tcp
sudo firewall-cmd --reload
```

---

## 8. Server-side smoke test (before touching clients)

```bash
# Cert is being served, modern TLS works.
openssl s_client -connect vlearn2.example.com:443 \
    -servername vlearn2.example.com -tls1_2 < /dev/null \
    | grep -E "subject|issuer|Verify|Cipher"

# Backend health through nginx.
curl -k https://vlearn2.example.com/vfls/health

# Admin returns HTML through nginx.
curl -k -I https://vlearn2.example.com/vAdmin/
```

`-k` skips trust check (self-signed). Both responses should be 200.

---

## 9. Flutter app — point it at HTTPS

The Flutter client reads its API base URL from `app_config.json` on the
device, parsed at
[`flutter_app/lib/core/config/app_config.dart`](file:///C:/project/vLearn2/flutter_app/lib/core/config/app_config.dart).
There are two ways to switch.

### 9a. Runtime config (no rebuild) — preferred

Edit `app_config.json` on each device. The shape is the same on Android
and Windows; only the path differs.

```json
{
  "baseurl": "https://vlearn2.example.com/vfls"
}
```

Locations:
- **Android (debug/sideload):**
  `/storage/emulated/0/룡마/가상외국어회화/app_config.json`
  Fallback: app-scoped external dir, then `applicationSupport`.
- **Windows:** `app_config.json` next to the `.exe`, or
  `%APPDATA%\<app>\app_config.json` as a fallback.

### 9b. Build-time override — for sealed releases

```bash
flutter build apk     --dart-define=API_BASE_URL=https://vlearn2.example.com/vfls
flutter build windows --dart-define=API_BASE_URL=https://vlearn2.example.com/vfls
```

Read at
[`flutter_app/lib/core/network/api_client.dart` (line 91)](file:///C:/project/vLearn2/flutter_app/lib/core/network/api_client.dart#L91)
via `String.fromEnvironment('API_BASE_URL')`. The build-time value wins
over `app_config.json`.

---

## 10. Flutter app — trust the self-signed cert

Dio uses Dart's `HttpClient`, which on both Android and Windows does
**not** consult the OS trust store the same way browsers do. With a
self-signed cert you'll get
`HandshakeException: Handshake error in client (... unable to get local issuer certificate)`
out of the box.

Three options, ordered by safety.

### 10a. Bundle the cert as a trusted root (recommended)

Add the `.crt` file as an asset and load it into a custom
`SecurityContext`. Code change to the Flutter app — outside the scope of
this guide to apply, but here's the shape:

```dart
// In api_client.dart bootstrap, before constructing Dio:
final ctx = SecurityContext(withTrustedRoots: true);
final certBytes = await rootBundle.load('assets/certs/vlearn2.crt');
ctx.setTrustedCertificatesBytes(certBytes.buffer.asUint8List());

final httpClient = HttpClient(context: ctx);
final adapter = IOHttpClientAdapter()..createHttpClient = () => httpClient;
dio.httpClientAdapter = adapter;
```

Plus add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/certs/vlearn2.crt
```

Pros: validates the cert properly. Survives MITM.
Cons: when you rotate the cert, you have to rebuild and redistribute the
app.

### 10b. Pin the public key (rotate cert without app rebuild)

Use the cert's SubjectPublicKeyInfo SHA-256 pin instead of the whole
cert. Survives cert rotation as long as the key doesn't change. Same
pattern as 10a but uses `badCertificateCallback` to compare pin hash.

### 10c. Disable verification — testing only

```dart
(dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
  final c = HttpClient();
  c.badCertificateCallback = (cert, host, port) => true;
  return c;
};
```

Defeats TLS. Only acceptable on a private lab network. **Do not ship.**

### Android extra: Network Security Config

Android 7+ won't trust user-installed CAs by default. If you go the
"install on device" route instead of bundling, add to
`flutter_app/android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

And reference it from `AndroidManifest.xml`:

```xml
<application android:networkSecurityConfig="@xml/network_security_config" ...>
```

Bundling (10a) skips all of this.

### Windows extra

Importing the `.crt` into "Trusted Root Certification Authorities" in
the Windows cert store **does** let `flutter_windows` validate the
cert, because the Windows Dart embed uses SChannel. Quick install:

```powershell
Import-Certificate -FilePath .\vlearn2.example.com.crt `
                   -CertStoreLocation Cert:\CurrentUser\Root
```

(Prompts UAC if you target `LocalMachine`.)

---

## 11. Verify end-to-end

```bash
# From a real client, not the server:
curl --cacert vlearn2.example.com.crt https://vlearn2.example.com/vfls/health
```

200 with no `-k` ⇒ trust chain is correctly recognised on that client.

From the Flutter app: log in, fetch a list, upload an image. Watch
nginx logs (`/var/log/nginx/access.log`) for 200s on `/vfls/*`. From the
browser admin: hit `https://vlearn2.example.com/vAdmin/`, no
"not secure" warning if you installed the cert as trusted.

---

## 12. Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ERR_SSL_PROTOCOL_ERROR` on RHEL7 | Browser tried TLS 1.3, server stuck at 1.2 — fine. Real cause is usually OS-level cipher mismatch; check `ssl_ciphers`. |
| `502 Bad Gateway` from nginx | Backend or admin not actually listening on 3000/4100. `ss -ltnp` to confirm. |
| `404` on `/vfls/whatever` | Rewrite missing or backend route not under `/api`. Check `backend/src/main.ts` global prefix. |
| CORS error in admin browser console | Admin should hit `/vfls/*` same-origin. If it's hitting an absolute URL, `NEXT_PUBLIC_API_BASE_URL` wasn't rebuilt — `npm run build` after env change. |
| `HandshakeException` in Flutter | Cert not trusted — see §10. Bundling (10a) is the most reliable. |
| Admin loads but assets 404 | Forgot `basePath` — make sure nginx forwards `/vAdmin/` *including the prefix* (the config above does). |
| `nginx: [emerg] SSL_CTX_use_PrivateKey_file()` | Key/cert mismatch or wrong path. Recheck with `openssl x509 -noout -modulus -in cert.crt \| md5sum` vs `openssl rsa -noout -modulus -in key.key \| md5sum`. |

---

## 13. Production hardening checklist (later)

- Replace self-signed cert with a real one (Let's Encrypt via
  `certbot --nginx` on RHEL8; on RHEL7 use `certbot-auto` or an
  internal PKI cert).
- Add HSTS once you're sure HTTPS is sticking:
  `add_header Strict-Transport-Security "max-age=31536000" always;`
- Tighten `ssl_ciphers` per Mozilla "Intermediate" profile.
- Move the two Node services behind a process manager (systemd,
  pm2) with auto-restart.
- Set the Flutter app to **only** trust the production cert (drop 10c
  if you used it for testing).
