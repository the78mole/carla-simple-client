// Minimal CARLA client test
#include <iostream>
#include <carla/client/Client.h>

int main() {
    try {
        std::cout << "Connecting to CARLA..." << std::endl;
        carla::client::Client client("localhost", 2000, 2);
        client.SetTimeout(std::chrono::seconds(10));
        
        std::cout << "Client version: " << client.GetClientVersion() << std::endl;
        std::cout << "Server version: " << client.GetServerVersion() << std::endl;
        
        std::cout << "Success!" << std::endl;
        return 0;
    } catch (const std::exception &e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
