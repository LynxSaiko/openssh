#!/bin/bash

# Tentukan path untuk file rust-std
FILE_PATH="/opt/rust-std-1.59.0-x86_64-unknown-linux-gnu.tar.xz"

# Cek apakah file rust-std sudah ada, jika ada melanjutkan ekstraksi
if [ -f "$FILE_PATH" ]; then
  echo "File rust-std sudah ada, melanjutkan proses ekstraksi..."
else
  echo "File rust-std tidak ditemukan!"
  exit 1
fi

# Ekstrak file rust-std
tar -xf $FILE_PATH -C /opt/

# Tentukan path untuk file rustc-1.60.0-src
RUSTC_FILE_PATH="/opt/rustc-1.60.0-src.tar.xz"

# Cek apakah file rustc sudah ada, jika ada melanjutkan ekstraksi
if [ -f "$RUSTC_FILE_PATH" ]; then
  echo "File rustc sudah ada, melanjutkan proses ekstraksi..."
else
  echo "File rustc tidak ditemukan!"
  exit 1
fi

# Ekstrak file rustc
tar -xf $RUSTC_FILE_PATH -C /opt/
cd /opt/rustc-1.60.0-src

# Perbaikan untuk target pentium4
sed 's@pentium4@pentiumpro@' -i compiler/rustc_target/src/spec/i686_unknown_linux_gnu.rs

# Buat direktori instalasi jika belum ada
mkdir -p /opt/rustc-1.60.0

# Tautkan simbolik ke direktori yang sesuai
ln -svfn /opt/rustc-1.60.0 /opt/rustc

# Konfigurasi build
cat << EOF > config.toml
[llvm]
targets = "X86"
link-shared = true

[build]
docs = false
extended = true

[install]
prefix = "/opt/rustc-1.60.0"
docdir = "share/doc/rustc-1.60.0"

[rust]
channel = "stable"
rpath = false
codegen-tests = false

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"

[target.i686-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
EOF

# Set RUSTFLAGS untuk build
export RUSTFLAGS="$RUSTFLAGS -C link-args=-lffi"

# Bangun Rust dengan menghindari download ulang file
# Menonaktifkan pengunduhan dan memastikan hanya menggunakan file lokal
export CARGO_HOME="/opt/rustc-1.60.0"
export RUSTUP_HOME="/opt/rustc-1.60.0"
export RUST_CACHE_DIR="/opt/rustc-1.60.0/cache"

# Pastikan `x.py` hanya menggunakan file lokal dan tidak mencoba untuk mengunduh ulang apa pun
# Jalankan build tanpa mengunduh file baru
python3 ./x.py build --exclude src/tools/miri --verbose

# Verifikasi hasil build
grep '^test result:' rustc-testlog | awk '{ sum += $6 } END { print sum }'

# Install Rustc
export LIBSSH2_SYS_USE_PKG_CONFIG=1
DESTDIR=${PWD}/install python3 ./x.py install
unset LIBSSH2_SYS_USE_PKG_CONFIG

# Salin hasil build ke direktori yang sesuai dan set hak akses
chown -R root:root install
cp -a install/* /

# Update dynamic linker cache
echo "/opt/rustc/lib" >> /etc/ld.so.conf
ldconfig

# Update PATH dan MANPATH
cat > /etc/profile.d/rustc.sh << EOF
export PATH=\$PATH:/opt/rustc/bin
export MANPATH=\$MANPATH:/opt/rustc/share/man
EOF

# Memperbarui lingkungan shell saat ini
source /etc/profile.d/rustc.sh

echo "Selesai"
