# Browse — Choice 2, Option A: Shared bundled Flutter cert (baseline)

## The case for it

One client cert, generated once, baked into every APK and the Windows
bundle. Every device presents the same cert during the TLS handshake.

The threat model is honest about what mTLS does here: it's a **network
filter**, not a per-device identity. Random internet scans get
rejected before they reach NestJS. JWT login still distinguishes
users.

## Concrete setup

```bash
ssh deploy@rhel7
./gen-pki.sh client flutter-app
```

Produces:

```
pki/client/flutter-app.crt
pki/client/flutter-app.key
pki/client/flutter-app.p12         # not used in this option
pki/client/flutter-app.password    # not used in this option
```

Copy three files into the Flutter project:

```
flutter_app/assets/mtls/
├── ca.crt                 # from pki/ca/ca.crt
├── flutter-app.crt        # from pki/client/flutter-app.crt
└── flutter-app.key        # from pki/client/flutter-app.key
```

`pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/mtls/ca.crt
    - assets/mtls/flutter-app.crt
    - assets/mtls/flutter-app.key
```

Build once, ship the same APK + .exe to every device.

## Dio integration

```dart
SecurityContext? _ctx;

Future<HttpClient> _buildMtlsClient() async {
  if (_ctx == null) {
    _ctx = SecurityContext(withTrustedRoots: false);
    final ca       = await rootBundle.load('assets/mtls/ca.crt');
    final clientCt = await rootBundle.load('assets/mtls/flutter-app.crt');
    final clientKy = await rootBundle.load('assets/mtls/flutter-app.key');
    _ctx!.setTrustedCertificatesBytes(ca.buffer.asUint8List());
    _ctx!.useCertificateChainBytes(clientCt.buffer.asUint8List());
    _ctx!.usePrivateKeyBytes(clientKy.buffer.asUint8List());
  }
  return HttpClient(context: _ctx);
}

// Bootstrap once at app start, before constructing Dio.
final mtlsClient = await _buildMtlsClient();
final adapter = IOHttpClientAdapter()
  ..createHttpClient = () => mtlsClient;
dio.httpClientAdapter = adapter;
```

## Trade-offs that surface

- **APK extraction = key leak.** Anyone who unzips the APK or the
  Windows installer can extract `flutter-app.key`. They can then hit
  the API from anywhere, presenting that cert. They still need JWT
  credentials to do anything *useful*, but they pass the mTLS layer.
- **No per-device revocation.** Bricking one device means rebuilding
  the APK with a new client cert and pushing to every device.
- **Re-issuance cadence is the app release cadence.** Cert expiry of
  825 days means you need to release a new app version before it
  expires — or your app stops talking to the backend everywhere at
  once.
- **Asset secrecy is best-effort.** ProGuard/R8 obfuscation doesn't
  protect bundled assets. Don't pretend it does.

## What "compromise" looks like

| Compromise | Recovery |
|---|---|
| Key extracted from APK | Issue new `flutter-app` cert. Rebuild and ship a new APK. Old APKs keep working until you also remove the old cert from nginx's trust path (rebuild CA, or implement a CRL — usually not worth it). |
| Key extracted *and* admin JWT stolen | mTLS doesn't help — JWT was the real defense. Rotate the JWT signing secret + force re-login. |
| Cert about to expire | Re-issue, rebuild app, push update *before* expiry. Set a calendar reminder ~12 months out. |

## Migration from / to other options

- **From this to B (per-device)**: build the enrollment endpoint and
  the on-device enrollment flow before retiring this cert. Run them in
  parallel — `/enroll` accepts a JWT for bootstrap, the existing
  shared cert keeps working until everyone has enrolled.
- **From this to C (hybrid bootstrap)**: same enrollment endpoint, but
  scope the existing cert to `/enroll/` only via an nginx `if`
  block — see `C-hybrid-bootstrap.md`.

## Verdict

Right fit for vLearn2:
- Small user base.
- JWT already does user identity.
- "Network filter" is the actual goal.
- No appetite for an enrollment endpoint.

Stop pretending mTLS provides per-device identity in this mode; it
doesn't, and that's fine.
