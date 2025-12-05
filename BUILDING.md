# Building CARLA Simple Client

This guide provides detailed instructions for building the CARLA Simple Client for both x86_64 and ARM64 architectures.

## Quick Start

```bash
# Clone repository
git clone https://github.com/the78mole/carla-simple-client.git
cd carla-simple-client

# Build for x86_64
make build-x86_64

# Or build for both architectures
make build-all
```

## Using the Makefile

The project includes a comprehensive Makefile that handles all build complexities.

### Common Commands

```bash
make help               # Show all available targets
make build-x86_64      # Build complete x86_64 stack
make build-arm64       # Build complete ARM64 stack (cross-compilation)
make build-all         # Build both architectures
make info              # Show detailed build information
make clean             # Remove all build artifacts
```

### Available Targets

#### General
- `help` - Display all available targets with descriptions
- `all` - Build everything (x86_64 + ARM64)

#### x86_64 Builds
- `build-x86_64` - Build complete x86_64 stack (LibCarla + third-party + client)
- `libcarla-x86_64` - Build only LibCarla library for x86_64
- `third-party-x86_64` - Build only third-party libraries for x86_64
- `client-x86_64` - Build only C++ client for x86_64

#### ARM64 Builds
- `build-arm64` - Build complete ARM64 stack (LibCarla + third-party + client)
- `libcarla-arm64` - Build only LibCarla library for ARM64
- `third-party-arm64` - Build only third-party libraries for ARM64
- `client-arm64` - Build only C++ client for ARM64

#### Multi-Architecture
- `build-all` - Build for both x86_64 and ARM64

#### Testing
- `test-x86_64` - Run x86_64 client (requires CARLA server at localhost:2000)
- `test-arm64` - Run ARM64 client with QEMU emulation

#### Information
- `info` - Show detailed build information (sizes, paths, architectures)

#### Cleanup
- `clean-x86_64` - Clean x86_64 build artifacts
- `clean-arm64` - Clean ARM64 build artifacts
- `clean` - Clean all build artifacts
- `clean-all` - Clean everything including dependencies

## Build Process Details

### x86_64 Build Steps

The `make build-x86_64` command performs these steps:

1. **Build LibCarla** (`libcarla-x86_64`)
   - Compiles 115 source files
   - Creates static library: `build/x86_64/libcarla/install/lib/libcarla_client.a` (~11 MB)
   - Build time: ~1:48 (full), ~5s (incremental)

2. **Build Third-Party** (`third-party-x86_64`)
   - Compiles pugixml and odrSpiral
   - Creates: `build/x86_64/third-party/libcarla_third_party.a` (~372 KB)

3. **Build Client** (`client-x86_64`)
   - Links everything together
   - Creates: `examples/cpp_client/cpp_client` (~3.8 MB)

### ARM64 Build Steps

The `make build-arm64` command performs cross-compilation:

1. **Build LibCarla ARM64** (`libcarla-arm64`)
   - Uses ARM64 cross-compiler (aarch64-linux-gnu-g++)
   - Creates: `build/aarch64/libcarla/install/lib/libcarla_client.a` (~11 MB)
   - Uses pre-built dependencies from `deps/aarch64/install/`

2. **Build Third-Party ARM64** (`third-party-arm64`)
   - Cross-compiles pugixml and odrSpiral
   - Creates: `build/aarch64/third-party/libcarla_third_party.a` (~324 KB)

3. **Build Client ARM64** (`client-arm64`)
   - Cross-links for ARM64
   - Creates: `build/aarch64/cpp_client/cpp_client` (~3.6 MB)

## Docker Images

The build system uses two Docker images:

- **carla-x86_64-native:ubuntu-22.04** - For native x86_64 builds
- **carla-arm64-builder:latest** - For ARM64 cross-compilation

These images include all necessary compilers and tools.

## Build Artifacts

### Directory Structure

