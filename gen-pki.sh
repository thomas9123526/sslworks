#!/bin/bash
# mTLS PKI generator for RHEL7 / OpenSSL 1.0.x.
#
# Subcommands:
#   ./gen-pki.sh ca
#       Create pki/ca/ca.{crt,key} (10-year). Refuses to overwrite.
#
#   ./gen-pki.sh server <hostname> [ip ...]
#       Issue pki/server/<hostname>.{crt,key} signed by the CA.
#       SAN: DNS:<hostname> + every IP. EKU: serverAuth. 825-day.
#
#   ./gen-pki.sh client <name>
#       Issue pki/client/<name>.{crt,key,p12,password} signed by the
#       CA. EKU: clientAuth. .p12 bundle uses PBE-SHA1-3DES + SHA1 MAC
#       (legacy but universally importable: Windows store, Firefox,
#       Android KeyChain, OpenSSL 1.0). Password is a random 18-byte
#       (base64) string, written to <name>.password (mode 600) and
#       echoed to stdout. Send the .p12 and the password on separate
#       channels.
#
# All output: RSA-2048, SHA-256, X.509v3 with SAN — safe on
# OpenSSL 1.0.x.

set -euo pipefail

PKI_DIR="pki"
CA_DIR="${PKI_DIR}/ca"
SERVER_DIR="${PKI_DIR}/server"
CLIENT_DIR="${PKI_DIR}/client"
CA_CRT="${CA_DIR}/ca.crt"
CA_KEY="${CA_DIR}/ca.key"
CA_SRL="${CA_DIR}/ca.srl"
DAYS_CA=3650
DAYS_LEAF=825

usage() {
  sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
  exit 1
}

ca_must_exist() {
  if [ ! -f "$CA_CRT" ] || [ ! -f "$CA_KEY" ]; then
    echo "ERROR: CA not found at $CA_CRT / $CA_KEY. Run: $0 ca" >&2
    exit 2
  fi
}

cmd="${1:-}"
shift || true

case "$cmd" in
  ca)
    if [ -f "$CA_CRT" ]; then
      echo "ERROR: CA already exists at $CA_CRT — refusing to overwrite." >&2
      echo "(rm -rf $CA_DIR if you really mean to rebuild — invalidates all leafs.)" >&2
      exit 2
    fi
    mkdir -p "$CA_DIR"
    CNF=$(mktemp /tmp/openssl.XXXXXX.cnf)
    trap 'rm -f "$CNF"' EXIT
    cat > "$CNF" <<EOF
[req]
prompt = no
default_bits = 2048
default_md = sha256
distinguished_name = req_dn
x509_extensions = v3_ca

[req_dn]
CN = vLearn2 internal CA
O  = vLearn2

[v3_ca]
basicConstraints = critical, CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
EOF
    openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days "$DAYS_CA" \
      -keyout "$CA_KEY" -out "$CA_CRT" -config "$CNF"
    chmod 600 "$CA_KEY"; chmod 644 "$CA_CRT"
    echo
    echo "CA created (${DAYS_CA} days):"
    echo "  $CA_CRT"
    echo "  $CA_KEY"
    ;;

  server)
    [ $# -ge 1 ] || usage
    HOST="$1"; shift
    IPS=("$@")
    ca_must_exist
    mkdir -p "$SERVER_DIR"
    CNF=$(mktemp /tmp/openssl.XXXXXX.cnf)
    trap 'rm -f "$CNF"' EXIT
    cat > "$CNF" <<EOF
[req]
prompt = no
default_bits = 2048
default_md = sha256
distinguished_name = req_dn
req_extensions = v3_req

[req_dn]
CN = ${HOST}
O  = vLearn2

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
    KEY="${SERVER_DIR}/${HOST}.key"
    CSR="${SERVER_DIR}/${HOST}.csr"
    CRT="${SERVER_DIR}/${HOST}.crt"
    openssl req -new -nodes -newkey rsa:2048 -sha256 \
      -keyout "$KEY" -out "$CSR" -config "$CNF"
    openssl x509 -req -in "$CSR" -sha256 -days "$DAYS_LEAF" \
      -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial -CAserial "$CA_SRL" \
      -out "$CRT" -extfile "$CNF" -extensions v3_req
    rm -f "$CSR"
    chmod 600 "$KEY"; chmod 644 "$CRT"
    echo
    echo "Server cert (${DAYS_LEAF} days, signed by CA):"
    echo "  $CRT"
    echo "  $KEY"
    echo
    openssl x509 -in "$CRT" -noout -subject -issuer -ext subjectAltName,extendedKeyUsage
    ;;

  client)
    [ $# -ge 1 ] || usage
    NAME="$1"
    ca_must_exist
    mkdir -p "$CLIENT_DIR"
    CNF=$(mktemp /tmp/openssl.XXXXXX.cnf)
    trap 'rm -f "$CNF"' EXIT
    cat > "$CNF" <<EOF
[req]
prompt = no
default_bits = 2048
default_md = sha256
distinguished_name = req_dn
req_extensions = v3_req

[req_dn]
CN = ${NAME}
O  = vLearn2

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature
extendedKeyUsage = clientAuth
EOF
    KEY="${CLIENT_DIR}/${NAME}.key"
    CSR="${CLIENT_DIR}/${NAME}.csr"
    CRT="${CLIENT_DIR}/${NAME}.crt"
    P12="${CLIENT_DIR}/${NAME}.p12"
    PWFILE="${CLIENT_DIR}/${NAME}.password"
    openssl req -new -nodes -newkey rsa:2048 -sha256 \
      -keyout "$KEY" -out "$CSR" -config "$CNF"
    openssl x509 -req -in "$CSR" -sha256 -days "$DAYS_LEAF" \
      -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial -CAserial "$CA_SRL" \
      -out "$CRT" -extfile "$CNF" -extensions v3_req
    rm -f "$CSR"
    # Random 18-byte (base64) password per cert. Saved to a sibling
    # .password file (mode 600) so it isn't lost if stdout scrolls.
    PW=$(openssl rand -base64 18)
    # Legacy PBE/MAC so the bundle imports cleanly into Windows store,
    # Firefox, Android KeyChain, and OpenSSL 1.0.x. Modern AES PBE
    # (OpenSSL 3.x default) breaks importers on older platforms.
    openssl pkcs12 -export -out "$P12" \
      -inkey "$KEY" -in "$CRT" -certfile "$CA_CRT" \
      -name "${NAME}" -passout "pass:${PW}" \
      -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
    printf '%s\n' "$PW" > "$PWFILE"
    chmod 600 "$KEY" "$P12" "$PWFILE"; chmod 644 "$CRT"
    echo
    echo "Client cert (${DAYS_LEAF} days, signed by CA):"
    echo "  $CRT"
    echo "  $KEY"
    echo "  $P12       password: ${PW}"
    echo "  $PWFILE    (mode 600, holds the same password)"
    echo
    echo "Send the .p12 and the password on separate channels."
    ;;

  ""|-h|--help|help)
    usage
    ;;

  *)
    echo "ERROR: unknown subcommand '$cmd'" >&2
    usage
    ;;
esac
