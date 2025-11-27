# Copilot Instructions for CARLA Simple Client

This document provides guidelines for GitHub Copilot and developers working on this project.

## Project Overview

This repository enables building CARLA simulator clients **externally** from the main CARLA source tree, specifically targeting the `ue4/0.9.16` branch. The primary goal is to simplify client development, especially on **ARM64 Linux** platforms.

## Target CARLA Version

- **Branch**: `ue4/0.9.16`
- **Repository**: https://github.com/carla-simulator/carla/tree/ue4/0.9.16

## Architecture Support

- **Primary Target**: ARM64 Linux (aarch64-linux-gnu)
- **Secondary Target**: x86_64 Linux
- **Future Consideration**: Windows, macOS

## Directory Structure

```
carla-simple-client/
├── .github/
│   └── copilot-instructions.md  # This file
├── cmake/
│   ├── toolchain-arm64.cmake    # ARM64 cross-compilation toolchain
│   └── toolchain-x86_64.cmake   # x86_64 native toolchain
├── scripts/
│   └── setup-dependencies.sh    # Script to download and build dependencies
├── examples/
│   └── cpp_client/              # Example C++ client
│       ├── CMakeLists.txt
│       └── main.cpp
├── CMakeLists.txt               # Main CMake configuration
├── README.md                    # Project documentation
└── LICENSE                      # MIT License
```

## Dependencies

The following dependencies are required from CARLA's build system:

1. **Boost** (1.84.0) - C++ libraries for networking, filesystem, etc.
2. **rpclib** (v2.2.1_c5) - RPC library for client-server communication
3. **Recast/Detour** - Navigation mesh library
4. **libpng** (1.6.37) - PNG image support
5. **pugixml** - XML parsing (bundled with LibCarla source)

## Coding Conventions

### C++ Standards
- Use **C++14** standard (`-std=c++14`)
- Enable position-independent code (`-fPIC`)
- Use pthread for threading (`-pthread`)

### Compiler Flags (Release)
```cmake
-std=c++14 -pthread -fPIC -O3 -DNDEBUG -Wall -Wextra
```

### Include Paths
When building against LibCarla, use the following include structure:
- `include/` - CARLA headers
- `include/system/` - Third-party headers (boost, rpc, recast)

### Linking Order
Libraries should be linked in this order:
1. `carla_client` (static)
2. `rpc` (static)
3. `boost_filesystem` (static)
4. `Recast`, `Detour`, `DetourCrowd` (dynamic or static)
5. `png`, `tiff`, `jpeg` (dynamic)

## Build System Guidelines

### CMake Best Practices
- Minimum CMake version: 3.14
- Use modern CMake targets with `target_link_libraries`
- Prefer `PRIVATE` visibility for internal dependencies
- Use `find_package` with `CONFIG` mode when possible

### Cross-Compilation
For ARM64 targets:
- Use a proper toolchain file
- Set `CMAKE_SYSTEM_NAME` to `Linux`
- Set `CMAKE_SYSTEM_PROCESSOR` to `aarch64`
- Specify cross-compiler paths

## Implementation Notes

### LibCarla Client Build
The LibCarla client library is built with these CMake options:
- `CMAKE_BUILD_TYPE=Client`
- `LIBCARLA_BUILD_RELEASE=ON`
- `LIBCARLA_BUILD_DEBUG=OFF` (for release builds)
- `LIBCARLA_BUILD_TEST=OFF` (tests require server)

### Version Header
CARLA version is defined in `carla/Version.h`, generated from `Version.h.in`:
```cpp
#define CARLA_VERSION_MAJOR X
#define CARLA_VERSION_MINOR Y
#define CARLA_VERSION_PATCH Z
```

### Error Handling
- Use `BOOST_ERROR_CODE_HEADER_ONLY` to avoid linking Boost.System
- Client builds use standard C++ exceptions
- Timeout exceptions are thrown as `carla::client::TimeoutException`

## Testing

### Manual Testing
Since this is a client library, testing requires a running CARLA server:
1. Start a CARLA server on the target machine or network
2. Run the example client with server address: `./cpp_client <host> <port>`

### Connection Testing
Default connection settings:
- Host: `localhost`
- Port: `2000`
- Timeout: `40s`

## Future Improvements

- [ ] Add Python API bindings support
- [ ] Add Docker-based build environment
- [ ] Add CI/CD for automated testing
- [ ] Add pre-built dependency packages
- [ ] Support for Windows MSVC builds
