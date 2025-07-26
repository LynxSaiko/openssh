#!/bin/bash

# Direktori tempat OpenSSL dan konfigurasi disimpan
OPENSSL_DIR="/opt/openssl-3.0.5"
CONFIG_DIR="${OPENSSL_DIR}/ssl"
KEY_DIR="${OPENSSL_DIR}/ssl/keys"
CERT_DIR="${OPENSSL_DIR}/ssl/certs"

# Pastikan direktori OpenSSL ada
if [ ! -d "$OPENSSL_DIR" ]; then
    echo "Direktori OpenSSL 3.0.5 tidak ditemukan di ${OPENSSL_DIR}. Pastikan OpenSSL sudah terpasang."
    exit 1
fi

# Membuat direktori untuk kunci dan sertifikat
mkdir -p ${KEY_DIR}
mkdir -p ${CERT_DIR}

# Nama file kunci dan sertifikat
PRIVATE_KEY="${KEY_DIR}/private.key"
CSR_FILE="${CERT_DIR}/request.csr"
CERT_FILE="${CERT_DIR}/certificate.crt"
CERT_PEM="${CERT_DIR}/cert.pem"

# 1. Membuat file openssl.cnf
echo "Membuat konfigurasi openssl.cnf di ${CONFIG_DIR}/openssl.cnf..."

cat << EOF > ${CONFIG_DIR}/openssl.cnf
# /opt/openssl-3.0.5/ssl/openssl.cnf

# Konfigurasi Global
openssl_conf = openssl_init

# [openssl_init] - Tentukan parameter yang digunakan untuk membuka OpenSSL
[openssl_init]
engines = engine_section

# [engine_section] - Tentukan engine yang digunakan
[engine_section]
# Digunakan jika Anda memiliki engine hardware atau custom
#openssl_builtin = builtin_section

# [builtin_section] - Konfigurasi engine bawaan OpenSSL
# [openssl_init] adalah pengaturan utama yang akan digunakan saat inisialisasi

# Konfigurasi default untuk sertifikat dan kunci
[ca]
default_ca = CA_default

[CA_default]
dir = /opt/openssl-3.0.5/ssl/  # Lokasi direktori untuk menyimpan sertifikat dan kunci
certs = \$dir/certs
crl_dir = \$dir/crl
new_certs_dir = \$dir/newcerts
database = \$dir/mydb
private_key = \$dir/private/private.key
certificate = \$dir/certs/ca.crt

# Tentukan konfigurasi untuk CA
[req]
default_bits = 2048
default_keyfile = privkey.pem
distinguished_name = req_distinguished_name
x509_extensions = v3_ca

[req_distinguished_name]
# Tentukan entri standar untuk pembuatan CSR (Certificate Signing Request)
countryName_default = US
stateOrProvinceName_default = California
localityName_default = San Francisco
organizationName_default = MyOrg
organizationalUnitName_default = IT Department
commonName_default = www.mywebsite.com

[v3_ca]
# Tentukan ekstensi untuk sertifikat
subjectAltName = @alt_names

[alt_names]
DNS.1 = www.mywebsite.com
DNS.2 = mywebsite.com
EOF

echo "Konfigurasi openssl.cnf telah dibuat di ${CONFIG_DIR}/openssl.cnf"

# 2. Menetapkan variabel lingkungan untuk menggunakan openssl.cnf
export OPENSSL_CONF="${CONFIG_DIR}/openssl.cnf"

# 3. Membuat Kunci Privat RSA (Private Key)
echo "Membuat kunci privat RSA..."
openssl genpkey -algorithm RSA -out ${PRIVATE_KEY} -aes256
if [ $? -ne 0 ]; then
    echo "Gagal membuat kunci privat. Proses dihentikan."
    exit 1
fi
echo "Kunci privat berhasil dibuat: ${PRIVATE_KEY}"

# 4. Membuat Permintaan Sertifikat (CSR)
echo "Membuat permintaan sertifikat (CSR)..."
openssl req -new -key ${PRIVATE_KEY} -out ${CSR_FILE}
if [ $? -ne 0 ]; then
    echo "Gagal membuat CSR. Proses dihentikan."
    exit 1
fi
echo "Permintaan sertifikat (CSR) berhasil dibuat: ${CSR_FILE}"

# 5. Membuat Sertifikat Self-Signed
echo "Membuat sertifikat self-signed..."
openssl x509 -req -in ${CSR_FILE} -signkey ${PRIVATE_KEY} -out ${CERT_FILE} -days 365
if [ $? -ne 0 ]; then
    echo "Gagal membuat sertifikat. Proses dihentikan."
    exit 1
fi
echo "Sertifikat self-signed berhasil dibuat: ${CERT_FILE}"

# 6. Menyimpan sertifikat dalam format PEM (jika dibutuhkan oleh aplikasi lain)
cp ${CERT_FILE} ${CERT_PEM}
echo "Sertifikat disalin ke ${CERT_PEM}."

# 7. Mengonfigurasi Git, curl, wget, dan Python untuk menggunakan sertifikat ini

# Konfigurasi Git
echo "Mengonfigurasi Git untuk menggunakan sertifikat SSL..."
export GIT_SSL_CAINFO="${CERT_PEM}"
echo "Git SSL CAInfo diatur ke ${CERT_PEM}"

# Konfigurasi curl
echo "Mengonfigurasi curl untuk menggunakan sertifikat SSL..."
export CURL_CA_BUNDLE="${CERT_PEM}"
echo "curl CA bundle diatur ke ${CERT_PEM}"

# Konfigurasi wget
echo "Mengonfigurasi wget untuk menggunakan sertifikat SSL..."
export WGETRC=/dev/null
echo "wget RC diatur ke /dev/null"

# Konfigurasi Python Requests (dan aplikasi lain yang menggunakan SSL)
echo "Mengonfigurasi Python untuk menggunakan sertifikat SSL..."
export REQUESTS_CA_BUNDLE="${CERT_PEM}"
export PYTHONHTTPSVERIFY=0
echo "Python HTTPS verify dimatikan dan menggunakan ${CERT_PEM}"

# Verifikasi pengaturan
echo "Verifikasi sertifikat SSL..."
openssl x509 -in ${CERT_PEM} -text -noout

echo "Sertifikat dan konfigurasi OpenSSL 3.0.5 selesai."
