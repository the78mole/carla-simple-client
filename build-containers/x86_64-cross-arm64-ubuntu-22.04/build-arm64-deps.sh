#!/bin/bash
set -e

# ARM64 CARLA Dependencies Build Script
# This script builds all CARLA dependencies for ARM64 architecture

WORK_DIR="/workspace"
DEPS_DIR="$WORK_DIR/deps/aarch64"
BUILD_DIR="$DEPS_DIR/build"
INSTALL_DIR="$DEPS_DIR/install"
DOWNLOADS_DIR="$DEPS_DIR/downloads"

# Ensure we're using the right cross-compiler
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
export STRIP=aarch64-linux-gnu-strip
export RANLIB=aarch64-linux-gnu-ranlib
export PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig

echo "=== CARLA ARM64 Dependencies Build ==="
echo "Target Architecture: ARM64 (aarch64)"
echo "Cross-Compiler: $CXX"
echo "Install Directory: $INSTALL_DIR"
echo ""

# Create directories
mkdir -p "$BUILD_DIR" "$INSTALL_DIR" "$DOWNLOADS_DIR"

# Function to download and verify
download_and_verify() {
    local URL="$1"
    local FILENAME="$2"
    local TARGET_DIR="$3"
    
    if [ ! -f "$DOWNLOADS_DIR/$FILENAME" ]; then
        echo "Downloading $FILENAME..."
        wget -O "$DOWNLOADS_DIR/$FILENAME" "$URL"
    fi
    
    if [ ! -d "$TARGET_DIR" ]; then
        echo "Extracting $FILENAME..."
        cd "$BUILD_DIR"
        case "$FILENAME" in
            *.tar.gz|*.tgz) tar -xzf "$DOWNLOADS_DIR/$FILENAME" ;;
            *.tar.bz2) tar -xjf "$DOWNLOADS_DIR/$FILENAME" ;;
            *.tar.xz) tar -xJf "$DOWNLOADS_DIR/$FILENAME" ;;
            *.zip) unzip -q "$DOWNLOADS_DIR/$FILENAME" ;;
            *) echo "Unknown archive format: $FILENAME"; exit 1 ;;
        esac
        cd "$WORK_DIR"
    fi
}

# 1. Build Boost 1.84.0 for ARM64
echo "=== Building Boost 1.84.0 for ARM64 ==="
BOOST_URL="https://archives.boost.io/release/1.84.0/source/boost_1_84_0.tar.gz"
BOOST_ARCHIVE="boost_1_84_0.tar.gz"
BOOST_DIR="$BUILD_DIR/boost_1_84_0"
BOOST_INSTALL="$INSTALL_DIR/boost-1.84.0"

download_and_verify "$BOOST_URL" "$BOOST_ARCHIVE" "$BOOST_DIR"

if [ ! -d "$BOOST_INSTALL" ]; then
    cd "$BOOST_DIR"
    echo "Configuring Boost for ARM64..."
    
    # Create user-config.jam for cross-compilation
    cat > user-config.jam << EOF
using gcc : arm64 : aarch64-linux-gnu-g++ ;
EOF
    
    ./bootstrap.sh --prefix="$BOOST_INSTALL"
    
    echo "Building Boost for ARM64..."
    ./b2 -j$(nproc) \
        --user-config=user-config.jam \
        toolset=gcc-arm64 \
        target-os=linux \
        architecture=arm \
        address-model=64 \
        link=static \
        threading=multi \
        runtime-link=shared \
        --without-mpi \
        --without-graph_parallel \
        install
    
    cd "$WORK_DIR"
    echo "✅ Boost 1.84.0 ARM64 build completed"
else
    echo "✅ Boost 1.84.0 already built for ARM64"
fi

# 2. Build rpclib for ARM64
echo "=== Building rpclib v2.2.1_c5 for ARM64 ==="
RPCLIB_URL="https://github.com/rpclib/rpclib/archive/v2.2.1.tar.gz"
RPCLIB_ARCHIVE="rpclib-v2.2.1.tar.gz"
RPCLIB_DIR="$BUILD_DIR/rpclib-2.2.1"
RPCLIB_BUILD="$BUILD_DIR/rpclib-build"
RPCLIB_INSTALL="$INSTALL_DIR/rpclib-v2.2.1_c5"

download_and_verify "$RPCLIB_URL" "$RPCLIB_ARCHIVE" "$RPCLIB_DIR"

if [ ! -d "$RPCLIB_INSTALL" ]; then
    mkdir -p "$RPCLIB_BUILD"
    cd "$RPCLIB_BUILD"
    
    echo "Configuring rpclib for ARM64..."
    cmake -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="/usr/local/bin/arm64-toolchain.cmake" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$RPCLIB_INSTALL" \
        -DRPCLIB_BUILD_EXAMPLES=OFF \
        -DRPCLIB_BUILD_TESTS=OFF \
        "$RPCLIB_DIR"
    
    echo "Building rpclib for ARM64..."
    ninja install
    
    cd "$WORK_DIR"
    echo "✅ rpclib ARM64 build completed"
else
    echo "✅ rpclib already built for ARM64"
fi

# 3. Build Recast & Detour for ARM64
echo "=== Building Recast & Detour for ARM64 ==="
RECAST_URL="https://github.com/recastnavigation/recastnavigation/archive/v1.6.0.tar.gz"
RECAST_ARCHIVE="recast-1.6.0.tar.gz"
RECAST_DIR="$BUILD_DIR/recastnavigation-1.6.0"
RECAST_BUILD="$BUILD_DIR/recast-build"
RECAST_INSTALL="$INSTALL_DIR/recast"

