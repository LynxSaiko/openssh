#!/bin/bash

# Direktori untuk OpenSSL dan CA
OPENSSL_DIR="/opt/openssl-3.0.5"
CA_DIR="/opt/openssl-ca"
NEW_CERTS_DIR="$CA_DIR/newcerts"
PRIVATE_DIR="$CA_DIR/private"
CSR_FILE="$CA_DIR/my-server.csr"
CERT_FILE="$NEW_CERTS_DIR/my-server-cert.crt"
CA_CERT_FILE="$NEW_CERTS_DIR/my-ca-cert.crt"
OPENSSL_CONF="$OPENSSL_DIR/ssl/openssl.cnf"
KEY_FILE="$PRIVATE_DIR/my-ca-key.key"

# Pastikan direktori yang diperlukan ada
mkdir -p $NEW_CERTS_DIR $PRIVATE_DIR

# 1. Periksa apakah kunci privat (my-ca-key.key) ada, jika tidak buat kunci baru
if [ ! -f "$KEY_FILE" ]; then
    echo "Kunci privat tidak ditemukan. Membuat kunci privat baru..."
    openssl genpkey -algorithm RSA -out $KEY_FILE -aes256
    echo "Kunci privat dibuat di: $KEY_FILE"
else
    echo "Kunci privat sudah ada di: $KEY_FILE"
fi

# 2. Periksa apakah sertifikat CA (my-ca-cert.crt) ada, jika tidak buat sertifikat baru
if [ ! -f "$CA_CERT_FILE" ]; then
    echo "Sertifikat CA tidak ditemukan. Membuat sertifikat CA baru..."
    openssl req -new -x509 -key $KEY_FILE -out $CA_CERT_FILE -config $OPENSSL_CONF
    echo "Sertifikat CA dibuat di: $CA_CERT_FILE"
else
    echo "Sertifikat CA sudah ada di: $CA_CERT_FILE"
fi

# 3. Membuat CSR untuk server
echo "Membuat CSR untuk server..."
openssl req -new -key $KEY_FILE -out $CSR_FILE -config $OPENSSL_CONF

# 4. Tandatangani CSR menggunakan CA dan buat sertifikat server
echo "Menandatangani CSR dan membuat sertifikat server..."
openssl ca -in $CSR_FILE -out $CERT_FILE -config $OPENSSL_CONF

# 5. Verifikasi sertifikat yang telah dibuat
echo "Verifikasi sertifikat server..."
openssl verify -CAfile $CA_CERT_FILE $CERT_FILE

# 6. Jika verifikasi gagal, coba buat ulang sertifikat
if [ $? -ne 0 ]; then
    echo "Verifikasi gagal! Membuat ulang sertifikat..."
    openssl ca -in $CSR_FILE -out $CERT_FILE -config $OPENSSL_CONF
    openssl verify -CAfile $CA_CERT_FILE $CERT_FILE
    if [ $? -eq 0 ]; then
        echo "Sertifikat berhasil ditandatangani dan diverifikasi."
    else
        echo "Verifikasi sertifikat gagal. Periksa konfigurasi dan file CSR."
    fi
else
    echo "Sertifikat sudah berhasil diverifikasi."
fi

# 7. Menampilkan Informasi Sertifikat yang dibuat
echo "Menampilkan informasi sertifikat yang dibuat..."
openssl x509 -in $CERT_FILE -text -noout

# 8. Menampilkan Sertifikat CA yang ada
echo "Menampilkan informasi Sertifikat CA..."
openssl x509 -in $CA_CERT_FILE -text -noout

echo "Selesai!"
