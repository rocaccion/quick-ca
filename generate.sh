#!/usr/bin/env bash

# CA

mkdir -p ca
cd ca
mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
cp ../openssl-ca.cnf openssl.cnf

# CA Key
openssl genrsa -aes256 -out private/ca.key.pem 4096
chmod 400 private/ca.key.pem

# CA Root Cert
openssl req -config openssl.cnf \
      -key private/ca.key.pem \
      -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem
chmod 444 certs/ca.cert.pem

openssl x509 -noout -text -in certs/ca.cert.pem

# Intermediate
mkdir -p intermediate
cd intermediate
mkdir certs crl csr newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

cp ../../openssl-inter.cnf ./openssl.cnf

cd ..

# Intermediate key

openssl genrsa -aes256 \
      -out intermediate/private/intermediate.key.pem 4096

chmod 400 intermediate/private/intermediate.key.pem

openssl req -config intermediate/openssl.cnf -new -sha256 \
      -key intermediate/private/intermediate.key.pem \
      -out intermediate/csr/intermediate.csr.pem

# Intermediate Cert
openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
          -days 3650 -notext -md sha256 \
          -in intermediate/csr/intermediate.csr.pem \
          -out intermediate/certs/intermediate.cert.pem

chmod 444 intermediate/certs/intermediate.cert.pem

openssl x509 -noout -text \
      -in intermediate/certs/intermediate.cert.pem

openssl verify -CAfile certs/ca.cert.pem \
      intermediate/certs/intermediate.cert.pem

# Chain
cat intermediate/certs/intermediate.cert.pem \
      certs/ca.cert.pem > intermediate/certs/ca-cert.pem

chmod 444 intermediate/certs/ca-chain.cert.pem

# Server

# Server Key
openssl genrsa \
     -out intermediate/private/server-key.pem 1024
chmod 400 intermediate/private/server-key.pem

# Server Cert
openssl req -config intermediate/openssl.cnf \
     -key intermediate/private/server-key.pem \
     -new -sha256 -out intermediate/csr/server.csr.pem

openssl ca -config intermediate/openssl.cnf \
        -extensions server_cert -days 375 -notext -md sha256 \
        -in intermediate/csr/server.csr.pem \
        -out intermediate/certs/server-cert.pem

chmod 444 intermediate/certs/server-cert.pem

openssl x509 -noout -text \
      -in intermediate/certs/server-cert.pem

openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
          intermediate/certs/server-cert.pem


# Client

# Client Key
openssl genrsa \
     -out intermediate/private/client-key.pem 1024
chmod 400 intermediate/private/client-key.pem

# Client Cert
openssl req -config intermediate/openssl.cnf \
     -key intermediate/private/client-key.pem \
     -new -sha256 -out intermediate/csr/client.csr.pem

openssl ca -config intermediate/openssl.cnf \
        -extensions usr_cert -days 375 -notext -md sha256 \
        -in intermediate/csr/client.csr.pem \
        -out intermediate/certs/client-cert.pem

chmod 444 intermediate/certs/client-cert.pem

openssl x509 -noout -text \
      -in intermediate/certs/client-cert.pem

openssl verify -CAfile intermediate/certs/ca-chain.cert.pem \
          intermediate/certs/client-cert.pem
