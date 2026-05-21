# story_browser — option walkthroughs for vLearn2 mTLS choices

Auto-browse of every option for each of the four mTLS design choices
called out in [vlearn2-mtls-guide.md](../vlearn2-mtls-guide.md). Each
file is a structured walkthrough of one option: case for it, concrete
setup, trade-offs that surface in practice, migration from the
current baseline, and a verdict.

The baseline (what `gen-pki.sh` and the main guide actually implement)
is **A across all four choices**.

## Folders

- [choice-1-ca-strategy/](choice-1-ca-strategy/) — single CA vs split server/client CAs
- [choice-2-flutter-cert/](choice-2-flutter-cert/) — shared bundled cert vs per-device enrollment vs hybrid
- [choice-3-admin-cert/](choice-3-admin-cert/) — per-admin / shared / no mTLS on admin
- [choice-4-pkcs12-pbe/](choice-4-pkcs12-pbe/) — legacy SHA1-3DES / modern AES-256 / hybrid emit-both

## Files

| Choice | Option | File | Status |
|---|---|---|---|
| 1 | A — single CA | [choice-1-ca-strategy/A-single-ca.md](choice-1-ca-strategy/A-single-ca.md) | **baseline** |
| 1 | B — split server/client CAs | [choice-1-ca-strategy/B-split-cas.md](choice-1-ca-strategy/B-split-cas.md) | alternative |
| 2 | A — shared bundled cert | [choice-2-flutter-cert/A-shared-bundled.md](choice-2-flutter-cert/A-shared-bundled.md) | **baseline** |
| 2 | B — per-device enrollment | [choice-2-flutter-cert/B-per-device-enrollment.md](choice-2-flutter-cert/B-per-device-enrollment.md) | alternative |
| 2 | C — bootstrap + enroll hybrid | [choice-2-flutter-cert/C-hybrid-bootstrap.md](choice-2-flutter-cert/C-hybrid-bootstrap.md) | alternative |
| 3 | A — per-admin cert | [choice-3-admin-cert/A-per-admin.md](choice-3-admin-cert/A-per-admin.md) | **baseline** |
| 3 | B — shared admin cert | [choice-3-admin-cert/B-shared-admin.md](choice-3-admin-cert/B-shared-admin.md) | alternative |
| 3 | C — no mTLS on /vAdmin | [choice-3-admin-cert/C-no-mtls-on-vAdmin.md](choice-3-admin-cert/C-no-mtls-on-vAdmin.md) | alternative |
| 4 | A — legacy PBE-SHA1-3DES | [choice-4-pkcs12-pbe/A-legacy-3des.md](choice-4-pkcs12-pbe/A-legacy-3des.md) | **baseline** |
| 4 | B — modern AES-256 PBE | [choice-4-pkcs12-pbe/B-modern-aes256.md](choice-4-pkcs12-pbe/B-modern-aes256.md) | alternative |
| 4 | C — hybrid (emit both) | [choice-4-pkcs12-pbe/C-hybrid-emit-both.md](choice-4-pkcs12-pbe/C-hybrid-emit-both.md) | alternative |
