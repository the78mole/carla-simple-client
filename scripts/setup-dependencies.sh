#!/bin/bash
#
# Setup script for CARLA Simple Client dependencies
#
# This script downloads and builds all required dependencies for building
# CARLA clients outside the main CARLA source tree.
#
# Target CARLA version: ue4/0.9.16
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Build settings
CARLA_BRANCH="ue4/0.9.16"
# Cross-platform CPU count detection
if command -v nproc >/dev/null 2>&1; then
    # Linux
    DEFAULT_JOBS=$(nproc)
elif command -v sysctl >/dev/null 2>&1; then
    # macOS
    DEFAULT_JOBS=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
else
    # Fallback
    DEFAULT_JOBS=4
fi
BUILD_JOBS="${BUILD_JOBS:-${DEFAULT_JOBS}}"
BUILD_DIR="${PROJECT_ROOT}/deps/build"
INSTALL_DIR="${PROJECT_ROOT}/deps/install"
DOWNLOAD_DIR="${PROJECT_ROOT}/deps/downloads"
LIBCARLA_INSTALL_DIR="${INSTALL_DIR}/libcarla-client"

# Compiler settings
CC="${CC:-gcc}"
CXX="${CXX:-g++}"
CXXFLAGS="${CXXFLAGS:--std=c++14 -fPIC -O3 -DNDEBUG}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Create directories
mkdir -p "${BUILD_DIR}" "${INSTALL_DIR}" "${DOWNLOAD_DIR}" "${LIBCARLA_INSTALL_DIR}"

# ==============================================================================
# Boost
# ==============================================================================

BOOST_VERSION="1.84.0"
BOOST_BASENAME="boost_${BOOST_VERSION//./_}"
BOOST_INSTALL_DIR="${INSTALL_DIR}/boost-${BOOST_VERSION}"

build_boost() {
    if [[ -f "${BOOST_INSTALL_DIR}/lib/libboost_filesystem.a" ]]; then
        log "Boost ${BOOST_VERSION} already installed."
        return
    fi

    log "Building Boost ${BOOST_VERSION}..."
    
    # Check for Python development headers
    if ! command -v python3-config &> /dev/null; then
        warn "python3-config not found. Boost.Python may fail to build."
        warn "Install python3-dev (Debian/Ubuntu) or python3-devel (RHEL/Fedora)"
    fi
    
    cd "${DOWNLOAD_DIR}"
    
    if [[ ! -f "${BOOST_BASENAME}.tar.gz" ]]; then
        log "Downloading Boost from primary source..."
        if ! wget -q "https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_BASENAME}.tar.gz"; then
            log "Primary download failed, trying backup source..."
            # Backup source: CARLA's S3 bucket (documented fallback)
            wget -q "https://carla-releases.s3.us-east-005.backblazeb2.com/Backup/${BOOST_BASENAME}.tar.gz" \
                || error "Failed to download Boost from both primary and backup sources"
        fi
    fi
    
    log "Extracting Boost..."
    tar -xzf "${BOOST_BASENAME}.tar.gz" -C "${BUILD_DIR}"
    
    cd "${BUILD_DIR}/${BOOST_BASENAME}"
    
    # Try to detect Python
    PYTHON_INCLUDE=""
    PYTHON_LIB=""
    if command -v python3-config &> /dev/null; then
        PYTHON_INCLUDE=$(python3-config --includes | sed 's/-I//g' | awk '{print $1}')
        PYTHON_LIB=$(python3-config --ldflags | grep -o '\-L[^ ]*' | sed 's/-L//')
        log "Python detected: include=${PYTHON_INCLUDE}, lib=${PYTHON_LIB}"
    fi
    
    # Configure Boost with Python if available
    if [[ -n "${PYTHON_INCLUDE}" ]]; then
        ./bootstrap.sh \
            --prefix="${BOOST_INSTALL_DIR}" \
            --with-libraries=python,filesystem,system,program_options \
            --with-python=$(which python3)
    else
        warn "Python development headers not found, building without Boost.Python"
        ./bootstrap.sh \
            --prefix="${BOOST_INSTALL_DIR}" \
            --with-libraries=filesystem,system,program_options
    fi
    
    ./b2 \
        cxxflags="${CXXFLAGS}" \
        --prefix="${BOOST_INSTALL_DIR}" \
        -j "${BUILD_JOBS}" \
        install
    
    # Copy to LibCarla install dir
    mkdir -p "${LIBCARLA_INSTALL_DIR}/include/system"
    mkdir -p "${LIBCARLA_INSTALL_DIR}/lib"
    cp -rf "${BOOST_INSTALL_DIR}/include/boost" "${LIBCARLA_INSTALL_DIR}/include/system/"
    
    # Copy static libraries if they exist
    if compgen -G "${BOOST_INSTALL_DIR}/lib/"*.a > /dev/null; then
        cp -rf "${BOOST_INSTALL_DIR}/lib/"*.a "${LIBCARLA_INSTALL_DIR}/lib/"
    else
        warn "No static Boost libraries found at ${BOOST_INSTALL_DIR}/lib/"
    fi
    
    log "Boost ${BOOST_VERSION} installed."
}

