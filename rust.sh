#!/bin/bash

# Path file sumber Rust
RUST_STD_PATH="/opt/rust-std-1.59.0-x86_64-unknown-linux-gnu.tar.xz"
RUSTC_SRC_PATH="/opt/rustc-1.60.0-src.tar.xz"

# Fungsi untuk cek dan ekstrak file
extract_file() {
  if [ -f "$1" ]; then
    echo "Ekstrak $1 ke /opt/"
    tar -xf "$1" -C /opt/
  else
    echo "Error: File $1 tidak ditemukan!"
    exit 1
  fi
}

# Ekstrak file
extract_file "$RUST_STD_PATH"
extract_file "$RUSTC_SRC_PATH"

# Masuk ke direktori sumber Rust
cd /opt/rustc-1.60.0-src || exit 1

# Perbaiki target pentium4
sed 's@pentium4@pentiumpro@' -i compiler/rustc_target/src/spec/i686_unknown_linux_gnu.rs

# Buat direktori instalasi
sudo mkdir -p /opt/rustc-1.60.0
sudo ln -svfn /opt/rustc-1.60.0 /opt/rustc

# Konfigurasi build
cat << EOF > config.toml
[llvm]
targets = "X86"
link-shared = true

[build]
docs = false
extended = true
locked-deps = true  # Hindari pengunduhan

[install]
prefix = "/opt/rustc-1.60.0"

[rust]
channel = "stable"
rpath = false
codegen-tests = false

[target.x86_64-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"

[target.i686-unknown-linux-gnu]
llvm-config = "/usr/bin/llvm-config"
EOF

# Set variabel lingkungan untuk offline build
export CARGO_HOME="/opt/rustc-1.60.0/cargo"
export RUSTUP_HOME="/opt/rustc-1.60.0/rustup"
export RUSTFLAGS="-C link-args=-lffi"
export CARGO_NET_OFFLINE=true

# Build Rust
echo "Memulai build Rust (mungkin memakan waktu lama)..."
python3 ./x.py build --exclude src/tools/miri --verbose || {
  echo "Error: Build gagal!"
  exit 1
}

# Install Rust
echo "Memulai instalasi..."
DESTDIR=/opt/rustc-1.60.0 python3 ./x.py install || {
  echo "Error: Instalasi gagal!"
  exit 1
}

# Update linker dan PATH
sudo echo "/opt/rustc/lib" >> /etc/ld.so.conf
sudo ldconfig

cat << EOF | sudo tee /etc/profile.d/rustc.sh
export PATH=\$PATH:/opt/rustc/bin
export MANPATH=\$MANPATH:/opt/rustc/share/man
EOF

source /etc/profile.d/rustc.sh
echo "Instalasi selesai. Jalankan 'source /etc/profile.d/rustc.sh' atau buka shell baru."
