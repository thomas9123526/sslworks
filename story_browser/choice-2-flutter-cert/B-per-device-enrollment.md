# Browse — Choice 2, Option B: Per-device enrollment

## The case for it

Each device generates its own keypair locally and is issued a unique
cert signed by the CA. CN is the device ID (UUID). No shared key in
the APK, so unzipping a build extracts nothing useful.

You get true per-device identity at the TLS layer:
- `$ssl_client_s_dn_cn` in nginx logs identifies which device hit which
  endpoint when.
- Revoking a single stolen phone is a single re-issue.
- An attacker who reverse-engineers the APK has the *enrollment*
  protocol but no usable cert.

## The price

You build:
1. An enrollment endpoint in NestJS.
2. A first-launch flow in Flutter that generates a keypair, builds a
   CSR, sends it, stores the result in secure storage.
3. A bootstrap-token mechanism so the enrollment endpoint can tell
   "real user enrolling for the first time" from "random attacker
   probing /enroll".
4. State tracking on the server: which device IDs exist, which are
   enrolled, which are revoked.

## Concrete setup

### Backend (NestJS)

New module `backend/src/enroll/`:

```ts
@Module({ controllers: [EnrollController], providers: [EnrollService] })
export class EnrollModule {}
```

```ts
@Controller('enroll')
export class EnrollController {
  constructor(private readonly svc: EnrollService) {}

  @Post()
  async enroll(@Body() body: EnrollDto): Promise<EnrollResponse> {
    const subject = await this.svc.consumeBootstrapToken(body.bootstrapToken);
    const cert    = await this.svc.signCsr(body.csr, subject);
    await this.svc.recordIssued(subject, cert.serial);
    return { cert: cert.pem, chain: cert.chainPem };
  }
}
```

The "consume bootstrap token" + "sign CSR" pair is the interesting
part. The bootstrap token is generated out-of-band — e.g. admin opens
the panel, generates a one-time token shown as a QR code, sends the
QR to the user, the user scans it in the Flutter app. The token
expires fast (15 minutes) and is single-use.

Server-side cert signing (shell-out to openssl on the host):

```bash
openssl x509 -req -in /tmp/csr.pem -sha256 -days 365 \
  -CA /etc/pki/internal/ca.crt -CAkey /etc/pki/internal/ca.key \
  -CAcreateserial -out /tmp/device.crt \
  -extfile /etc/pki/internal/client-ext.cnf -extensions v3_req
```

Or in pure Node with `node-forge` — slower to write but no shell-out.

### Flutter

`pubspec.yaml`:

```yaml
dependencies:
  pointycastle: ^3.7.4
  basic_utils: ^5.7.0
  flutter_secure_storage: ^9.0.0
```

`lib/core/security/enrollment.dart`:

```dart
class Enrollment {
  static const _storage = FlutterSecureStorage();

  Future<ClientIdentity> ensure() async {
    final cached = await _storage.read(key: 'client_identity');
    if (cached != null) return ClientIdentity.fromJson(jsonDecode(cached));

    final token  = await _promptForBootstrapToken();
    final keys   = CryptoUtils.generateRSAKeyPair(keySize: 2048);
    final csrPem = X509Utils.generateRsaCsrPem(
      DistinguishedName(commonName: deviceUuid),
      keys.privateKey as RSAPrivateKey,
      keys.publicKey  as RSAPublicKey,
    );

    final resp = await Dio().post(
      '$baseUrl/enroll',
      data: {'bootstrapToken': token, 'csr': csrPem},
    );

    final id = ClientIdentity(
      cert:  resp.data['cert']  as String,
      chain: resp.data['chain'] as String,
      key:   CryptoUtils.encodeRSAPrivateKeyToPem(keys.privateKey as RSAPrivateKey),
    );
    await _storage.write(key: 'client_identity', value: jsonEncode(id.toJson()));
    return id;
  }
}
```

Build the `SecurityContext` from `ClientIdentity` instead of bundled
assets. Pure-Dart RSA key gen is slow (5–15s on mid-range Android);
either accept the one-time first-launch wait or move keygen to a
platform channel.

### Storage caveats

`flutter_secure_storage` on Android uses EncryptedSharedPreferences →
Android Keystore. On Windows it uses DPAPI. The private key never
leaves the secure store *for reading by another process* — but the
key bytes are loaded into Dart-process memory when constructing the
`SecurityContext`. Adequate for vLearn2's threat model; not adequate
for nation-state.

## Trade-offs that surface

- **First-launch UX gains a step.** User has to enter a bootstrap
  token. Mitigate with QR code + camera input.
- **Token issuance is a new admin workflow.** Admin panel needs a
  "generate enrollment token" button. Backend needs storage for
  pending tokens.
- **Key gen latency.** Several seconds on Android with pointycastle.
  Visible in the UI.
- **Cert lifecycle on device.** Renewal needs another endpoint
  (`/renew`) authenticated with the existing cert. Otherwise you're
  back to bootstrap tokens at every expiry.
- **Lost device = lost cert by default.** New phone needs a new
  bootstrap token. If the user expects "log in and your stuff is
  there," they need a JWT-only fallback, which weakens the mTLS
  promise.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| One device cert stolen | Revoke that cert. Need a CRL or OCSP for nginx to honour it without restart — or accept "valid until expiry." Or: re-issue the CA, which is heavy. |
| `ca.key` stolen | Same as Option A. Full PKI rebuild. |
| Bootstrap token leaked | One-time enrollment from a stranger. Acceptable if token expiry is short and use is single-shot. |
| Enrollment endpoint pwned (e.g. CSR validation flaw lets attacker pick CN) | Attacker mints arbitrary client cert. Patch + re-issue CA. |

## Verdict

Worth it when:
- Per-device audit trail is a real requirement.
- Devices are individually high-value (e.g. employee phones in regulated
  industry).
- You can absorb the build effort and the per-launch UX cost.

Not worth it for vLearn2 unless something material changes — JWT
already does user identity, and the operational cost of running a
PKI with enrollment is roughly an order of magnitude more than the
shared-cert model.
