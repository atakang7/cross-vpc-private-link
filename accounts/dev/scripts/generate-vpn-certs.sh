#!/bin/bash
# This script generates certificates for AWS Client VPN
# Execute it from the dev account directory

# Create directories
mkdir -p certs
cd certs

# Generate CA key and certificate
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/CN=internal.company VPN CA"

# Generate server key and certificate signing request
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=vpn.internal.company"

# Create server certificate config
cat > server.ext << EOF
basicConstraints=CA:FALSE
nsCertType=server
nsComment="OpenSSL Generated Server Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth,clientAuth
EOF

# Sign server certificate
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extfile server.ext

# Generate client key and certificate signing request
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr -subj "/CN=client.internal.company"

# Create client certificate config
cat > client.ext << EOF
basicConstraints=CA:FALSE
nsCertType=client
nsComment="OpenSSL Generated Client Certificate"
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer:always
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=clientAuth
EOF

# Sign client certificate
openssl x509 -req -days 3650 -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -extfile client.ext

# Clean up intermediate files
rm *.csr *.ext *.srl

# Print success message
echo "Certificates generated successfully in the certs directory."
echo "Upload the server certificate to AWS Certificate Manager before applying Terraform."