```
carla-simple-client/
├── build/
│   ├── x86_64/
│   │   ├── libcarla/
│   │   │   └── install/lib/libcarla_client.a    # 11 MB
│   │   └── third-party/
│   │       └── libcarla_third_party.a            # 372 KB
│   └── aarch64/
│       ├── libcarla/
│       │   └── install/lib/libcarla_client.a    # 11 MB
│       ├── third-party/
│       │   └── libcarla_third_party.a            # 324 KB
│       └── cpp_client/
│           └── cpp_client                        # 3.6 MB (ARM64)
├── examples/
│   └── cpp_client/
│       └── cpp_client                            # 3.8 MB (x86_64)
└── deps/
    ├── x86_64/                                   # x86_64 dependencies
    └── aarch64/                                  # ARM64 dependencies
```

### Verifying Builds

```bash
# Check file types
file examples/cpp_client/cpp_client
# Output: ELF 64-bit LSB pie executable, x86-64, ...

file build/aarch64/cpp_client/cpp_client
# Output: ELF 64-bit LSB pie executable, ARM aarch64, ...

# Check sizes
ls -lh examples/cpp_client/cpp_client
ls -lh build/aarch64/cpp_client/cpp_client

# Or use make info
make info
```

## VS Code Integration

Build tasks are pre-configured in `.vscode/tasks.json`:

- **Press `Ctrl+Shift+B`** (or `Cmd+Shift+B` on macOS) to build x86_64 (default)
- **Press `Ctrl+Shift+P`** → "Tasks: Run Task" to access all build tasks:
  - Build x86_64
  - Build ARM64
  - Build All (x86_64 + ARM64)
  - Build LibCarla x86_64/ARM64
  - Test x86_64 Client
  - Show Build Info
  - Clean x86_64/ARM64/All

## Building Python Wheels

### Prerequisites

Python wheels require LibCarla to be built with `-fPIC` flag, which is automatically handled by the build system.

### x86_64 Python Wheel

Build a Python wheel for x86_64:

```bash
make wheel-x86_64
```

This will:
1. Build LibCarla with position-independent code (`-fPIC`)
2. Copy all required libraries to `deps/install/`:
   - `libcarla_client.a` (11 MB)
   - `librpc.a`, `libRecast.a`, `libDetour.a`, `libDetourCrowd.a`
   - `libboost_filesystem.a`, `libboost_python310.a`
   - `libpng.a`
