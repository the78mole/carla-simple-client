#!/bin/bash
# Build script for CARLA Simple Client examples on x86_64 Ubuntu 22.04
# This script builds all native x86_64 dependencies and examples in a container

set -euo pipefail

WORKSPACE_ROOT="/workspace"
DEPS_DIR="$WORKSPACE_ROOT/deps/x86_64"
BUILD_DIR="$WORKSPACE_ROOT/build/x86_64"
EXAMPLES_DIR="$WORKSPACE_ROOT/examples"

echo "=== CARLA Simple Client x86_64 Native Build ==="
echo "Workspace: $WORKSPACE_ROOT"
echo "Dependencies: $DEPS_DIR" 
echo "Build output: $BUILD_DIR"

# Create build directories
mkdir -p "$DEPS_DIR" "$BUILD_DIR"

# Function to build and install dependencies
build_dependencies() {
    echo "=== Setting up x86_64 Dependencies ==="
    
    # Create dependencies directory structure
    mkdir -p "$DEPS_DIR/lib" "$DEPS_DIR/include"
    
    # Check if dependencies already exist
    if [[ -f "$DEPS_DIR/lib/librpc.a" && -d "$DEPS_DIR/include/boost" ]]; then
        echo "Dependencies already exist in $DEPS_DIR"
        echo "Contents:"
        ls -la "$DEPS_DIR/"
        return 0
    fi
    
    echo "Setting up dependencies..."
    
    # Use system Boost (Ubuntu 22.04 has Boost 1.74 which is sufficient)
    echo "Using system Boost packages..."
    if [[ ! -L "$DEPS_DIR/include/boost" ]]; then
        ln -sf /usr/include/boost "$DEPS_DIR/include/"
    fi
    
    # Copy system boost libraries to our deps directory
    find /usr/lib/x86_64-linux-gnu -name "libboost_*.so*" -exec ln -sf {} "$DEPS_DIR/lib/" \;
    find /usr/lib/x86_64-linux-gnu -name "libboost_*.a" -exec ln -sf {} "$DEPS_DIR/lib/" \; 2>/dev/null || true
    
    # Build rpclib
    if [[ ! -f "$DEPS_DIR/lib/librpc.a" ]]; then
        echo "Building rpclib..."
        cd /tmp
        git clone --depth 1 --branch v2.2.1 https://github.com/rpclib/rpclib.git
        cd rpclib
        
        mkdir -p build && cd build
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$DEPS_DIR" \
            -DRPCLIB_BUILD_EXAMPLES=OFF \
            -DRPCLIB_BUILD_TESTS=OFF \
            -GNinja
        
        ninja install
        rm -rf /tmp/rpclib
    fi
    
    # Build Recast/Detour
    if [[ ! -f "$DEPS_DIR/lib/libRecast.a" ]]; then
        echo "Building Recast/Detour..."
        cd /tmp
        git clone --depth 1 --branch v1.6.0 https://github.com/recastnavigation/recastnavigation.git
        cd recastnavigation
        
        mkdir -p build && cd build
        cmake .. \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_INSTALL_PREFIX="$DEPS_DIR" \
            -DRECASTNAVIGATION_DEMO=OFF \
            -DRECASTNAVIGATION_TESTS=OFF \
            -DRECASTNAVIGATION_EXAMPLES=OFF \
            -GNinja
            
        ninja install
        rm -rf /tmp/recastnavigation
    fi
    
    # Use system image libraries
    if [[ ! -L "$DEPS_DIR/lib/libpng.so" ]]; then
        ln -sf /usr/lib/x86_64-linux-gnu/libpng*.so* "$DEPS_DIR/lib/"
        ln -sf /usr/lib/x86_64-linux-gnu/libjpeg*.so* "$DEPS_DIR/lib/"
        ln -sf /usr/lib/x86_64-linux-gnu/libtiff*.so* "$DEPS_DIR/lib/"
    fi
    
    echo "Dependencies setup completed!"
    echo "Installed in: $DEPS_DIR"
    ls -la "$DEPS_DIR/lib/" | head -10
    ls -la "$DEPS_DIR/include/" | head -10
}

# Function to build LibCarla client
build_libcarla() {
    echo "=== Building LibCarla Client Library ==="
    
    cd "$WORKSPACE_ROOT"
    LIBCARLA_BUILD="$BUILD_DIR/libcarla"
    
    mkdir -p "$LIBCARLA_BUILD"
    cd "$LIBCARLA_BUILD"
    
    cmake "$WORKSPACE_ROOT/LibCarla/cmake" \
        -DCMAKE_BUILD_TYPE=Client \
        -DCMAKE_INSTALL_PREFIX="$DEPS_DIR" \
        -DCMAKE_PREFIX_PATH="$DEPS_DIR" \
        -DLIBCARLA_BUILD_RELEASE=ON \
        -DLIBCARLA_BUILD_DEBUG=OFF \
        -DLIBCARLA_BUILD_TEST=OFF \
        -DRPCLIB_INCLUDE_PATH="$DEPS_DIR/include" \
        -DBOOST_INCLUDE_PATH="/usr/include" \
        -DRECAST_INCLUDE_PATH="/usr/include" \
        -DLIBPNG_INCLUDE_PATH="/usr/include" \
        -GNinja
    
    ninja
    ninja install
    
    echo "LibCarla client built successfully!"
}

# Function to build examples
build_examples() {
    echo "=== Building Examples ==="
    
    # Build cpp_client
    echo "Building cpp_client..."
    CPP_CLIENT_BUILD="$BUILD_DIR/cpp_client"
    mkdir -p "$CPP_CLIENT_BUILD"
    cd "$CPP_CLIENT_BUILD"
    
    cmake "$EXAMPLES_DIR/cpp_client" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_PREFIX_PATH="$DEPS_DIR" \
        -GNinja
    
    ninja
    
    # Build cpp_client_window (if it exists)
    if [[ -d "$EXAMPLES_DIR/cpp_client_window" ]]; then
        echo "Building cpp_client_window..."
        CPP_CLIENT_WINDOW_BUILD="$BUILD_DIR/cpp_client_window"
        mkdir -p "$CPP_CLIENT_WINDOW_BUILD"
        cd "$CPP_CLIENT_WINDOW_BUILD"
        
        cmake "$EXAMPLES_DIR/cpp_client_window" \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_PREFIX_PATH="$DEPS_DIR" \
            -GNinja
        
        ninja
    fi
    
    echo "Examples built successfully!"
    echo "Built binaries:"
    find "$BUILD_DIR" -type f -executable -name "*client*" | head -10
}

# Function to run tests
run_tests() {
    echo "=== Testing Examples ==="
    
    # Test cpp_client
    if [[ -f "$BUILD_DIR/cpp_client/cpp_client" ]]; then
        echo "Testing cpp_client..."
        "$BUILD_DIR/cpp_client/cpp_client" --help || echo "cpp_client help check completed"
    fi
    
    # List all built binaries
    echo "All built executables:"
    find "$BUILD_DIR" -type f -executable | grep -E "(client|example)" | head -20
}

# Main execution
main() {
    echo "Starting x86_64 native build process..."
    
    build_dependencies
    build_libcarla
    build_examples
    run_tests
    
    echo "=== Build completed successfully! ==="
    echo "Built examples available in: $BUILD_DIR"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi