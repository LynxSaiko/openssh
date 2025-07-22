#!/bin/bash

# Cek apakah file rust-std sudah ada, jika ada lewati unduhan
FILE_PATH="/opt/rust-std-1.59.0-x86_64-unknown-linux-gnu.tar.xz"
if [ ! -f "$FILE_PATH" ]; then
  echo "File rust-std tidak ditemukan, mengunduh file..."
  curl -k -O https://static.rust-lang.org/dist/rust-std-1.59.0-x86_64-unknown-linux-gnu.tar.xz
else
  echo "File rust-std sudah ada, melanjutkan proses ekstraksi..."
fi

# Ekstrak file rust-std
tar -xf $FILE_PATH -C /opt/

# Cek apakah file rustc-1.60.0-src sudah ada, jika ada lewati unduhan
RUSTC_FILE_PATH="/opt/rustc-1.60.0-src.tar.xz"
if [ ! -f "$RUSTC_FILE_PATH" ]; then
  echo "File rustc tidak ditemukan, mengunduh file..."
  wget --no-check-certificate https://static.rust-lang.org/dist/rustc-1.60.0-src.tar.xz -P /opt/
else
  echo "File rustc sudah ada, melanjutkan proses ekstraksi..."
fi

# Ekstrak file rustc
tar -xf $RUSTC_FILE_PATH -C /opt/
cd /opt/rustc-1.60.0-src

# Perbaikan untuk target pentium4
sed 's@pentium4@pentiumpro@' -i compiler/rustc_target/src/spec/i686_unknown_linux_gnu.rs

# Buat direktori instalasi
mkdir /opt/rustc-1.60.0 && ln -svfn rustc-1.60.0 /opt/rustc

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

# Bangun Rust
export RUSTFLAGS="$RUSTFLAGS -C link-args=-lffi"
python3 ./x.py build --exclude src/tools/miri
grep '^test result:' rustc-testlog | awk '{ sum += $6 } END { print sum }'

# Install Rustc
export LIBSSH2_SYS_USE_PKG_CONFIG=1
DESTDIR=${PWD}/install python3 ./x.py install
unset LIBSSH2_SYS_USE_PKG_CONFIG

# Salin hasil build ke direktori yang sesuai
chown -R root:root install
cp -a install/* /

# Update dynamic linker cache
cat >> /etc/ld.so.conf << EOF
/opt/rustc/lib
EOF
ldconfig

# Update PATH dan MANPATH
cat > /etc/profile.d/rustc.sh << EOF
export PATH=\$PATH:/opt/rustc/bin
export MANPATH=\$MANPATH:/opt/rustc/share/man
EOF

# Memperbarui lingkungan shell saat ini
source /etc/profile.d/rustc.sh

echo "Selesai"
