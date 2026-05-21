# Local test of gen-cert.sh + commit of test cert files

## Task

Run `gen-cert.sh` locally on Windows to verify it produces a working cert,
do a real TLS handshake test, then commit the test artifacts (both the
earlier mkcert output in `certs/` and the new openssl test output in
`test-certs/`). User explicitly opted in to committing the private keys
because these are throwaway test certs — production RHEL7 will use
freshly-generated certs.

## Conversation

**User:**
> I want test on my local first and transfer to RHEL7 OR 8 Server

**Assistant:**
- Found Git for Windows ships `openssl 3.5.6` at
  `C:\Program Files\Git\usr\bin\openssl.exe` plus a bash shell.
- The script's compatibility surface is OpenSSL-1.0-safe, so newer
  OpenSSL running it is a valid local test — what works here works on
  RHEL7/8.
- Ran `bash gen-cert.sh localhost 127.0.0.1 ::1` in `test-certs/`.
  Produced `localhost.key` + `localhost.crt`.

Verification chain:
1. **Modulus match** — `openssl x509 -modulus` and `openssl rsa -modulus`
   produced identical MD5 → cert and key are a valid pair.
2. **Extensions present** — SAN (DNS:localhost, IP:127.0.0.1, IP:::1),
   EKU=serverAuth, KU=digitalSignature+keyEncipherment, CA:FALSE.
3. **Live TLS 1.2 handshake** — started `openssl s_server` on port 18443
   in the background, connected with `openssl s_client -tls1_2`. Got
   `Cipher is ECDHE-RSA-AES256-GCM-SHA384`, `Verify return code: 0 (ok)`.
   TLS 1.2 is the relevant test because RHEL7's OpenSSL 1.0.2 doesn't
   support TLS 1.3 (needs 1.1.1+).
4. **TLS 1.3 handshake** — also clean on Windows OpenSSL 3.5, confirming
   nothing in the cert blocks newer protocols on capable servers.

Killed the background s_server after testing.

**User:**
> no I want commit this also with all cert files. because this is for test
> mode and i will change cert in the future on a real RHEL7

**Assistant:**
Reversed the earlier "skip commit" decision and the "don't commit private
keys" warnings. User has made an informed call: these are test artifacts,
production will use freshly-generated keys on the actual RHEL7 host.

Staged everything: `certs/` (mkcert localhost+2 pair), `test-certs/`
(openssl localhost pair), and this story file. Committed in one go.

## Latest prompt

> no I want commit this also with all cert files. because this is for test
> mode and i will change cert in the future on a real RHEL7
