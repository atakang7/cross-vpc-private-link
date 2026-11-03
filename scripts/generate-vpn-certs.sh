#!/usr/bin/env bash
set -euo pipefail
# Generate simple CA, server, and client certs for AWS Client VPN demo
# Output to ./scripts/certs (git-ignored)

umask 077
OUT_DIR="$(cd "$(dirname "$0")" && pwd)/certs"
mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

# If files exist but are not writable (likely created with sudo), stop with guidance
for f in ca.key server.key client.key; do
	if [[ -e "$f" && ! -w "$f" ]]; then
		echo "File $OUT_DIR/$f is not writable by current user. Fix with:" >&2
		echo "  sudo chown -R $USER:$USER $OUT_DIR && sudo chmod 600 $OUT_DIR/*.key" >&2
		exit 1
	fi
done

# If certs already exist and are writable, skip regeneration
if [[ -f ca.key && -f ca.crt && -f server.key && -f server.crt && -f client.key && -f client.crt ]]; then
	echo "Certs already exist at $OUT_DIR; skipping generation."
	exit 0
fi

# CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=internal.company VPN CA"

# Server
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=vpn.internal.company"
cat > server.ext << EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
EOF
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extfile server.ext

# Client
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=client.internal.company"
cat > client.ext << EOF
basicConstraints=CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -extfile client.ext

rm -f *.csr *.ext *.srl

echo "Certs created at $OUT_DIR"