# ==============================================================================
# rpclib
# ==============================================================================

RPCLIB_VERSION="v2.2.1_c5"
RPCLIB_INSTALL_DIR="${INSTALL_DIR}/rpclib-${RPCLIB_VERSION}"

build_rpclib() {
    if [[ -f "${RPCLIB_INSTALL_DIR}/lib/librpc.a" ]]; then
        log "rpclib ${RPCLIB_VERSION} already installed."
        return
    fi

    log "Building rpclib ${RPCLIB_VERSION}..."
    
    cd "${BUILD_DIR}"
    
    if [[ ! -d "rpclib-source" ]]; then
        git clone -b "${RPCLIB_VERSION}" --depth 1 \
            https://github.com/carla-simulator/rpclib.git rpclib-source
    fi
    
    mkdir -p rpclib-build
    cd rpclib-build
    
    cmake -G "Ninja" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${RPCLIB_INSTALL_DIR}" \
        ../rpclib-source
    
    ninja -j "${BUILD_JOBS}"
    ninja install
    
    # Copy to LibCarla install dir
    mkdir -p "${LIBCARLA_INSTALL_DIR}/include/system"
    cp -rf "${RPCLIB_INSTALL_DIR}/include/rpc" "${LIBCARLA_INSTALL_DIR}/include/system/"
    cp -f "${RPCLIB_INSTALL_DIR}/lib/librpc.a" "${LIBCARLA_INSTALL_DIR}/lib/"
    
    log "rpclib ${RPCLIB_VERSION} installed."
}

# ==============================================================================
# Recast Navigation
# ==============================================================================

RECAST_INSTALL_DIR="${INSTALL_DIR}/recast"

build_recast() {
    if [[ -f "${RECAST_INSTALL_DIR}/lib/libRecast.a" ]]; then
        log "Recast already installed."
        return
    fi

    log "Building Recast Navigation..."
    
    cd "${BUILD_DIR}"
    
    if [[ ! -d "recast-source" ]]; then
        git clone --depth 1 -b carla \
            https://github.com/carla-simulator/recastnavigation.git recast-source
        
        # Fix CMake minimum version requirement (CARLA fork uses old version)
        sed -i.bak 's/cmake_minimum_required(VERSION [0-9.]*)/cmake_minimum_required(VERSION 3.5)/' \
            recast-source/CMakeLists.txt
    fi
    
    mkdir -p recast-build
    cd recast-build
    
    cmake -G "Ninja" \
        -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
        -DCMAKE_INSTALL_PREFIX="${RECAST_INSTALL_DIR}" \
        -DRECASTNAVIGATION_DEMO=OFF \
        -DRECASTNAVIGATION_TEST=OFF \
        ../recast-source
    
    ninja -j "${BUILD_JOBS}"
    ninja install
    
    # Copy to LibCarla install dir
    mkdir -p "${LIBCARLA_INSTALL_DIR}/include/system"
    cp -rf "${RECAST_INSTALL_DIR}/include/recast" "${LIBCARLA_INSTALL_DIR}/include/system/"
    cp -f "${RECAST_INSTALL_DIR}/lib/"*.a "${LIBCARLA_INSTALL_DIR}/lib/"
    
    log "Recast installed."
}

# ==============================================================================
# libpng
# ==============================================================================

LIBPNG_VERSION="1.6.43"
LIBPNG_INSTALL_DIR="${INSTALL_DIR}/libpng-${LIBPNG_VERSION}"

build_libpng() {
    if [[ -f "${LIBPNG_INSTALL_DIR}/lib/libpng.a" ]]; then
        log "libpng ${LIBPNG_VERSION} already installed."
        return
    fi

    log "Building libpng ${LIBPNG_VERSION}..."
    
    cd "${DOWNLOAD_DIR}"
    
    if [[ ! -f "libpng-${LIBPNG_VERSION}.tar.xz" ]]; then
        log "Downloading libpng..."
        wget -q "https://sourceforge.net/projects/libpng/files/libpng16/${LIBPNG_VERSION}/libpng-${LIBPNG_VERSION}.tar.xz"
    fi
    
    log "Extracting libpng..."
    tar -xf "libpng-${LIBPNG_VERSION}.tar.xz" -C "${BUILD_DIR}"
    
    cd "${BUILD_DIR}/libpng-${LIBPNG_VERSION}"
    
    CFLAGS="-fPIC" ./configure --prefix="${LIBPNG_INSTALL_DIR}"
    make -j "${BUILD_JOBS}"
    make install
    
    # Copy to LibCarla install dir
    mkdir -p "${LIBCARLA_INSTALL_DIR}/include/system/libpng16"
    cp -rf "${LIBPNG_INSTALL_DIR}/include/"* "${LIBCARLA_INSTALL_DIR}/include/system/"
    cp -f "${LIBPNG_INSTALL_DIR}/lib/"*.a "${LIBCARLA_INSTALL_DIR}/lib/"
    
    log "libpng ${LIBPNG_VERSION} installed."
}

