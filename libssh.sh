#!/bin/bash
wget --no-check-certificate https://www.libssh2.org/download/libssh2-1.10.0.tar.gz
tar -xf libssh2-1.10.0.tar.gz
cd libssh2-1.10.0
./configure --prefix=/usr --disable-static &&
make -j$(nproc)
make install
