# CARLA Simple Client

A standalone repository for building CARLA simulator clients **outside** the main CARLA source tree. This project targets the `ue4/0.9.16` branch of CARLA and supports multiple platforms including ARM64/x86_64 Linux and macOS.

## Overview

Building CARLA clients normally requires cloning the entire CARLA repository and building within its source tree. This project provides:

- **Complete LibCarla sources included**: No need to clone the CARLA repository
- **Out-of-tree building**: Build clients independently
- **Multi-platform support**: ARM64 & x86_64 on Linux (Ubuntu 22.04+, 24.04+) and macOS 15
- **Simplified dependencies**: Automated setup for required libraries
- **Example code**: Ready-to-use C++ and Python client examples

## Quick Start

### Prerequisites

- CMake 3.14+
- GCC 9+ or Clang 10+
- Git
- Ninja (recommended) or Make
- wget, tar, unzip
- **Python 3.8+** (for Python client)
- **uv** (recommended for Python package management)

### Ubuntu/Debian Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential cmake ninja-build git wget \
    libpng-dev libtiff-dev libjpeg-dev \
    autoconf automake libtool
```

### Building

1. **Clone this repository:**
   ```bash
   git clone https://github.com/the78mole/carla-simple-client.git
   cd carla-simple-client
   ```

2. **Setup dependencies:**
   ```bash
   ./scripts/setup-dependencies.sh
   ```

3. **Build the example client:**
   ```bash
   mkdir build && cd build
   cmake -G Ninja ..
   ninja
   ```

4. **Run the client** (requires a running CARLA server):
   ```bash
   ./examples/cpp_client/carla_cpp_client localhost 2000
   ```

## ARM64 Cross-Compilation

For building on ARM64 Linux targets:

```bash
mkdir build-arm64 && cd build-arm64
cmake -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-arm64.cmake \
    ..
ninja
```

Note: You'll need an ARM64 cross-compiler installed (e.g., `aarch64-linux-gnu-gcc`).

## Project Structure

```
carla-simple-client/
├── .github/
│   └── copilot-instructions.md  # Development guidelines
├── LibCarla/                    # CARLA client library sources (from ue4/0.9.16)
│   ├── cmake/                   # CMake build configuration
│   └── source/                  # C++ source code
├── cmake/
│   ├── toolchain-arm64.cmake    # ARM64 cross-compilation
│   └── toolchain-x86_64.cmake   # Native x86_64 build
├── scripts/
│   └── setup-dependencies.sh    # Dependency setup script
├── examples/
│   ├── cpp_client/              # Example C++ client
│   └── python_client/           # Example Python client (planned)
├── CMakeLists.txt               # Main CMake configuration
├── README.md                    # This file
└── LICENSE                      # MIT License
```

## Target CARLA Version

- **Branch**: [`ue4/0.9.16`](https://github.com/carla-simulator/carla/tree/ue4/0.9.16)
- **LibCarla Source**: Included in `LibCarla/` directory (extracted from official CARLA repository)

## Dependencies

This project uses the following libraries:

| Library | Version | Description |
|---------|---------|-------------|
| Boost | 1.84.0 | C++ utilities (filesystem, python, etc.) |
| rpclib | v2.2.1_c5 | RPC for client-server communication |
| Recast/Detour | carla fork | Navigation mesh generation |
| libpng | 1.6.37 | PNG image support |
| xerces-c | 3.2.3 | XML parsing |
| PROJ | 7.2.1 | Coordinate transformations |

## Supported Platforms

This project provides pre-built releases for:

### C++ Clients
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
