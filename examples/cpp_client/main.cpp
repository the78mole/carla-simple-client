/**
 * CARLA C++ Client Example
 * 
 * This example demonstrates how to connect to a CARLA server,
 * spawn a vehicle, and control it from C++.
 * 
 * Based on the official CARLA Examples/CppClient example.
 * 
 * Usage: ./carla_cpp_client [host] [port]
 *   host: CARLA server hostname (default: localhost)
 *   port: CARLA server port (default: 2000)
 */

#include <iostream>
#include <random>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <tuple>

#include <carla/client/ActorBlueprint.h>
#include <carla/client/BlueprintLibrary.h>
#include <carla/client/Client.h>
#include <carla/client/Map.h>
#include <carla/client/Sensor.h>
#include <carla/client/TimeoutException.h>
#include <carla/client/World.h>
#include <carla/geom/Transform.h>
#include <carla/sensor/data/Image.h>

// Optional: Image IO support (requires libpng, libjpeg, libtiff)
#if LIBCARLA_IMAGE_WITH_PNG_SUPPORT
#include <carla/image/ImageIO.h>
#include <carla/image/ImageView.h>
#endif

namespace cc = carla::client;
namespace cg = carla::geom;
namespace csd = carla::sensor::data;

using namespace std::chrono_literals;
using namespace std::string_literals;

#define EXPECT_TRUE(pred) if (!(pred)) { throw std::runtime_error(#pred); }

/**
 * Pick a random element from a range.
 */
template <typename RangeT, typename RNG>
static auto &RandomChoice(const RangeT &range, RNG &&generator) {
    EXPECT_TRUE(range.size() > 0u);
    std::uniform_int_distribution<size_t> dist{0u, range.size() - 1u};
    return range[dist(std::forward<RNG>(generator))];
}

/**
 * Parse command line arguments.
 */
static auto ParseArguments(int argc, const char *argv[]) {
    EXPECT_TRUE((argc == 1u) || (argc == 3u));
    using ResultType = std::tuple<std::string, uint16_t>;
    return argc == 3u ?
        ResultType{argv[1u], static_cast<uint16_t>(std::stoi(argv[2u]))} :
        ResultType{"localhost", 2000u};
}

/**
 * Print usage information.
 */
static void PrintUsage(const char *program_name) {
    std::cout << "CARLA C++ Client Example\n"
              << "\n"
              << "Usage: " << program_name << " [host] [port]\n"
              << "  host: CARLA server hostname (default: localhost)\n"
              << "  port: CARLA server port (default: 2000)\n"
              << std::endl;
}

int main(int argc, const char *argv[]) {
    // Check for help flag
    if (argc == 2 && (std::string(argv[1]) == "-h" || std::string(argv[1]) == "--help")) {
        PrintUsage(argv[0]);
        return 0;
    }

    try {
        std::string host;
        uint16_t port;
        std::tie(host, port) = ParseArguments(argc, argv);

        std::cout << "Connecting to CARLA server at " << host << ":" << port << "...\n";

        // Initialize random number generator
        std::mt19937_64 rng((std::random_device())());

        // Create client and connect to server
        auto client = cc::Client(host, port);
        client.SetTimeout(40s);

        std::cout << "Client API version : " << client.GetClientVersion() << '\n';
        std::cout << "Server API version : " << client.GetServerVersion() << '\n';

        // Get the current world
        auto world = client.GetWorld();
        std::cout << "Connected to world: " << world.GetMap()->GetName() << '\n';

        // Get a random vehicle blueprint
        auto blueprint_library = world.GetBlueprintLibrary();
        auto vehicles = blueprint_library->Filter("vehicle");
        auto blueprint = RandomChoice(*vehicles, rng);

        std::cout << "Selected vehicle: " << blueprint.GetId() << '\n';

        // Randomize the vehicle color if available
        if (blueprint.ContainsAttribute("color")) {
            auto &attribute = blueprint.GetAttribute("color");
            blueprint.SetAttribute(
                "color",
                RandomChoice(attribute.GetRecommendedValues(), rng));
        }

        // Find a valid spawn point
        auto map = world.GetMap();
        auto transform = RandomChoice(map->GetRecommendedSpawnPoints(), rng);

        std::cout << "Spawning vehicle at: ("
                  << transform.location.x << ", "
                  << transform.location.y << ", "
                  << transform.location.z << ")\n";

        // Spawn the vehicle
        auto actor = world.SpawnActor(blueprint, transform);
        std::cout << "Spawned " << actor->GetDisplayId() << '\n';
        auto vehicle = boost::static_pointer_cast<cc::Vehicle>(actor);

        // Apply control to vehicle (drive forward)
        cc::Vehicle::Control control;
        control.throttle = 0.5f;
        vehicle->ApplyControl(control);

        std::cout << "Vehicle is moving forward...\n";

        // Move spectator camera to follow the vehicle
        auto spectator = world.GetSpectator();
        transform.location += 32.0f * transform.GetForwardVector();
        transform.location.z += 2.0f;
        transform.rotation.yaw += 180.0f;
        transform.rotation.pitch = -15.0f;
        spectator->SetTransform(transform);

        // Let the simulation run for a few seconds
        std::cout << "Simulation running for 5 seconds...\n";
        std::this_thread::sleep_for(5s);

        // Stop the vehicle
        control.throttle = 0.0f;
        control.brake = 1.0f;
        vehicle->ApplyControl(control);

        std::cout << "Vehicle stopped.\n";
        std::this_thread::sleep_for(2s);

        // Clean up - destroy the vehicle
        vehicle->Destroy();
        std::cout << "Vehicle destroyed.\n";

        std::cout << "Example completed successfully!" << std::endl;

    } catch (const cc::TimeoutException &e) {
        std::cerr << "\nConnection timeout: " << e.what() << '\n';
        std::cerr << "Make sure the CARLA server is running and accessible.\n";
        return 1;
    } catch (const std::exception &e) {
        std::cerr << "\nException: " << e.what() << '\n';
        return 2;
    }

    return 0;
}
