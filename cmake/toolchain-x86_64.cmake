# x86_64 Native Linux Toolchain
#
# This toolchain file is used for native x86_64 Linux builds.
# It provides consistent compiler settings across different systems.
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-x86_64.cmake ..

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Try to find GCC 9 or higher first, then fall back to system default
find_program(CMAKE_C_COMPILER
    NAMES gcc-11 gcc-10 gcc-9 gcc
    DOC "C compiler"
)

find_program(CMAKE_CXX_COMPILER
    NAMES g++-11 g++-10 g++-9 g++
    DOC "C++ compiler"
)

# Alternatively, use Clang if preferred
# find_program(CMAKE_C_COMPILER NAMES clang-12 clang-11 clang-10 clang)
# find_program(CMAKE_CXX_COMPILER NAMES clang++-12 clang++-11 clang++-10 clang++)

# Compiler flags
set(CMAKE_C_FLAGS_INIT "-fPIC")
set(CMAKE_CXX_FLAGS_INIT "-std=c++14 -fPIC -pthread")

# Enable warnings
set(CMAKE_CXX_FLAGS_INIT "${CMAKE_CXX_FLAGS_INIT} -Wall -Wextra")

message(STATUS "x86_64 Native Toolchain")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  C++ Compiler: ${CMAKE_CXX_COMPILER}")
