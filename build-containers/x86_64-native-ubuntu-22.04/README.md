# CARLA Simple Client - x86_64 Native Ubuntu 22.04 Build Container

This directory contains a Docker container for building CARLA client examples natively on x86_64 architecture using Ubuntu 22.04.

## Purpose

Provides a clean, reproducible Ubuntu 22.04 build environment for:
- Building CARLA LibCarla client library natively on x86_64
- Compiling C++ example clients (`cpp_client`, `cpp_client_window`)
- Creating platform-specific binaries with consistent dependencies

## Container Architecture

- **Base**: Ubuntu 22.04 LTS
- **Target Architecture**: x86_64 (native)
- **Build Tools**: GCC, CMake, Ninja
- **Dependencies**: Boost, rpclib, Recast/Detour, LibPNG, system libraries

## Files

- `Dockerfile` - Container definition with Ubuntu 22.04 and build tools
- `build-native-examples.sh` - Complete build script for dependencies and examples
- `docker-build.sh` - Helper script for building the container image
- `README.md` - This documentation

## Quick Start

### 1. Build the Container

```bash
./docker-build.sh
```

### 2. Run Container with Build

```bash
# Build everything in container
docker run -it --rm \
  -v "$(pwd)/../../:/workspace" \
  carla-x86_64-native:ubuntu-22.04 \
  /workspace/build-containers/x86_64-native-ubuntu-22.04/build-native-examples.sh
```

### 3. Interactive Development

```bash
# Interactive shell in container
docker run -it --rm \
  -v "$(pwd)/../../:/workspace" \
  carla-x86_64-native:ubuntu-22.04
```

## Build Process

The `build-native-examples.sh` script performs these steps:

1. **Dependencies**: Builds Boost, rpclib, Recast/Detour from source
2. **LibCarla**: Compiles CARLA client library natively
3. **Examples**: Builds all C++ client examples
4. **Testing**: Validates built binaries

## Output

All build artifacts are placed in:
- **Dependencies**: `deps/x86_64/` (libraries, headers)
- **Build files**: `build/x86_64/` (CMake cache, objects)
- **Binaries**: `build/x86_64/*/` (executable files)

## Example Usage

After building, the examples can be run:

```bash
# Test connection to CARLA server
./build/x86_64/cpp_client/cpp_client localhost 2000

# Run window client (if built)
./build/x86_64/cpp_client_window/cpp_client_window localhost 2000
```

## Container Features

- **Non-root user**: Builds run as `carla` user for security
- **Clean environment**: Fresh Ubuntu 22.04 with minimal dependencies
- **Reproducible**: Same build environment across different host systems
- **Volume mounted**: Repository is mounted for persistent build artifacts

## Troubleshooting

### Permission Issues
Ensure the repository directory is accessible to the container user:
```bash
sudo chown -R $(id -u):$(id -g) build/ deps/
```

### Missing Dependencies
The container installs all required system dependencies. For additional libraries:
```bash
# Edit Dockerfile and rebuild
./docker-build.sh --rebuild
```

### Build Failures
Check build logs for specific errors:
```bash
# Run with verbose output
docker run -it --rm \
  -v "$(pwd)/../../:/workspace" \
  carla-x86_64-native:ubuntu-22.04 \
  bash -c "set -x; /workspace/build-containers/x86_64-native-ubuntu-22.04/build-native-examples.sh"
```