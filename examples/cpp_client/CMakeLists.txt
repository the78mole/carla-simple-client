cmake_minimum_required(VERSION 3.14)
project(carla_cpp_client VERSION 0.1.0 LANGUAGES CXX)

# Find parent project's dependencies
# These are defined in the root CMakeLists.txt

add_executable(carla_cpp_client main.cpp)

target_link_libraries(carla_cpp_client PRIVATE
    carla::client
)

target_compile_features(carla_cpp_client PRIVATE cxx_std_14)

# Install the example
install(TARGETS carla_cpp_client
    RUNTIME DESTINATION bin
)
