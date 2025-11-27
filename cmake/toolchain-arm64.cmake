# ARM64 Linux Cross-Compilation Toolchain
#
# This toolchain file is used for cross-compiling CARLA clients
# for ARM64 (aarch64) Linux targets.
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-arm64.cmake ..

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Cross-compiler settings
# Adjust these paths based on your cross-compiler installation
set(CROSS_COMPILE_PREFIX "aarch64-linux-gnu-")

# Try to find the cross-compiler
find_program(CMAKE_C_COMPILER
    NAMES
        ${CROSS_COMPILE_PREFIX}gcc
        aarch64-linux-gnu-gcc-11
        aarch64-linux-gnu-gcc-10
        aarch64-linux-gnu-gcc-9
    DOC "ARM64 C compiler"
)

find_program(CMAKE_CXX_COMPILER
    NAMES
        ${CROSS_COMPILE_PREFIX}g++
        aarch64-linux-gnu-g++-11
        aarch64-linux-gnu-g++-10
        aarch64-linux-gnu-g++-9
    DOC "ARM64 C++ compiler"
)

if(NOT CMAKE_C_COMPILER OR NOT CMAKE_CXX_COMPILER)
    message(FATAL_ERROR
        "ARM64 cross-compiler not found!\n"
        "Install with: sudo apt-get install g++-aarch64-linux-gnu"
    )
endif()

# Compiler flags
set(CMAKE_C_FLAGS_INIT "-fPIC")
set(CMAKE_CXX_FLAGS_INIT "-std=c++14 -fPIC -pthread")

# Search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Sysroot for cross-compilation (optional)
# Set this if you have a specific ARM64 sysroot
# set(CMAKE_SYSROOT "/path/to/arm64-sysroot")

# pkg-config for cross-compilation
set(ENV{PKG_CONFIG_PATH} "")
set(ENV{PKG_CONFIG_LIBDIR} "${CMAKE_SYSROOT}/usr/lib/aarch64-linux-gnu/pkgconfig:${CMAKE_SYSROOT}/usr/share/pkgconfig")

message(STATUS "ARM64 Cross-Compilation Toolchain")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  C++ Compiler: ${CMAKE_CXX_COMPILER}")