3. Copy all headers (carla/* and system headers)
4. Build the wheel using Docker with `python3 -m build --wheel`

**Output**: `dist/carla_client-0.9.16-cp310-cp310-linux_x86_64.whl` (~38 MB)

### ARM64 Python Wheel

⚠️ **Note**: ARM64 Python wheels require `boost_python` library for ARM64, which is not currently included in the ARM64 dependencies.

To build ARM64 wheel (when dependencies are available):

```bash
make wheel-arm64
```

### Installing a Wheel

Install the built wheel:

```bash
pip install dist/carla_client-0.9.16-cp310-cp310-linux_x86_64.whl
```

Or in a virtual environment:

```bash
python3 -m venv carla_env
source carla_env/bin/activate
pip install dist/carla_client-0.9.16-*.whl
python -c "import carla; print(carla.__version__)"  # Should print: 0.9.16
```

### Testing the Python Client

After installation, test the Python client:

```bash
# In a terminal with CARLA server running on localhost:2000
python examples/python_client/manual_control.py
```

### Clean Python Artifacts

Remove all Python build artifacts:

```bash
make clean-python
```

This removes:
- `dist/` - Built wheel files
- `*.egg-info` - Package metadata
- `deps/install/` - Prepared dependencies for Python build
- `__pycache__`, `*.pyc`, `*.so` - Python cache files

## Troubleshooting

### Dependencies Missing

If dependencies are not built, run:

```bash
./scripts/setup-dependencies.sh
```

This builds:
- Boost 1.84.0 (ARM64 only, x86_64 uses system)
- rpclib v2.2.1_c5
- Recast/Detour 1.6.0
- libpng 1.6.37

### Docker Image Not Found

Build the required Docker images:

```bash
# For x86_64
docker build -t carla-x86_64-native:ubuntu-22.04 build-containers/x86_64-native-ubuntu-22.04/

# For ARM64
docker build -t carla-arm64-builder:latest build-containers/x86_64-cross-arm64-ubuntu-22.04/
```

### Clean Build

If you encounter issues, try a clean rebuild:

```bash
make clean
make build-x86_64
```

For a complete clean including dependencies:

```bash
make clean-all
./scripts/setup-dependencies.sh
make build-x86_64
```

### Incremental Builds

The Makefile supports incremental builds. After the initial full build, only changed files will be recompiled:

```bash
# Initial build (1-2 minutes)
make build-x86_64

# Modify a source file
touch LibCarla/source/carla/client/Actor.cpp

# Incremental rebuild (5-10 seconds)
make build-x86_64
```

## Manual Build (Advanced)

If you need to customize the build beyond what the Makefile provides, you can build manually:

### x86_64 Manual Build

```bash
# 1. Build LibCarla
mkdir -p build/x86_64/libcarla
cd build/x86_64/libcarla
cmake ../../../LibCarla/cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DLIBCARLA_BUILD_RELEASE=ON \
  -G Ninja
ninja install

# 2. Build third-party
mkdir -p ../third-party
cd ../third-party
g++ -std=c++14 -fPIC -O3 -DNDEBUG \
  -c ../../../LibCarla/source/third-party/odrSpiral/odrSpiral.cpp
g++ -std=c++14 -fPIC -O3 -DNDEBUG \
  -c ../../../LibCarla/source/third-party/pugixml/pugixml.cpp
ar rcs libcarla_third_party.a odrSpiral.o pugixml.o

# 3. Build client
cd ../../../examples/cpp_client
g++ -std=c++14 -pthread -fPIC -O3 -DNDEBUG \
  -DBOOST_ERROR_CODE_HEADER_ONLY \
  -I../../build/x86_64/libcarla/install/include \
  -I../../deps/x86_64/include \
  -o cpp_client main.cpp \
  ../../build/x86_64/libcarla/install/lib/libcarla_client.a \
  ../../build/x86_64/third-party/libcarla_third_party.a \
  ../../deps/x86_64/lib/librpc.a \
  -lboost_filesystem -lboost_system -lpng -lz
```

### ARM64 Manual Build

See the Makefile for the complete ARM64 build commands with all dependency paths.

## CMake Options

Key CMake options for LibCarla:

| Option | Values | Description |
|--------|--------|-------------|
| `CMAKE_BUILD_TYPE` | `Release`, `Debug` | Build configuration |
| `LIBCARLA_BUILD_RELEASE` | `ON`, `OFF` | **Required** to build library (not just headers) |
| `CMAKE_TOOLCHAIN_FILE` | Path | For cross-compilation (ARM64) |
| `BOOST_INCLUDE_PATH` | Path | Boost headers location |
| `RPCLIB_INCLUDE_PATH` | Path | rpclib headers location |
| `RECAST_INCLUDE_PATH` | Path | Recast/Detour headers location |
| `LIBPNG_INCLUDE_PATH` | Path | libpng headers location |

## Performance Tips

1. **Use Ninja** instead of Make for faster builds
2. **Incremental builds** are much faster than clean builds
3. **Parallel builds** are automatic with Docker (uses all CPU cores)
4. **Build only what you need**:
   - `make libcarla-x86_64` if you only changed library code
   - `make client-x86_64` if you only changed client code

## Next Steps

After building:

1. **Test the client**: `make test-x86_64`
2. **View build info**: `make info`
3. **Read usage examples**: See main README.md
4. **Develop your EABS**: Modify `examples/cpp_client/main.cpp`

## Additional Resources

- [README.md](README.md) - Main project documentation
- [Copilot Instructions](.github/copilot-instructions.md) - Development guidelines
- [CARLA Documentation](https://carla.readthedocs.io/) - Official CARLA docs
