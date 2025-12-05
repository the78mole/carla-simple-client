#!/usr/bin/env python3
"""
CARLA Python Client Example

This example demonstrates how to connect to a CARLA server,
spawn a vehicle, and control it from Python.

Usage: python example_client.py [host] [port]
  host: CARLA server hostname (default: localhost)
  port: CARLA server port (default: 2000)
"""

import argparse
import random
import sys
import time

try:
    import carla
except ImportError:
    print("Error: carla module not found.")
    print("Install with: pip install carla-client")
    print("Or run from the repository root with: uv pip install -e .")
    sys.exit(1)


def main():
    """Main function to demonstrate CARLA client usage."""
    parser = argparse.ArgumentParser(description="CARLA Python Client Example")
    parser.add_argument("host", nargs="?", default="localhost", help="CARLA server host")
    parser.add_argument("port", nargs="?", type=int, default=2000, help="CARLA server port")
    parser.add_argument("--timeout", type=float, default=10.0, help="Connection timeout in seconds")
    args = parser.parse_args()

    print(f"Connecting to CARLA server at {args.host}:{args.port}...")

    try:
        # Connect to the CARLA server
        client = carla.Client(args.host, args.port)
        client.set_timeout(args.timeout)

        # Print version info
        print(f"Client API version: {client.get_client_version()}")
        print(f"Server API version: {client.get_server_version()}")

        # Get the world
        world = client.get_world()
        print(f"Connected to world: {world.get_map().name}")

        # Get available vehicle blueprints
        blueprint_library = world.get_blueprint_library()
        vehicle_blueprints = blueprint_library.filter("vehicle.*")

        if not vehicle_blueprints:
            print("No vehicle blueprints available!")
            return 1

        # Choose a random vehicle blueprint
        blueprint = random.choice(vehicle_blueprints)
        print(f"Selected vehicle: {blueprint.id}")

        # Randomize color if available
        if blueprint.has_attribute("color"):
            color = random.choice(blueprint.get_attribute("color").recommended_values)
            blueprint.set_attribute("color", color)

        # Get a spawn point
        spawn_points = world.get_map().get_spawn_points()
        if not spawn_points:
            print("No spawn points available!")
            return 1

        spawn_point = random.choice(spawn_points)
        print(
            f"Spawning at: ({spawn_point.location.x:.1f}, {spawn_point.location.y:.1f}, {spawn_point.location.z:.1f})"
        )

        # Spawn the vehicle
        vehicle = world.spawn_actor(blueprint, spawn_point)
        print(f"Spawned: {vehicle.type_id}")

        # Apply control (drive forward)
        control = carla.VehicleControl()
        control.throttle = 0.5
        vehicle.apply_control(control)

        print("Vehicle is moving forward...")

        # Move spectator to follow the vehicle
        spectator = world.get_spectator()
        transform = vehicle.get_transform()
        transform.location += carla.Location(x=-10, z=5)
        transform.rotation.pitch = -15.0
        spectator.set_transform(transform)

        # Let the simulation run for a bit
        print("Simulation running for 5 seconds...")
        time.sleep(5)

        # Stop the vehicle
        control.throttle = 0.0
        control.brake = 1.0
        vehicle.apply_control(control)
        print("Vehicle stopped.")

        time.sleep(2)

        # Clean up
        vehicle.destroy()
        print("Vehicle destroyed.")
        print("Example completed successfully!")

        return 0

    except RuntimeError as e:
        print(f"\nConnection error: {e}")
        print("Make sure the CARLA server is running and accessible.")
        return 1
    except Exception as e:
        print(f"\nError: {e}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