# ==============================================================================
# LibCarla (sources included in repository)
# ==============================================================================

# LibCarla source is included in this repository
LIBCARLA_SOURCE_DIR="${PROJECT_ROOT}/LibCarla"

build_libcarla() {
    if [[ -f "${LIBCARLA_INSTALL_DIR}/lib/libcarla_client.a" ]]; then
        log "LibCarla client already installed."
        return
    fi

    # Verify LibCarla sources exist in the repository
    if [[ ! -d "${LIBCARLA_SOURCE_DIR}/cmake" ]]; then
        error "LibCarla sources not found at ${LIBCARLA_SOURCE_DIR}"
    fi

    log "Building LibCarla client from included sources..."
    
    # Create CMake config file
    mkdir -p "${BUILD_DIR}/libcarla-build"
    cat > "${BUILD_DIR}/libcarla-build/CarlaConfig.cmake" << EOF
# Automatically generated CARLA config
add_definitions(-DBOOST_ERROR_CODE_HEADER_ONLY)

set(CARLA_VERSION "0.9.16")
set(BOOST_INCLUDE_PATH "${BOOST_INSTALL_DIR}/include")
set(RPCLIB_INCLUDE_PATH "${RPCLIB_INSTALL_DIR}/include")
set(RPCLIB_LIB_PATH "${RPCLIB_INSTALL_DIR}/lib")
set(RECAST_INCLUDE_PATH "${RECAST_INSTALL_DIR}/include")
set(RECAST_LIB_PATH "${RECAST_INSTALL_DIR}/lib")
set(LIBPNG_INCLUDE_PATH "${LIBPNG_INSTALL_DIR}/include")
set(LIBPNG_LIB_PATH "${LIBPNG_INSTALL_DIR}/lib")
set(BOOST_LIB_PATH "${BOOST_INSTALL_DIR}/lib")

add_definitions(-DLIBCARLA_IMAGE_WITH_PNG_SUPPORT=true)
EOF
    
    # Create toolchain file with dependency include paths
    cat > "${BUILD_DIR}/libcarla-build/ToolChain.cmake" << EOF
set(CMAKE_C_COMPILER ${CC})
set(CMAKE_CXX_COMPILER ${CXX})
set(CMAKE_CXX_FLAGS_INIT "${CXXFLAGS} -isystem ${BOOST_INSTALL_DIR}/include -isystem ${RPCLIB_INSTALL_DIR}/include -isystem ${RECAST_INSTALL_DIR}/include -isystem ${LIBPNG_INSTALL_DIR}/include")
EOF
    
    log "Building LibCarla client..."
    
    cd "${BUILD_DIR}/libcarla-build"
    
    cmake -G "Ninja" \
        -DCMAKE_BUILD_TYPE=Client \
        -DLIBCARLA_BUILD_RELEASE=ON \
        -DLIBCARLA_BUILD_DEBUG=OFF \
        -DLIBCARLA_BUILD_TEST=OFF \
        -DCMAKE_TOOLCHAIN_FILE="${BUILD_DIR}/libcarla-build/ToolChain.cmake" \
        -DCMAKE_INSTALL_PREFIX="${LIBCARLA_INSTALL_DIR}" \
        -C "${BUILD_DIR}/libcarla-build/CarlaConfig.cmake" \
        "${LIBCARLA_SOURCE_DIR}/cmake"
    
    ninja -j "${BUILD_JOBS}"
    ninja install
    
    log "LibCarla client installed to ${LIBCARLA_INSTALL_DIR}"
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    log "Setting up CARLA Simple Client dependencies..."
    log "CARLA branch: ${CARLA_BRANCH}"
    log "Build jobs: ${BUILD_JOBS}"
    log "Install directory: ${INSTALL_DIR}"
    echo
    
    # Check for required tools
    for cmd in cmake ninja git wget; do
        if ! command -v "$cmd" &> /dev/null; then
            error "$cmd is required but not installed."
        fi
    done
    
    # Build dependencies in order
    build_boost
    build_rpclib
    build_recast
    build_libpng
    build_libcarla
    
    log ""
    log "All dependencies installed successfully!"
    log ""
    log "LibCarla client is installed at: ${LIBCARLA_INSTALL_DIR}"
    log ""
    log "You can now build the project:"
    log "  mkdir build && cd build"
    log "  cmake -G Ninja .."
    log "  ninja"
}

main "$@"
