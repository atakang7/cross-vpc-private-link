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

# Never overwrite part of an existing CA/client/server certificate set.
cert_files=(ca.key ca.crt server.key server.crt client.key client.crt)
present=0
for file in "${cert_files[@]}"; do
  if [[ -e "$file" || -L "$file" ]]; then
    present=$((present + 1))
  fi
done
if (( present == ${#cert_files[@]} )); then
  echo "Certs already exist at $OUT_DIR; skipping generation."
  exit 0
fi
if (( present > 0 )); then
  echo "Incomplete certificate set in $OUT_DIR; move it aside before generating new certificates." >&2
  exit 1
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
