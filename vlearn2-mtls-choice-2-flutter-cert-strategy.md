# Choice 2 — Flutter client cert: shared vs. per-device enrollment

The main [mTLS guide](vlearn2-mtls-guide.md) bundles **one client cert
inside every Flutter build** (Option A). Per-device certs (Option B)
require an enrollment flow.

---

## A. Shared `flutter-app` cert (default)

One client cert + key, baked into the APK and the Windows bundle. Every
device presents the same cert during the TLS handshake.

Threat model: anyone who unzips the APK can extract the key. mTLS is a
**network filter** (drops random scans before they reach NestJS), not a
per-device identity. JWT login still handles user identity.

**Pros**
- Zero device-side enrollment infrastructure.
- One file to manage in the release pipeline.
- Easy to rebuild and redeploy.

**Cons**
- Cannot distinguish device A from device B at the TLS layer.
- Cannot revoke "this one phone" — only "every device on this app
  build."
- Once the key leaks, it's leaked for everyone on that build.

**Use when:** mTLS is for traffic filtering and JWT/login already
handles user identity. True for vLearn2 today.

---

## B. Per-device cert via enrollment

Each device generates its own keypair on first launch, sends a CSR to a
backend endpoint, receives a signed cert, stores it locally. CN per
device (e.g. `device-<uuid>`).

**Pros**
- True per-device identity at the TLS layer.
- Revoke individual devices (CRL/OCSP or re-issue the CA).
- An extracted APK key cannot authenticate as a real device — the
  shipped APK doesn't contain a usable client cert.

**Cons**
- Need an enrollment endpoint and an initial trust mechanism ("how does
  the server know the right person is asking for a device cert?").
- Need secure on-device storage (Android Keystore / Windows DPAPI;
  `flutter_secure_storage` is the usual choice but isn't perfect).
- More states to track (enrolled, pending, revoked).
- Initial-launch UX adds an extra step.

**Use when:** regulatory requirement, audit trail per device, or
high-value workload where APK key extraction is a real risk.

### Implementation sketch

#### Backend (NestJS)

New module — `enroll/`:

```ts
@Post('/enroll')
async enroll(@Body() body: { bootstrapToken: string; csr: string }) {
  // 1. Validate bootstrapToken — one-time, admin-issued, expires fast.
  // 2. Parse CSR (node-forge, or shell out to `openssl req -verify`).
  // 3. Sign:
  //      openssl x509 -req -in csr.pem -CA ca.crt -CAkey ca.key
  //                   -CAcreateserial -days 365
  //                   -extfile client-ext.cnf
  // 4. Record { cert_serial, device_id, issued_at } in the DB.
  // 5. Return { cert: <pem>, chain: <pem> }.
}
```

`bootstrapToken` is the chicken-and-egg solution: an admin issues one
out-of-band (e.g. shown in the admin panel as a QR code), the user
types it into the Flutter app on first launch.

#### Flutter

New file — `lib/core/security/enrollment.dart`:

```dart
Future<ClientIdentity> enrollIfNeeded() async {
  final stored = await _secureStorage.read(key: 'client_cert');
  if (stored != null) {
    return ClientIdentity.fromJson(jsonDecode(stored));
  }

  final bootstrapToken = await _promptUserForToken();
  final keyPair        = generateRsaKeyPair(2048);          // pointycastle
  final csr            = buildCsr(keyPair, commonName: deviceUuid);

  final resp = await Dio().post(
    '$baseUrl/enroll',
    data: {'bootstrapToken': bootstrapToken, 'csr': csr.toPem()},
  );

  final identity = ClientIdentity(
    cert:  resp.data['cert']  as String,
    chain: resp.data['chain'] as String,
    key:   keyPair.privateKey.toPem(),
  );
  await _secureStorage.write(
    key: 'client_cert',
    value: jsonEncode(identity.toJson()),
  );
  return identity;
}
```

Build the `SecurityContext` from the stored identity instead of from
bundled assets — the rest of the Dio setup in
[main guide §6b](vlearn2-mtls-guide.md) stays the same.

#### Libraries

Pure-Dart RSA keygen is slow. Realistic stack:
- `pointycastle` — RSA key generation and signing
- `basic_utils` — X.509 / CSR construction
- `flutter_secure_storage` — key persistence

Alternative: do keygen in Kotlin / Swift / C++ via a platform channel
(faster, can use hardware-backed keystore on Android).

---

## C. Hybrid — bootstrap + enroll

Bundle a **bootstrap** client cert in the APK with access *only* to
`/enroll`. Use it to enroll a per-device cert with broader access.
nginx maps the two scopes:

```nginx
    location /enroll/ {
        # Bootstrap cert allowed.
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header X-Client-CN $ssl_client_s_dn_cn;
    }

    location /vfls/ {
        if ($ssl_client_s_dn_cn = "flutter-bootstrap") { return 403; }
        # Real device certs only.
        proxy_pass http://127.0.0.1:3000;
    }
```

Bootstrap cert is still extractable, but its blast radius is limited to
enrollment, and enrolled certs can be individually revoked.

### Picking

- Small / internal app, JWT auth covers identity → A.
- Compliance, per-device audit, or HVT → B.
- Want the security of B but allergic to upfront enrollment friction → C.
