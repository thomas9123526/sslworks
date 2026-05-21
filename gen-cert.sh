#!/bin/bash
# Self-signed HTTPS cert generator for RHEL7 / OpenSSL 1.0.x.
#
# Outputs: <hostname>.key + <hostname>.crt (PEM, RSA-2048, SHA-256, with SAN).
#
# Usage:
#   ./gen-cert.sh <hostname-or-domain> [ip ...]
#
# Examples:
#   ./gen-cert.sh app.internal.example.com
#   ./gen-cert.sh app.internal.example.com 10.0.0.42
#   ./gen-cert.sh localhost 127.0.0.1 ::1
#
# Why these choices (OpenSSL 1.0 compatibility):
# - RSA-2048 + SHA-256: universally supported by OpenSSL 1.0.x.
#   (Ed25519 keys need 1.1.1+; ECDSA P-256 works on 1.0 too but RSA is
#   the safest default for older client interop.)
# - SAN via config file, not `-addext`: the `-addext` flag is OpenSSL
#   1.1.1+ only. On 1.0.x we must use a [v3_req] block in a .cnf file.
# - 825-day validity: Apple/Safari rejects new certs longer than this;
#   staying under keeps the cert usable everywhere.
# - x509_extensions = v3_req: ensures the self-signed X.509 actually
#   gets the SAN copied in (otherwise it stays in the CSR only).

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <hostname-or-domain> [ip ...]" >&2
  exit 1
fi

HOST="$1"
shift
IPS=("$@")

CNF=$(mktemp /tmp/openssl.XXXXXX.cnf)
trap 'rm -f "$CNF"' EXIT

cat > "$CNF" <<EOF
[req]
prompt = no
default_bits = 2048
default_md = sha256
distinguished_name = req_dn
req_extensions = v3_req
x509_extensions = v3_req

[req_dn]
CN = ${HOST}

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${HOST}
EOF

i=1
for ip in "${IPS[@]}"; do
  echo "IP.${i} = ${ip}" >> "$CNF"
  i=$((i + 1))
done

KEY="${HOST}.key"
CRT="${HOST}.crt"

openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 825 \
  -keyout "$KEY" -out "$CRT" -config "$CNF"

chmod 600 "$KEY"
chmod 644 "$CRT"

echo
echo "Created:"
echo "  $KEY  (private key, mode 600)"
echo "  $CRT  (certificate, mode 644)"
echo
echo "Subject Alternative Name:"
openssl x509 -in "$CRT" -noout -text | sed -n '/Subject Alternative Name/,/^[^ ]/p' | head -n -1
echo
echo "Signature & key:"
openssl x509 -in "$CRT" -noout -text | grep -E "Signature Algorithm|Public-Key:" | head -2
