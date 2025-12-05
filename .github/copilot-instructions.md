# Copilot Instructions for CARLA Simple Client

This document provides guidelines for GitHub Copilot and developers working on this project.

## Project Overview

This repository enables building CARLA simulator clients **externally** from the main CARLA source tree, specifically targeting the `ue4/0.9.16` branch. The primary goal is to simplify client development, especially on **ARM64 Linux** platforms.

It also contains some examples of Python and C++ clients.

**Key Feature**: LibCarla sources are included directly in this repository, so there's no need to clone the main CARLA repository.

## Target CARLA Version

- **Branch**: `ue4/0.9.16`
- **Repository**: https://github.com/carla-simulator/carla/tree/ue4/0.9.16

## Architecture Support

- **Primary Target**: ARM64 Linux (aarch64-linux-gnu)
- **Secondary Target**: x86_64 Linux
- **Release Targets**: 
  - Ubuntu 22.04 LTS (x86_64, ARM64)
  - Ubuntu 24.04 LTS (x86_64, ARM64)
  - macOS 15 (x86_64, ARM64)
- **Future Consideration**: Windows

## Directory Structure

```
carla-simple-client/
├── .github/
│   ├── copilot-instructions.md  # This file
│   └── workflows/               # GitHub Actions CI/CD workflows
├── build-containers/
│   └── x86_64-cross-arm64-ubuntu-22.04/  # ARM64 cross-compilation container
│       ├── Dockerfile
│       ├── build-arm64-deps.sh  # Automated dependency building script
│       └── arm64-toolchain.cmake # ARM64 cross-compilation toolchain
├── LibCarla/                    # CARLA client library sources (included)
│   ├── cmake/                   # CMake build configuration
│   └── source/                  # C++ source code
├── PythonAPI/                   # Python API bindings
│   └── source/                  # CARLA Python package sources
├── cmake/
│   ├── toolchain-arm64.cmake    # ARM64 cross-compilation toolchain
│   └── toolchain-x86_64.cmake   # x86_64 native toolchain
├── deps/                        # Architecture-specific dependencies
│   ├── x86_64/                  # Native x86_64 dependencies
│   └── aarch64/                 # ARM64 cross-compiled dependencies
├── build/                       # Architecture-specific build outputs
│   ├── x86_64/                  # Native x86_64 builds
│   └── aarch64/                 # ARM64 cross-compiled builds
├── scripts/
│   └── setup-dependencies.sh    # Script to build dependencies
├── examples/
│   ├── cpp_client/              # Example C++ client
│   │   ├── CMakeLists.txt
│   │   └── main.cpp
│   ├── cpp_client_window/       # C++ client with OpenCV window rendering
│   ├── python_client/           # Example Python client
│   └── python_client_window/    # Python client with pygame window rendering
├── tests/                       # Test suite
├── CMakeLists.txt               # Main CMake configuration
├── pyproject.toml               # Python project configuration (PEP 517/518)
├── README.md                    # Project documentation
└── LICENSE                      # MIT License
```

## Dependencies

### C++ Dependencies

The following dependencies are required from CARLA's build system:

1. **Boost** (1.84.0) - C++ libraries for networking, filesystem, etc.
2. **rpclib** (v2.2.1_c5) - RPC library for client-server communication
3. **Recast/Detour** - Navigation mesh library
4. **libpng** (1.6.37) - PNG image support
5. **pugixml** - XML parsing (bundled with LibCarla source)

### Python Dependencies

Python package requirements (defined in `pyproject.toml`):

1. **numpy** (>=1.19.0) - Numerical computing
2. **pillow** (>=8.0.0) - Image processing
3. **uv** - Fast Python package manager (recommended for development)

## Coding Conventions

### C++ Standards
- Use **C++14** standard (`-std=c++14`)
- Enable position-independent code (`-fPIC`)
- Use pthread for threading (`-pthread`)

### Compiler Flags (Release)
```cmake
-std=c++14 -pthread -fPIC -O3 -DNDEBUG -Wall -Wextra
```

### Python Standards
- Target **Python 3.8+** for broad compatibility
- Use **type hints** where appropriate
- Follow **PEP 8** style guide (enforced by `black` and `ruff`)
- Line length: **100 characters**
- Use **uv** for package management and building

### Python Code Style
```python
# Format with black
black --line-length 100 .

# Lint with ruff
ruff check .

# Type check with mypy
mypy carla/
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

### Python Build Guidelines
- Use **uv** for dependency management and building
- Follow **PEP 517/518** standards (defined in `pyproject.toml`)
- Use **setuptools** as build backend
- Include **cibuildwheel** configuration for multi-platform builds
- Ensure native extensions are compiled for target architectures

#### Building Python Wheels with uv
```bash
# Setup environment
uv venv
source .venv/bin/activate

# Install in development mode
uv pip install -e ".[dev]"

# Build wheel
uv build

# Run tests
uv run pytest
```

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

## Releases

All clients shall be published as Github Releases, built for 
- ubuntu (24.04) linux x86_64 & arm64 

For the Python clients, it should create wheels packages that have pre-built the C/C++ glue parts for:
- ubuntu (22.04) linux x86_64 & arm64
- ubuntu (24.04) linux x86_64 & arm64
- macosx 15 x86_64 & arm64

All artifacts shall be published with semantic versioning (using paulhatch's action) by a release workflow.

Python packages shall be published to PyPi.

Publishing packages is disabled when running with act, but artifacts will be uploaded to the act local artifact server.

## Testing

### Manual Testing
Since this is a client library, testing requires a running CARLA server:
1. Start a CARLA server on the target machine or network
2. Run the C++ example client: `./cpp_client <host> <port>`
3. Run the Python example client: `python example_client.py <host> <port>`

### Connection Testing
Default connection settings:
- Host: `localhost`
- Port: `2000`
- Timeout: `40s`

### Python Wheel Testing
For testing Python wheels on different platforms:
1. Build wheels for target platform (Ubuntu 22.04/24.04, macOS 15)
2. Install wheel in isolated environment: `pip install carla-*.whl`
3. Run test scripts to verify functionality
4. Test on both x86_64 and ARM64 architectures

## Future Improvements

- [ ] Add Docker-based build environment
- [ ] Add CI/CD for automated testing
- [ ] Add pre-built dependency packages
- [ ] Support for Windows MSVC builds
- [ ] Add automated wheel building for Python packages
