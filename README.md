# CARLA Simple Client

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/the78mole/carla-simple-client)
[![Architecture](https://img.shields.io/badge/arch-x86__64%20%7C%20ARM64-blue)](https://github.com/the78mole/carla-simple-client)
[![CARLA Version](https://img.shields.io/badge/CARLA-0.9.16-orange)](https://github.com/carla-simulator/carla/tree/ue4/0.9.16)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A standalone repository for building CARLA simulator clients **outside** the main CARLA source tree. This project targets the `ue4/0.9.16` branch of CARLA and supports multiple platforms including ARM64/x86_64 Linux and macOS.

## ✨ Features

- 🚀 **No CARLA Clone Required**: Complete LibCarla sources included
- 🏗️ **Out-of-Tree Building**: Build clients independently
- 🔧 **Multi-Architecture**: Native x86_64 and ARM64 cross-compilation support
- 🐳 **Docker-Based Builds**: Reproducible build environments
- 📦 **Pre-Built Dependencies**: ARM64 dependencies ready to use
- 💡 **Example Code**: Ready-to-use C++ and Python client examples

## Overview

Building CARLA clients normally requires cloning the entire CARLA repository and building within its source tree. This project provides:

- **Complete LibCarla sources included**: No need to clone the CARLA repository
- **Out-of-tree building**: Build clients independently
- **Multi-platform support**: ARM64 & x86_64 on Linux (Ubuntu 22.04+, 24.04+) and macOS 15
- **Simplified dependencies**: Automated setup for required libraries
- **Example code**: Ready-to-use C++ and Python client examples

## Quick Start

### TL;DR - Build Everything

```bash
# Clone repository
git clone https://github.com/the78mole/carla-simple-client.git
cd carla-simple-client

# Build for x86_64
make build-x86_64

# Or build for both architectures
make build-all

# Run the client (requires CARLA server)
make test-x86_64
```

> 📖 **For detailed build instructions**, see [BUILDING.md](BUILDING.md)

### Prerequisites

- **Docker** (recommended) or native build tools
- Git
- **For native builds**:
  - CMake 3.14+
  - GCC 11+ or Clang 10+
  - Ninja (recommended) or Make
- **For Python client**:
  - Python 3.8+
  - uv (recommended for package management)

### Building with Docker (Recommended)

Docker-based builds provide consistent, reproducible environments for both x86_64 and ARM64 targets.

#### 1. Clone the Repository

```bash
git clone https://github.com/the78mole/carla-simple-client.git
cd carla-simple-client
```

#### 2. View Available Targets

```bash
make help
```

This shows all available build targets:

```
General
  help                  Display this help
  all                   Build everything (x86_64 + ARM64)

x86_64 Builds
  build-x86_64          Build complete x86_64 stack
  libcarla-x86_64       Build LibCarla for x86_64
  third-party-x86_64    Build third-party libraries for x86_64
  client-x86_64         Build C++ client for x86_64

ARM64 Builds
  build-arm64           Build complete ARM64 stack
  libcarla-arm64        Build LibCarla for ARM64
  third-party-arm64     Build third-party libraries for ARM64
  client-arm64          Build C++ client for ARM64

Python Wheels
  wheel-x86_64          Build Python wheel for x86_64
  wheel-arm64           Build Python wheel for ARM64 (requires boost_python)
  wheels-all            Build all Python wheels
  clean-python          Clean Python build artifacts

Multi-Architecture
  build-all             Build for both x86_64 and ARM64
```

#### 3. Build x86_64 Client

```bash
# Build everything for x86_64
make build-x86_64

# Or build step-by-step:
make libcarla-x86_64      # Build LibCarla library
make third-party-x86_64   # Build third-party libraries
make client-x86_64        # Build example client
```

**Result**: `examples/cpp_client/cpp_client` (~3.8 MB, x86_64)

#### 4. Build ARM64 Client (Cross-Compilation)

```bash
# Build everything for ARM64
make build-arm64

# Or build step-by-step:
make libcarla-arm64       # Build LibCarla library
make third-party-arm64    # Build third-party libraries
make client-arm64         # Build example client
```

**Result**: `build/aarch64/cpp_client/cpp_client` (~3.6 MB, ARM aarch64)

#### 5. Build Both Architectures

```bash
# Build everything for both x86_64 and ARM64
make build-all
```

#### 6. Run the Client

```bash
# x86_64
make test-x86_64
# Or directly:
./examples/cpp_client/cpp_client localhost 2000

# ARM64 (requires ARM64 hardware or QEMU)
make test-arm64
# Or directly:
./build/aarch64/cpp_client/cpp_client localhost 2000
```

#### 7. View Build Information

```bash
make info
```

Shows detailed information about build artifacts, sizes, and architectures.

### VS Code Integration

If you're using VS Code, build tasks are pre-configured in `.vscode/tasks.json`:

- Press `Ctrl+Shift+B` (or `Cmd+Shift+B` on macOS) to build x86_64 (default)
- Press `Ctrl+Shift+P` → "Tasks: Run Task" to see all available tasks:
  - Build x86_64
  - Build ARM64
  - Build All (x86_64 + ARM64)
  - Build LibCarla x86_64/ARM64
  - Test x86_64 Client
  - Show Build Info
  - Clean x86_64/ARM64/All

### Native Build (Without Docker)

**Note**: For most users, the Makefile-based Docker build is recommended. However, you can also build natively.

#### Ubuntu/Debian Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake ninja-build git wget \
    libboost-all-dev libpng-dev \
    g++-aarch64-linux-gnu  # For ARM64 cross-compilation
```

#### Build Steps

1. **Setup dependencies:**
   ```bash
   ./scripts/setup-dependencies.sh
   ```

2. **Build for native architecture:**
   ```bash
   mkdir -p build/$(uname -m)/libcarla
   cd build/$(uname -m)/libcarla
   
   cmake ../../../LibCarla/cmake \
     -DCMAKE_BUILD_TYPE=Release \
     -DLIBCARLA_BUILD_RELEASE=ON \
     -G Ninja
   
   ninja install
   ```

3. **Build the example client:**
   - For detailed manual compilation commands, see the `Makefile` targets
   - Or use the Makefile even for native builds: `make build-x86_64`

## Build Artifacts

After a successful build, you'll have:

| Component | x86_64 | ARM64 | Description |
|-----------|--------|-------|-------------|
| **LibCarla** | 11 MB | 11 MB | Static library with CARLA client API |
| **Third-party** | 372 KB | 324 KB | pugixml + odrSpiral bundled libs |
| **Example Client** | 3.8 MB | 3.6 MB | Standalone executable |
| **Build Time** | ~1:48 | ~1:55 | Full build (115 source files) |
| **Incremental** | ~5s | ~5s | Single file recompilation |

### File Locations

#### x86_64 Build
- **LibCarla**: `build/x86_64/libcarla/install/lib/libcarla_client.a`
- **Third-party**: `build/x86_64/third-party/libcarla_third_party.a`
- **Example Client**: `examples/cpp_client/cpp_client`
- **Headers**: `build/x86_64/libcarla/install/include/`

#### ARM64 Build
- **LibCarla**: `build/aarch64/libcarla/install/lib/libcarla_client.a`
- **Third-party**: `build/aarch64/third-party/libcarla_third_party.a`
- **Example Client**: `build/aarch64/cpp_client/cpp_client`
- **Headers**: `build/aarch64/libcarla/install/include/`

### Verifying Builds

```bash
# Check architecture
file examples/cpp_client/cpp_client
# Output: ELF 64-bit LSB pie executable, x86-64, ...

file build/aarch64/cpp_client/cpp_client
# Output: ELF 64-bit LSB pie executable, ARM aarch64, ...

# Check library symbols
nm -C build/x86_64/libcarla/install/lib/libcarla_client.a | grep "carla::client::Client"
```

## Makefile Overview

The project includes a comprehensive Makefile that simplifies all build operations:

```bash
make help               # Show all available targets
make build-x86_64      # Build complete x86_64 stack
make build-arm64       # Build complete ARM64 stack (cross-compilation)
make build-all         # Build both architectures
make info              # Show detailed build information
make clean             # Remove all build artifacts
```

**Benefits:**
- ✅ Simple, memorable commands
- ✅ Automatic directory creation
- ✅ Colored output for better visibility
- ✅ Incremental builds (only rebuild what changed)
- ✅ VS Code task integration

## Project Structure

```
carla-simple-client/
├── .github/
│   ├── copilot-instructions.md     # Development guidelines
│   └── workflows/                  # CI/CD pipelines
├── build/                          # Build outputs (not in git)
│   ├── x86_64/                     # Native x86_64 builds
│   │   ├── libcarla/               # LibCarla library
│   │   ├── third-party/            # Third-party libraries
│   │   └── cpp_client/             # Example client build
│   └── aarch64/                    # ARM64 cross-compiled builds
│       ├── libcarla/
│       ├── third-party/
│       └── cpp_client/
├── deps/                           # Dependencies (built by setup script)
│   ├── x86_64/                     # x86_64 dependencies
│   │   ├── include/                # Headers (rpc, boost)
│   │   └── lib/                    # Libraries
│   └── aarch64/                    # ARM64 dependencies
│       └── install/                # Cross-compiled deps
│           ├── boost-1.84.0/
│           ├── rpclib-2.2.1/
│           ├── recast-1.6.0/
│           └── libpng-1.6.37/
├── LibCarla/                       # CARLA client library sources (from ue4/0.9.16)
│   ├── cmake/                      # CMake build configuration
│   └── source/                     # C++ source code
│       ├── carla/                  # Main CARLA headers/sources
│       │   ├── client/             # Client API
│       │   ├── geom/               # Geometry utilities
│       │   ├── nav/                # Navigation (minimal stubs)
│       │   ├── road/               # Road network
│       │   └── sensor/             # Sensor data handling
│       └── third-party/            # Bundled dependencies
│           ├── odrSpiral/          # OpenDRIVE spiral math
│           └── pugixml/            # XML parser
├── cmake/
│   ├── toolchain-arm64.cmake       # ARM64 cross-compilation
│   └── toolchain-x86_64.cmake      # Native x86_64 build
├── scripts/
│   └── setup-dependencies.sh       # Dependency setup script
├── examples/
│   ├── cpp_client/                 # Example C++ client
│   │   ├── CMakeLists.txt
│   │   └── main.cpp
│   ├── cpp_client_window/          # C++ client with OpenCV rendering
│   ├── python_client/              # Example Python client
│   └── python_client_window/       # Python client with pygame rendering
├── CMakeLists.txt                  # Main CMake configuration
├── pyproject.toml                  # Python package configuration
├── README.md                       # This file
└── LICENSE                         # MIT License
```

## Target CARLA Version

- **Branch**: [`ue4/0.9.16`](https://github.com/carla-simulator/carla/tree/ue4/0.9.16)
- **LibCarla Source**: Included in `LibCarla/` directory (extracted from official CARLA repository)

## Dependencies

This project uses the following libraries:

| Library | Version | Description | Build Status |
|---------|---------|-------------|-------------|
| Boost | 1.84.0 | C++ utilities (filesystem, system, etc.) | ✅ Pre-built for ARM64 |
| rpclib | v2.2.1_c5 | RPC for client-server communication | ✅ Pre-built for ARM64 |
| Recast/Detour | 1.6.0 | Navigation mesh (minimal stubs) | ✅ Pre-built for ARM64 |
| libpng | 1.6.37 | PNG image support | ✅ Pre-built for ARM64 |
| pugixml | bundled | XML parsing (bundled in LibCarla) | ✅ Built from source |
| odrSpiral | bundled | OpenDRIVE geometry (bundled) | ✅ Built from source |

### Dependency Notes

- **ARM64 dependencies** are pre-built and included in `deps/aarch64/install/`
- **x86_64 dependencies** use system libraries (Boost) + custom builds (rpclib)
- **Navigation**: Only minimal stubs are implemented (Navigation.cpp, WalkerManager.cpp). Full Recast/Detour integration is not active.
- **Third-party libraries** (pugixml, odrSpiral) are built separately and linked as `libcarla_third_party.a`

## Troubleshooting

### Common Issues

#### 1. **Recast Headers Not Found (ARM64)**

**Error**: `fatal error: recast/Recast.h: No such file or directory`

**Solution**: The Recast headers use relative symlinks that Docker may not resolve properly. The includes in `LibCarla/source/carla/nav/Navigation.h` should use `<recastnavigation/...>` instead of `<recast/...>`.

```cpp
// Correct includes (already fixed in this repo)
#include <recastnavigation/Recast.h>
#include <recastnavigation/DetourCrowd.h>
```

#### 2. **Wrong Architecture Library Linked**

**Error**: `Relocations in generic ELF (EM: 62)` or `file in wrong format`

**Solution**: Make sure you're using the correct library path for your target architecture:
- x86_64: `build/x86_64/libcarla/install/lib/libcarla_client.a`
- ARM64: `build/aarch64/libcarla/install/lib/libcarla_client.a`

#### 3. **Missing Third-Party Library**

**Error**: Undefined references to `pugi::xml_document` or `odrSpiral::...`

**Solution**: Build and link the third-party library:

```bash
# x86_64
cd build/x86_64/third-party
g++ -std=c++14 -fPIC -O3 -DNDEBUG \
  -c ../../LibCarla/source/third-party/odrSpiral/odrSpiral.cpp -o odrSpiral.o
g++ -std=c++14 -fPIC -O3 -DNDEBUG \
  -c ../../LibCarla/source/third-party/pugixml/pugixml.cpp -o pugixml.o
ar rcs libcarla_third_party.a odrSpiral.o pugixml.o

# ARM64
cd build/aarch64/third-party
aarch64-linux-gnu-g++ -std=c++14 -fPIC -O3 -DNDEBUG \
  -c ../../LibCarla/source/third-party/odrSpiral/odrSpiral.cpp -o odrSpiral.o
aarch64-linux-gnu-g++ -std=c++14 -fPIC -O3 -DNDEBUG \
  -c ../../LibCarla/source/third-party/pugixml/pugixml.cpp -o pugixml.o
aarch64-linux-gnu-ar rcs libcarla_third_party.a odrSpiral.o pugixml.o
```

#### 4. **LibCarla Not Built**

**Error**: Build artifacts missing or empty

**Solution**: Make sure to set `-DLIBCARLA_BUILD_RELEASE=ON` when configuring CMake:

```bash
cmake /workspace/LibCarla/cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DLIBCARLA_BUILD_RELEASE=ON \  # Required!
  -G Ninja
```

Without this flag, only headers are installed, not the actual library.

#### 5. **Boost Not Found (ARM64)**

**Error**: `Could NOT find Boost (missing: Boost_INCLUDE_DIR system filesystem)`

**Solution**: Set `BOOST_ROOT` and disable system paths:

```bash
cmake ... \
  -DBOOST_ROOT=/workspace/deps/aarch64/install/boost-1.84.0 \
  -DBoost_NO_SYSTEM_PATHS=ON
```

### Getting Help

If you encounter issues not listed here:

1. Check the [GitHub Issues](https://github.com/the78mole/carla-simple-client/issues)
2. Review the [Copilot Instructions](.github/copilot-instructions.md) for development details
3. Check the official [CARLA Documentation](https://carla.readthedocs.io/)

## Supported Platforms

This project provides pre-built releases for:

### C++ Clients
- Ubuntu 22.04 LTS (x86_64, ARM64)
- Ubuntu 24.04 LTS (x86_64, ARM64)

### Python Wheels
- Ubuntu 22.04 LTS (x86_64, ARM64)
- Ubuntu 24.04 LTS (x86_64, ARM64)
- macOS 15 (x86_64, ARM64)

Python packages are published to PyPI for easy installation.

**Using uv (recommended):**

```bash
# Install uv if not already installed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install carla-client
uv pip install carla-client
```

**Using pip:**

```bash
pip install carla-client
```

## Usage Examples

### C++ Client

```cpp
#include <carla/client/Client.h>
#include <carla/client/World.h>

int main() {
    // Connect to CARLA server
    auto client = carla::client::Client("localhost", 2000);
    client.SetTimeout(std::chrono::seconds(10));

    // Get the simulation world
    auto world = client.GetWorld();
    
    // Print server info
    std::cout << "Server version: " << client.GetServerVersion() << std::endl;
    
    return 0;
}
```

### Python Client

```python
import carla

# Connect to CARLA server
client = carla.Client('localhost', 2000)
client.set_timeout(10.0)

# Get the simulation world
world = client.get_world()

# Print server info
print(f"Server version: {client.get_server_version()}")
```

## Building Your Own Client

To use LibCarla in your own project, add to your `CMakeLists.txt`:

```cmake
find_package(carla-client REQUIRED)
target_link_libraries(your_app PRIVATE carla::client)
```

Or manually link against the installed libraries:

```cmake
target_include_directories(your_app PRIVATE ${CARLA_INCLUDE_DIR})
target_link_libraries(your_app PRIVATE
    carla_client
    rpc
    boost_filesystem
    Recast Detour DetourCrowd
    png
)
```

## Python Development

### Building Python Wheels

This project uses **uv** for Python package management and building.

**Setup development environment:**

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment and install dependencies
uv venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
uv pip install -e ".[dev]"
```

**Build wheels:**

```bash
# Build wheel for current platform
uv build

# Output will be in dist/
ls dist/
```

**Run tests:**

```bash
uv run pytest
```

**Format and lint:**

```bash
uv run black .
uv run ruff check .
```

### Cross-Platform Wheel Building

For building wheels for multiple platforms (Ubuntu 22.04/24.04, macOS 15), use the CI/CD pipeline or `cibuildwheel`:

```bash
uv pip install cibuildwheel
uv run cibuildwheel --platform linux
```

## Quick Reference

### Build Commands Cheat Sheet

```bash
# Build for x86_64 (native)
make build-x86_64

# Build for ARM64 (cross-compilation)
make build-arm64

# Build for both architectures
make build-all

# Build individual components
make libcarla-x86_64        # Just the library
make third-party-x86_64     # Just third-party libs
make client-x86_64          # Just the client

# ARM64 variants
make libcarla-arm64
make third-party-arm64
make client-arm64

# Test clients
make test-x86_64            # Run x86_64 client
make test-arm64             # Run ARM64 client with QEMU

# Information and cleanup
make info                   # Show build information
make clean-x86_64          # Clean x86_64 builds
make clean-arm64           # Clean ARM64 builds
make clean                 # Clean all builds
```

### Makefile Targets Overview

| Target | Description | Output |
|--------|-------------|--------|
| `build-x86_64` | Complete x86_64 build | LibCarla + client |
| `build-arm64` | Complete ARM64 build | LibCarla + client (cross-compiled) |
| `build-all` | Build both architectures | Both x86_64 and ARM64 |
| `libcarla-x86_64` | Only LibCarla for x86_64 | 11 MB static library |
| `libcarla-arm64` | Only LibCarla for ARM64 | 11 MB static library |
| `client-x86_64` | Only C++ client for x86_64 | 3.8 MB executable |
| `client-arm64` | Only C++ client for ARM64 | 3.6 MB executable |
| `test-x86_64` | Run x86_64 client | Connects to localhost:2000 |
| `test-arm64` | Run ARM64 client (QEMU) | Connects to localhost:2000 |
| `info` | Show build information | Sizes, paths, file types |
| `clean` | Remove all build artifacts | - |
| `help` | Show all available targets | - |

### Key CMake Flags

| Flag | Values | Description |
|------|--------|-------------|
| `CMAKE_BUILD_TYPE` | `Release`, `Debug` | Build configuration |
| `LIBCARLA_BUILD_RELEASE` | `ON`, `OFF` | **Required** to build library (not just headers) |
| `CMAKE_TOOLCHAIN_FILE` | `cmake/toolchain-arm64.cmake` | Cross-compilation toolchain |
| `BOOST_ROOT` | `/path/to/boost` | Boost installation directory |
| `RPCLIB_INCLUDE_PATH` | `/path/to/rpclib/include` | rpclib headers |
| `RECAST_INCLUDE_PATH` | `/path/to/recast/include` | Recast/Detour headers |

### Important Environment Variables

```bash
# For native builds
export BOOST_ROOT=/usr/include/boost
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# For cross-compilation
export CC=aarch64-linux-gnu-gcc
export CXX=aarch64-linux-gnu-g++
export AR=aarch64-linux-gnu-ar
```

## Contributing

Contributions are welcome! Please read the [Copilot Instructions](.github/copilot-instructions.md) for coding conventions and guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The CARLA simulator and LibCarla are licensed under the MIT License by the CARLA team.

## Related Projects

- [CARLA Simulator](https://github.com/carla-simulator/carla) - The main CARLA project
- [CARLA Documentation](https://carla.readthedocs.io/) - Official documentation

## Acknowledgments

- The CARLA team for the excellent autonomous driving simulator
- Contributors to the LibCarla client library
