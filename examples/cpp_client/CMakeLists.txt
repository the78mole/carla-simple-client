cmake_minimum_required(VERSION 3.14)
project(carla_cpp_client VERSION 0.1.0 LANGUAGES CXX)

# Allow overriding paths from command line
if(NOT DEFINED CARLA_INCLUDE_DIR)
    set(CARLA_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../build/x86_64/libcarla/install/include")
endif()
if(NOT DEFINED CARLA_LIBRARY)
    set(CARLA_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/../../build/x86_64/libcarla/install/lib/libcarla_client.a")
endif()
if(NOT DEFINED RPCLIB_INCLUDE_DIR)
    set(RPCLIB_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../deps/x86_64/include")
endif()
if(NOT DEFINED RPCLIB_LIBRARY)
    set(RPCLIB_LIBRARY "${CMAKE_CURRENT_SOURCE_DIR}/../../deps/x86_64/lib/librpc.a")
endif()

# Find system libraries
find_package(Boost REQUIRED COMPONENTS system filesystem)
find_package(Threads REQUIRED)

add_executable(cpp_client main.cpp)

target_include_directories(cpp_client PRIVATE
    ${CARLA_INCLUDE_DIR}
    ${RPCLIB_INCLUDE_DIR}
    ${Boost_INCLUDE_DIRS}
)

target_link_libraries(cpp_client PRIVATE
    ${CARLA_LIBRARY}
    ${CMAKE_CURRENT_SOURCE_DIR}/../../build/x86_64/third-party/libcarla_third_party.a
    ${RPCLIB_LIBRARY}
    Boost::system
    Boost::filesystem
    Threads::Threads
)

target_compile_features(cpp_client PRIVATE cxx_std_14)
target_compile_options(cpp_client PRIVATE -pthread -fPIC)
target_compile_definitions(cpp_client PRIVATE
    BOOST_ERROR_CODE_HEADER_ONLY
)

# Install the example
install(TARGETS cpp_client
    RUNTIME DESTINATION bin
)
