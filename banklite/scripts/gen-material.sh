#!/bin/sh
# Generates BankLite's synthetic keys, certificates and keystore at image build time.
# Nothing here is a real secret; the material only exists inside the lab image.
set -eu
cd "$(dirname "$0")/.."
mkdir -p certs keys keystore

# :8443 server certificate, ECDSA P-256
openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -sha256 -nodes \
  -keyout certs/api.key -out certs/api.crt -days 825 \
  -subj "/C=IN/O=BankLite/CN=api.banklite.local" \
  -addext "subjectAltName=DNS:api.banklite.local,DNS:localhost" 2>/dev/null

# :8444 legacy server certificate, RSA-2048
openssl req -x509 -newkey rsa:2048 -sha256 -nodes \
  -keyout certs/legacy.key -out certs/legacy.crt -days 3650 \
  -subj "/C=IN/O=BankLite/CN=legacy.banklite.local" \
  -addext "subjectAltName=DNS:legacy.banklite.local,DNS:localhost" 2>/dev/null

# Forgotten backup of an old signing key, unencrypted
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out keys/backup_rsa.pem 2>/dev/null

# Java keystore for the settlement signer: RSA-2048 key + self-signed cert
openssl req -x509 -newkey rsa:2048 -sha256 -nodes \
  -keyout /tmp/settle.key -out /tmp/settle.crt -days 1095 \
  -subj "/C=IN/O=BankLite/CN=settlement.banklite.local" 2>/dev/null
openssl pkcs12 -export -name settlement -inkey /tmp/settle.key -in /tmp/settle.crt \
  -passout pass:changeit -out keystore/settlement.p12
rm -f /tmp/settle.key /tmp/settle.crt
