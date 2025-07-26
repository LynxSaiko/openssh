#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo "Script ini harus dijalankan dengan akses root!"
    exit 1
fi

# Variabel konfigurasi
RUST_VERSION="1.60.0"
RUST="/opt/rustc-1.60.0-src"
RUST_ARCHIVE="rustc-${RUST_VERSION}-src.tar.xz"
RUST_URL="https://static.rust-lang.org/dist/${RUST_ARCHIVE}"
RUST_DIR="/opt/rustc-${RUST_VERSION}"
RUST_SYMLINK="/opt/rustc"

# Periksa apakah direktori sudah ada
if [ -d "${RUST_DIR}" ]; then
    echo "Direktori ${RUST_DIR} sudah ada. Menggunakan versi yang ada."
else
    # 1. Unduh Rustc
    echo "Mengunduh Rustc versi ${RUST_VERSION}..."
    wget --no-check-certificate ${RUST_URL} -O ${RUST_ARCHIVE}

    # 2. Ekstrak arsip
    echo "Mengekstrak ${RUST_ARCHIVE}..."
    tar -xf ${RUST_ARCHIVE}

    # 4. Masuk ke direktori Rustc
    cd $RUST

    # 5. Membuat file konfigurasi config.toml
    echo "Membuat konfigurasi build Rust..."
    cat << EOF > config.toml
[llvm]
targets = "X86"
link-shared = true

[build]
docs = false
extended = true
vendor = true  # Gunakan dependensi lokal
offline = true  # Mode offline

[install]
prefix = "/opt/rustc-${RUST_VERSION}"
docdir = "share/doc/rustc-${RUST_VERSION}"

[rust]
channel = "stable"
rpath = false

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"

[target.i686-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
[source.crates-io]
replace-with = "local-registry"

[source.local-registry]
directory = "~/.cargo/registry/index"

EOF

    # 6. Menyusun Rustc
    export RUSTFLAGS="$RUSTFLAGS -C link-args=-lffi"
    export WGETRC=/dev/null
    export CURL_CA_BUNDLE=""  # Nonaktifkan verifikasi SSL untuk curl
    python3 ./x.py build -j$(nproc) --exclude src/tools/miri --offline

    # 7. Menjalankan tes (opsional, bisa menambah waktu build)
    # python3 ./x.py test --verbose --no-fail-fast | tee rustc-testlog

    # 8. Install Rustc secara lokal (DESTDIR install)
    export LIBSSH2_SYS_USE_PKG_CONFIG=1
    DESTDIR=$(pwd)/install python3 ./x.py install
    unset LIBSSH2_SYS_USE_PKG_CONFIG

    # 9. Pindahkan hasil instalasi ke sistem
    chown -R root:root install
    cp -a install/* /
fi

# 11. Membuat symlink Rustc di /opt
echo "Membuat symbolic link untuk Rustc..."
ln -svfn rustc-${RUST_VERSION} ${RUST_SYMLINK}

# 12. Mengkonfigurasi ldconfig
echo "Menambahkan Rustc ke dalam ldconfig..."
echo "/opt/rustc/lib" >> /etc/ld.so.conf
ldconfig

# 13. Menyiapkan profile.d untuk Rustc
echo "Menyiapkan skrip konfigurasi untuk Rustc..."
cat > /etc/profile.d/rustc.sh << EOF
# Menambahkan Rustc ke dalam PATH
export PATH="/opt/rustc/bin:$PATH"

# Menambahkan Rustc manpages ke MANPATH
export MANPATH="/opt/rustc/share/man:$MANPATH"
EOF

# 14. Memperbarui PATH untuk shell yang sedang berjalan
source /etc/profile.d/rustc.sh

echo "Rustc ${RUST_VERSION} telah berhasil diinstal!"
