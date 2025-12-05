# CARLA Simple Client - Directory Structure

This document describes the organized directory structure of the CARLA Simple Client project.

## Architecture-Specific Organization

### Dependencies (`deps/`)
```
deps/
├── x86_64/           # x86_64 dependencies and builds
│   ├── install/      # Installed libraries (Boost, LibCarla, etc.)
│   └── build/        # Build artifacts
└── aarch64/          # ARM64 dependencies and builds
    ├── install/      # ARM64 installed libraries
    └── build/        # ARM64 build artifacts
```

### Build Outputs (`build/`)
```
build/
├── x86_64/          # x86_64 build outputs
│   └── examples/    # Built x86_64 client binaries
└── aarch64/         # ARM64 build outputs
    └── examples/    # Built ARM64 client binaries
```

### Build Containers (`build-containers/`)
```
build-containers/
└── x86_64-cross-arm64-ubuntu-22.04/  # Docker container for ARM64 cross-compilation
    ├── Dockerfile                    # Container definition
    ├── build-arm64-deps.sh          # Automated dependency building
    └── arm64-toolchain.cmake        # ARM64 cross-compilation toolchain
```

## Key Benefits

1. **Clean Architecture Separation**: Clear separation between x86_64 and ARM64 builds
2. **No Cross-Contamination**: Dependencies and builds are isolated by architecture
3. **Docker-Based Cross-Compilation**: Containerized build environment for consistent results
4. **Scalable**: Easy to add more architectures (e.g., `deps/riscv64/`, `build/riscv64/`)

## Usage

### x86_64 Local Build
```bash
mkdir -p build/x86_64
cd build/x86_64
cmake -G Ninja ../..
ninja
```

### ARM64 Cross-Compilation
```bash
# Using Docker container
docker build build-containers/x86_64-cross-arm64-ubuntu-22.04 -t carla-arm64-builder:latest

# Cross-compile
mkdir -p build/aarch64  
cd build/aarch64
cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE=../../cmake/toolchain-arm64.cmake ../..
ninja
```

## Architecture Detection

The CMake build system automatically detects the target architecture:

- `CMAKE_SYSTEM_PROCESSOR` determines the target architecture
- Dependencies are loaded from the appropriate `deps/{arch}/` directory
- Build outputs go to the corresponding `build/{arch}/` directory

This provides a clean, maintainable structure that supports multiple architectures without confusion or conflicts.