download_and_verify "$RECAST_URL" "$RECAST_ARCHIVE" "$RECAST_DIR"

if [ ! -d "$RECAST_INSTALL" ]; then
    mkdir -p "$RECAST_BUILD"
    cd "$RECAST_BUILD"
    
    echo "Configuring Recast & Detour for ARM64..."
    cmake -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="/usr/local/bin/arm64-toolchain.cmake" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$RECAST_INSTALL" \
        -DRECASTNAVIGATION_DEMO=OFF \
        -DRECASTNAVIGATION_TESTS=OFF \
        -DRECASTNAVIGATION_EXAMPLES=OFF \
        "$RECAST_DIR"
    
    echo "Building Recast & Detour for ARM64..."
    ninja install
    
    cd "$WORK_DIR"
    echo "✅ Recast & Detour ARM64 build completed"
else
    echo "✅ Recast & Detour already built for ARM64"
fi

# 4. Build LibPNG for ARM64 (backup, system version preferred)
echo "=== Building LibPNG 1.6.37 for ARM64 ==="
LIBPNG_URL="https://download.sourceforge.net/libpng/libpng-1.6.37.tar.gz"
LIBPNG_ARCHIVE="libpng-1.6.37.tar.gz"
LIBPNG_DIR="$BUILD_DIR/libpng-1.6.37"
LIBPNG_BUILD="$BUILD_DIR/libpng-build"
LIBPNG_INSTALL="$INSTALL_DIR/libpng-1.6.37"

download_and_verify "$LIBPNG_URL" "$LIBPNG_ARCHIVE" "$LIBPNG_DIR"

if [ ! -d "$LIBPNG_INSTALL" ]; then
    mkdir -p "$LIBPNG_BUILD"
    cd "$LIBPNG_BUILD"
    
    echo "Configuring LibPNG for ARM64..."
    cmake -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="/usr/local/bin/arm64-toolchain.cmake" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$LIBPNG_INSTALL" \
        -DPNG_TESTS=OFF \
        -DPNG_SHARED=OFF \
        -DPNG_STATIC=ON \
        -DZLIB_LIBRARY="/usr/lib/aarch64-linux-gnu/libz.so" \
        -DZLIB_INCLUDE_DIR="/usr/include" \
        "$LIBPNG_DIR"
    
    echo "Building LibPNG for ARM64..."
    ninja install
    
    cd "$WORK_DIR"
    echo "✅ LibPNG ARM64 build completed"
else
    echo "✅ LibPNG already built for ARM64"
fi

# 5. Build LibCarla Client for ARM64
echo "=== Building LibCarla Client for ARM64 ==="
LIBCARLA_BUILD="$BUILD_DIR/libcarla-build"
LIBCARLA_INSTALL="$INSTALL_DIR/libcarla-client"

if [ ! -d "$LIBCARLA_INSTALL" ]; then
    mkdir -p "$LIBCARLA_BUILD"
    cd "$LIBCARLA_BUILD"
    
    echo "Configuring LibCarla Client for ARM64..."
    cmake -G Ninja \
        -DCMAKE_TOOLCHAIN_FILE="/usr/local/bin/arm64-toolchain.cmake" \
        -DCMAKE_BUILD_TYPE=Client \
        -DCMAKE_INSTALL_PREFIX="$LIBCARLA_INSTALL" \
        -DLIBCARLA_BUILD_RELEASE=ON \
        -DLIBCARLA_BUILD_DEBUG=OFF \
        -DLIBCARLA_BUILD_TEST=OFF \
        -DBOOST_INCLUDE_PATH="$BOOST_INSTALL/include" \
        -DBOOST_LIB_PATH="$BOOST_INSTALL/lib" \
        -DRPCLIB_INCLUDE_PATH="$RPCLIB_INSTALL/include" \
        -DRPCLIB_LIB_PATH="$RPCLIB_INSTALL/lib" \
        -DRECAST_INCLUDE_PATH="$RECAST_INSTALL/include" \
        -DRECAST_LIB_PATH="$RECAST_INSTALL/lib" \
        -DLIBPNG_INCLUDE_PATH="$LIBPNG_INSTALL/include" \
        -DLIBPNG_LIB_PATH="$LIBPNG_INSTALL/lib" \
        "$WORK_DIR/LibCarla/cmake/client"
    
    echo "Building LibCarla Client for ARM64..."
    ninja install
    
    cd "$WORK_DIR"
    echo "✅ LibCarla Client ARM64 build completed"
else
    echo "✅ LibCarla Client already built for ARM64"
fi

echo ""
echo "🎉 ARM64 Dependencies Build Completed Successfully!"
echo ""
echo "📊 Build Summary:"
echo "- Boost 1.84.0:       $(du -sh $BOOST_INSTALL 2>/dev/null | cut -f1)"
echo "- rpclib v2.2.1:      $(du -sh $RPCLIB_INSTALL 2>/dev/null | cut -f1)"
echo "- Recast & Detour:    $(du -sh $RECAST_INSTALL 2>/dev/null | cut -f1)"
echo "- LibPNG 1.6.37:      $(du -sh $LIBPNG_INSTALL 2>/dev/null | cut -f1)"
echo "- LibCarla Client:    $(du -sh $LIBCARLA_INSTALL 2>/dev/null | cut -f1)"
echo "- Total Dependencies: $(du -sh $INSTALL_DIR 2>/dev/null | cut -f1)"
echo ""
echo "Dependencies installed in: $INSTALL_DIR"