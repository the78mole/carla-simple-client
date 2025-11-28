#!/usr/bin/env python3
"""
CARLA Python Client with Window Display

This example demonstrates how to connect to a CARLA server,
spawn a vehicle with a camera sensor, and display the camera
feed in a window using pygame.

Dependencies: pygame, numpy
Usage: python example_client_window.py [host] [port]
"""

import argparse
import numpy as np
import pygame
import sys
import time
from queue import Queue, Empty

try:
    import carla
except ImportError:
    print("Error: carla module not found.")
    print("Install with: pip install carla-client")
    sys.exit(1)


class CameraManager:
    """Manages camera sensor and image display."""
    
    def __init__(self, world, vehicle, width=800, height=600):
        self.world = world
        self.vehicle = vehicle
        self.width = width
        self.height = height
        self.image_queue = Queue()
        self.camera = None
        
        # Setup pygame
        pygame.init()
        self.display = pygame.display.set_mode((width, height))
        pygame.display.set_caption('CARLA Camera Feed')
        
    def setup_camera(self):
        """Setup and attach camera sensor to vehicle."""
        blueprint_library = self.world.get_blueprint_library()
        camera_bp = blueprint_library.find('sensor.camera.rgb')
        
        # Configure camera
        camera_bp.set_attribute('image_size_x', str(self.width))
        camera_bp.set_attribute('image_size_y', str(self.height))
        camera_bp.set_attribute('fov', '90.0')
        
        # Position camera on top of vehicle
        camera_transform = carla.Transform(
            carla.Location(x=0.0, y=0.0, z=2.0),  # 2m above vehicle
            carla.Rotation(pitch=0.0, yaw=0.0, roll=0.0)
        )
        
        # Spawn camera
        self.camera = self.world.spawn_actor(
            camera_bp, camera_transform, attach_to=self.vehicle
        )
        
        # Start listening for images
        self.camera.listen(self._on_image_received)
        print("Camera sensor started")
        
    def _on_image_received(self, image):
        """Callback for receiving camera images."""
        self.image_queue.put(image)
        
    def render(self):
        """Render the latest camera image to pygame display."""
        try:
            # Get the latest image (non-blocking)
            image = self.image_queue.get_nowait()
            
            # Convert CARLA image to numpy array
            array = np.frombuffer(image.raw_data, dtype=np.dtype("uint8"))
            array = np.reshape(array, (image.height, image.width, 4))
            array = array[:, :, :3]  # Remove alpha channel
            array = array[:, :, ::-1]  # BGR to RGB
            
            # Convert to pygame surface and display
            surface = pygame.surfarray.make_surface(array.swapaxes(0, 1))
            self.display.blit(surface, (0, 0))
            pygame.display.flip()
            
        except Empty:
            # No new image available
            pass
            
    def cleanup(self):
        """Clean up resources."""
        if self.camera:
            self.camera.destroy()
        pygame.quit()


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="CARLA Python Client with Window")
    parser.add_argument("host", nargs="?", default="localhost", help="CARLA server host")
    parser.add_argument("port", nargs="?", type=int, default=2000, help="CARLA server port")
    parser.add_argument("--timeout", type=float, default=10.0, help="Connection timeout")
    args = parser.parse_args()

    try:
        print(f"Connecting to CARLA server at {args.host}:{args.port}...")
        
        # Connect to CARLA server
        client = carla.Client(args.host, args.port)
        client.set_timeout(args.timeout)
        
        print(f"Client API version: {client.get_client_version()}")
        print(f"Server API version: {client.get_server_version()}")
        
        # Get world and spawn points
        world = client.get_world()
        blueprint_library = world.get_blueprint_library()
        spawn_points = world.get_map().get_spawn_points()
        
        if not spawn_points:
            print("No spawn points available!")
            return 1
            
        # Spawn a vehicle
        vehicle_blueprints = blueprint_library.filter("vehicle.*")
        if not vehicle_blueprints:
            print("No vehicle blueprints available!")
            return 1
            
        vehicle_bp = vehicle_blueprints[0]
        vehicle_transform = spawn_points[0]
        
        print(f"Spawning vehicle: {vehicle_bp.id}")
        vehicle = world.spawn_actor(vehicle_bp, vehicle_transform)
        
        # Setup camera manager
        camera_manager = CameraManager(world, vehicle)
        camera_manager.setup_camera()
        
        print("Display window opened. Press ESC or close window to exit.")
        
        # Main loop
        clock = pygame.time.Clock()
        running = True
        
        while running:
            # Handle pygame events
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        running = False
                        
            # Render camera feed
            camera_manager.render()
            
            # Control FPS
            clock.tick(30)
            
        # Cleanup
        camera_manager.cleanup()
        vehicle.destroy()
        print("Cleanup completed. Goodbye!")
        
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