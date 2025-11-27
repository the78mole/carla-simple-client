cmake_minimum_required(VERSION 3.14)
project(carla-simple-client VERSION 0.9.16 LANGUAGES C CXX)

# C++ Standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Options
option(BUILD_EXAMPLES "Build example applications" ON)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)

# Default build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "System: ${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}")

# Compiler flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread -fPIC")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-g -O0")

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra")
endif()

# Define paths
set(DEPS_INSTALL_DIR "${CMAKE_SOURCE_DIR}/deps/install" CACHE PATH "Dependencies install directory")
set(LIBCARLA_INSTALL_DIR "${DEPS_INSTALL_DIR}/libcarla-client" CACHE PATH "LibCarla install directory")

# LibCarla source is included in this repository
set(LIBCARLA_SOURCE_DIR "${CMAKE_SOURCE_DIR}/LibCarla" CACHE PATH "LibCarla source directory")

# Check if dependencies are built
if(NOT EXISTS "${LIBCARLA_INSTALL_DIR}/lib/libcarla_client.a")
    message(WARNING "LibCarla not found at ${LIBCARLA_INSTALL_DIR}")
    message(WARNING "Please run ./scripts/setup-dependencies.sh first")
    message(STATUS "LibCarla source is included at: ${LIBCARLA_SOURCE_DIR}")
endif()

# Find dependencies
set(CARLA_INCLUDE_DIR "${LIBCARLA_INSTALL_DIR}/include")
set(CARLA_SYSTEM_INCLUDE_DIR "${LIBCARLA_INSTALL_DIR}/include/system")
set(CARLA_LIB_DIR "${LIBCARLA_INSTALL_DIR}/lib")

# Define CARLA client library as imported target
add_library(carla_client STATIC IMPORTED)
set_target_properties(carla_client PROPERTIES
    IMPORTED_LOCATION "${CARLA_LIB_DIR}/libcarla_client.a"
    INTERFACE_INCLUDE_DIRECTORIES "${CARLA_INCLUDE_DIR};${CARLA_SYSTEM_INCLUDE_DIR}"
)

# rpclib
add_library(rpc STATIC IMPORTED)
set_target_properties(rpc PROPERTIES
    IMPORTED_LOCATION "${CARLA_LIB_DIR}/librpc.a"
)

# Boost libraries
add_library(boost_filesystem STATIC IMPORTED)
set_target_properties(boost_filesystem PROPERTIES
    IMPORTED_LOCATION "${CARLA_LIB_DIR}/libboost_filesystem.a"
)

# Recast navigation libraries
add_library(Recast STATIC IMPORTED)
set_target_properties(Recast PROPERTIES
    IMPORTED_LOCATION "${CARLA_LIB_DIR}/libRecast.a"
)

add_library(Detour STATIC IMPORTED)
set_target_properties(Detour PROPERTIES
    IMPORTED_LOCATION "${CARLA_LIB_DIR}/libDetour.a"
)

add_library(DetourCrowd STATIC IMPORTED)
set_target_properties(DetourCrowd PROPERTIES
    IMPORTED_LOCATION "${CARLA_LIB_DIR}/libDetourCrowd.a"
)

# System libraries
find_package(PNG REQUIRED)
find_package(JPEG)
find_package(TIFF)

# Create an interface library for all CARLA dependencies
add_library(carla_deps INTERFACE)
target_link_libraries(carla_deps INTERFACE
    carla_client
    rpc
    boost_filesystem
    Recast
    Detour
    DetourCrowd
    PNG::PNG
)

if(JPEG_FOUND)
    target_link_libraries(carla_deps INTERFACE JPEG::JPEG)
endif()

if(TIFF_FOUND)
    target_link_libraries(carla_deps INTERFACE TIFF::TIFF)
endif()

target_compile_definitions(carla_deps INTERFACE
    BOOST_ERROR_CODE_HEADER_ONLY
)

# Create alias for convenience
add_library(carla::client ALIAS carla_deps)

# Build examples
if(BUILD_EXAMPLES)
    add_subdirectory(examples/cpp_client)
endif()

# Installation
include(GNUInstallDirs)

# Export targets for use by other projects
install(TARGETS carla_deps
    EXPORT carla-client-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT carla-client-targets
    FILE carla-client-config.cmake
    NAMESPACE carla::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/carla-client
)
