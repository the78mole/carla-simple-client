/**
 * CARLA C++ Client with OpenCV Window Display
 *
 * This example demonstrates how to connect to a CARLA server,
 * spawn a vehicle with a camera sensor, and display the camera
 * feed in a window using OpenCV.
 *
 * Dependencies: OpenCV 4.x
 * Usage: ./carla_cpp_client_window [host] [port]
 */

#include <iostream>
#include <memory>
#include <random>
#include <string>
#include <thread>

#include <opencv2/opencv.hpp>

#include <carla/client/ActorBlueprint.h>
#include <carla/client/BlueprintLibrary.h>
#include <carla/client/Client.h>
#include <carla/client/Map.h>
#include <carla/client/Sensor.h>
#include <carla/client/TimeoutException.h>
#include <carla/client/World.h>
#include <carla/geom/Transform.h>
#include <carla/sensor/data/Image.h>

namespace cc = carla::client;
namespace cg = carla::geom;
namespace csd = carla::sensor::data;

// Global variables for display
cv::Mat current_frame;
bool frame_ready = false;
std::mutex frame_mutex;

void camera_callback(boost::shared_ptr<csd::Image> image) {
    std::lock_guard<std::mutex> lock(frame_mutex);
    
    // Convert CARLA image to OpenCV Mat
    auto color_array = boost::make_shared<csd::Color[]>(image->size());
    std::memcpy(color_array.get(), image->data(), image->size() * sizeof(csd::Color));
    
    // Create OpenCV Mat from CARLA image data (RGBA -> BGR)
    cv::Mat carla_mat(image->GetHeight(), image->GetWidth(), CV_8UC4, (void*)color_array.get());
    cv::cvtColor(carla_mat, current_frame, cv::COLOR_RGBA2BGR);
    
    frame_ready = true;
}

int main(int argc, char *argv[]) {
    std::string host = (argc > 1) ? argv[1] : "localhost";
    uint16_t port = (argc > 2) ? static_cast<uint16_t>(std::stoi(argv[2])) : 2000u;

    try {
        std::cout << "Connecting to CARLA server at " << host << ":" << port << "...\n";
        
        // Connect to server
        auto client = cc::Client(host, port);
        client.SetTimeout(std::chrono::seconds(40));
        
        std::cout << "Client API version: " << client.GetClientVersion() << std::endl;
        std::cout << "Server API version: " << client.GetServerVersion() << std::endl;
        
        // Get world and spawn points
        auto world = client.GetWorld();
        auto blueprint_library = world.GetBlueprintLibrary();
        auto spawn_points = world.GetMap()->GetRecommendedSpawnPoints();
        
        if (spawn_points.empty()) {
            std::cerr << "No spawn points available!\n";
            return 1;
        }
        
        // Spawn a vehicle
        auto vehicle_blueprints = blueprint_library->Filter("vehicle.*");
        if (vehicle_blueprints->empty()) {
            std::cerr << "No vehicle blueprints available!\n";
            return 1;
        }
        
        auto vehicle_bp = (*vehicle_blueprints)[0];
        auto vehicle_transform = spawn_points[0];
        
        std::cout << "Spawning vehicle: " << vehicle_bp.GetId() << std::endl;
        auto vehicle = world.SpawnActor(vehicle_bp, vehicle_transform);
        
        // Create camera sensor
        auto camera_bp = blueprint_library->Find("sensor.camera.rgb");
        camera_bp.SetAttribute("image_size_x", "800");
        camera_bp.SetAttribute("image_size_y", "600");
        camera_bp.SetAttribute("fov", "90.0");
        
        // Position camera on top of vehicle
        cg::Transform camera_transform(
            cg::Location(0.0f, 0.0f, 2.0f),  // 2m above vehicle
            cg::Rotation(0.0f, 0.0f, 0.0f)
        );
        
        std::cout << "Spawning camera sensor...\n";
        auto camera = world.SpawnActor(camera_bp, camera_transform, vehicle.get());
        
        // Cast to sensor and start listening
        auto camera_sensor = boost::static_pointer_cast<cc::Sensor>(camera);
        camera_sensor->Listen(camera_callback);
        
        std::cout << "Camera sensor started. Press ESC to exit.\n";
        
        // Create OpenCV window
        cv::namedWindow("CARLA Camera Feed", cv::WINDOW_AUTOSIZE);
        
        // Main display loop
        while (true) {
            {
                std::lock_guard<std::mutex> lock(frame_mutex);
                if (frame_ready && !current_frame.empty()) {
                    cv::imshow("CARLA Camera Feed", current_frame);
                    frame_ready = false;
                }
            }
            
            // Check for ESC key
            int key = cv::waitKey(30);
            if (key == 27) { // ESC key
                break;
            }
        }
        
        // Cleanup
        camera->Destroy();
        vehicle->Destroy();
        cv::destroyAllWindows();
        
        std::cout << "Cleanup completed. Goodbye!\n";
        
    } catch (const cc::TimeoutException &e) {
        std::cerr << "Timeout: " << e.what() << std::endl;
        return 1;
    } catch (const std::exception &e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}