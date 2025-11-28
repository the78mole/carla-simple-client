cmake_minimum_required(VERSION 3.14)
project(carla_cpp_client_window VERSION 0.1.0 LANGUAGES CXX)

# Find LibCarla installation
set(CARLA_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../deps/install/libcarla-client")
set(CARLA_INCLUDE_DIR "${CARLA_INSTALL_DIR}/include")
set(CARLA_LIB_DIR "${CARLA_INSTALL_DIR}/lib")

# Set PNG library paths before find_package
set(PNG_PNG_INCLUDE_DIR "${CARLA_INCLUDE_DIR}/system")
set(PNG_LIBRARY "${CARLA_LIB_DIR}/libpng.a")

find_package(PNG REQUIRED)
find_package(Threads REQUIRED)

# Find OpenCV for image display
find_package(OpenCV REQUIRED COMPONENTS core imgproc highgui)

add_executable(carla_cpp_client_window main.cpp)

target_include_directories(carla_cpp_client_window PRIVATE
    ${CARLA_INCLUDE_DIR}
    ${CARLA_INCLUDE_DIR}/system
)

target_link_libraries(carla_cpp_client_window PRIVATE
    ${CARLA_LIB_DIR}/libcarla_client.a
    ${CARLA_LIB_DIR}/librpc.a
    ${CARLA_LIB_DIR}/libboost_filesystem.a
    ${CARLA_LIB_DIR}/libRecast.a
    ${CARLA_LIB_DIR}/libDetour.a
    ${CARLA_LIB_DIR}/libDetourCrowd.a
    PNG::PNG
    Threads::Threads
    ${OpenCV_LIBS}
)

target_compile_features(carla_cpp_client_window PRIVATE cxx_std_14)
target_compile_definitions(carla_cpp_client_window PRIVATE
    BOOST_ERROR_CODE_HEADER_ONLY
)

# Install the example
install(TARGETS carla_cpp_client_window
    RUNTIME DESTINATION bin
)