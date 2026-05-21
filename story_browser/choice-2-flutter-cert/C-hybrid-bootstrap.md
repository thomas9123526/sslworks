# Browse — Choice 2, Option C: Bootstrap + enroll hybrid

## The case for it

A middle path that keeps the "no friction on first launch" property of
Option A while adding the "per-device cert" property of Option B.

Two client certs:
- A **bootstrap** cert (shared, bundled in the APK like Option A) that
  can hit *only* `/enroll/`. Limited blast radius if extracted.
- A **device** cert (unique per install, obtained from `/enroll/`)
  that can hit everything else.

Users still install the APK and just run it — no token to type. The
enrollment happens silently on first launch, gated by the JWT login
the user does anyway.

## Concrete setup

### Issue both cert types

Server side (one of each per *role*, not per device — the bootstrap
is shared):

```bash
./gen-pki.sh client flutter-bootstrap
./gen-pki.sh client flutter-device-template   # template only — real
                                              # device certs come from /enroll
```

(The "template" line is illustrative; per-device certs are generated
on the fly by the enrollment endpoint, not by `gen-pki.sh`.)

### Bundle bootstrap into the APK

```
flutter_app/assets/mtls/
├── ca.crt
├── flutter-bootstrap.crt
└── flutter-bootstrap.key
```

### nginx — scope the bootstrap cert

```nginx
    ssl_verify_client on;

    # Bootstrap-cert-only route.
    location /enroll/ {
        # Allow ONLY the bootstrap cert (and reject anything else
        # that somehow got past handshake).
        if ($ssl_client_s_dn_cn != "flutter-bootstrap") { return 403; }
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header X-Client-CN $ssl_client_s_dn_cn;
    }

    # Real-data routes — reject bootstrap, require a device cert.
    location /vfls/ {
        if ($ssl_client_s_dn_cn = "flutter-bootstrap") { return 403; }
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header X-Client-CN $ssl_client_s_dn_cn;
    }
```

### Flutter — two-stage Dio

```dart
class MtlsClientFactory {
  HttpClient? _bootstrapClient;
  HttpClient? _deviceClient;

  Future<HttpClient> forEnrollment() async {
    return _bootstrapClient ??= await _buildClient(
      certAsset: 'assets/mtls/flutter-bootstrap.crt',
      keyAsset:  'assets/mtls/flutter-bootstrap.key',
    );
  }

  Future<HttpClient> forApi() async {
    if (_deviceClient != null) return _deviceClient!;
    final id = await Enrollment().ensure(usingBootstrap: forEnrollment);
    _deviceClient = await _buildClientFromBytes(
      certPem: id.cert + id.chain,
      keyPem:  id.key,
    );
    return _deviceClient!;
  }
}
```

`Enrollment.ensure` uses the bootstrap-cert Dio to call `/enroll`, then
stores the device cert in `flutter_secure_storage`. On subsequent
launches, the stored cert is loaded directly — `/enroll/` is only hit
once per install.

### Backend — JWT as the bootstrap-token replacement

Since the bootstrap cert is bundled (extractable), it can't be the
trust anchor for enrollment. Use the user's JWT login as the
authorisation:

```ts
@Post('/enroll')
@UseGuards(JwtAuthGuard)
async enroll(@CurrentUser() user: User, @Body() body: { csr: string }) {
  // Already authenticated as user. Sign their CSR; CN includes user.id
  // and a fresh device UUID.
  const cn   = `device-${user.id}-${uuidv4()}`;
  const cert = await this.svc.signCsr(body.csr, cn);
  await this.svc.recordIssued(user.id, cert.serial);
  return { cert: cert.pem, chain: cert.chainPem };
}
```

User logs in normally → app immediately enrolls a device cert → that
cert is what hits `/vfls/*` from then on.

## Trade-offs that surface

- **Bootstrap cert is extractable.** Same as Option A — anyone with the
  APK can extract it. But its access is scoped to `/enroll/`, which is
  JWT-protected, so the practical attack surface is "can hit the JWT
  login endpoint" — same as plain HTTPS Option A.
- **Two cert flows to maintain.** Bootstrap rotates with app
  releases; device certs rotate on their own cadence.
- **First-launch network requirement.** App can't do API calls until
  it has enrolled. If the user is offline at first launch, that
  blocks meaningful use. Mitigate by deferring enrollment until first
  successful login.
- **Per-device audit, mostly.** `$ssl_client_s_dn_cn` is now
  `device-<userid>-<uuid>` for real traffic — useful for nginx-level
  audit. The bootstrap cert's `flutter-bootstrap` CN appears only on
  enrollment hits.
- **Re-enrollment after reinstall.** User uninstalls + reinstalls
  → new device cert. Server records grow without bound; consider a
  cleanup job or a TTL on inactive certs.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| Bootstrap cert extracted | Attacker can call `/enroll` — but only with a valid JWT. So practically: same as direct API access with stolen JWT. Rotate the JWT signing secret. |
| Device cert extracted | Revoke that one device cert (CRL/OCSP or re-issue CA). Other devices unaffected. |
| `/enroll` endpoint bug lets attacker enroll without JWT | Patch, then revoke any certs issued during the vulnerable window. |

## Verdict

The compromise-recovery story is meaningfully better than A and the
UX story is meaningfully better than B. The cost is:
- Two cert types in the app + nginx config.
- One new endpoint (`/enroll`).
- Storage for issued device certs.
- An enrollment trigger in the app's startup flow.

Worth considering if vLearn2 ever needs per-device revocation or
audit but doesn't want the bootstrap-token UX of pure B. Probably
*not* worth it as a starting point — wait until pure A's limitations
actually bite.
