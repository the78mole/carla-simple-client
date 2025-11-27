"""
CARLA Python Client Library

This module provides Python bindings for the CARLA simulator client library.
It wraps the LibCarla C++ library to provide a Pythonic interface for
interacting with the CARLA simulator.

Target CARLA Version: 0.9.16 (ue4/0.9.16 branch)
"""

__version__ = "0.9.16"
__all__ = [
    "Client",
    "World",
    "BlueprintLibrary",
    "ActorBlueprint",
    "Actor",
    "Vehicle",
    "Walker",
    "Sensor",
    "TrafficLight",
    "TrafficSign",
    "Map",
    "Waypoint",
    "Location",
    "Rotation",
    "Transform",
    "Vector3D",
    "Color",
    "VehicleControl",
    "WalkerControl",
    "command",
]

# Import native extension (will be built from C++ sources)
try:
    from carla._carla import *  # noqa: F401, F403
except ImportError as e:
    import sys
    import warnings
    
    warnings.warn(
        f"Native carla module not found: {e}\n"
        "The native C++ extension has not been built. "
        "Please build the extension using:\n"
        "  uv pip install -e .\n"
        "or install the pre-built wheel:\n"
        "  uv pip install carla-client",
        ImportWarning,
    )
    
    # Provide stub classes for development/documentation purposes
    # These will be replaced by the native implementation when built
    
    class Location:
        """Represents a 3D location in the world."""
        
        def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
            self.x = x
            self.y = y
            self.z = z
        
        def __repr__(self) -> str:
            return f"Location(x={self.x}, y={self.y}, z={self.z})"
    
    class Rotation:
        """Represents a rotation in 3D space (pitch, yaw, roll)."""
        
        def __init__(self, pitch: float = 0.0, yaw: float = 0.0, roll: float = 0.0):
            self.pitch = pitch
            self.yaw = yaw
            self.roll = roll
        
        def __repr__(self) -> str:
            return f"Rotation(pitch={self.pitch}, yaw={self.yaw}, roll={self.roll})"
    
    class Transform:
        """Represents a transformation (location + rotation)."""
        
        def __init__(self, location: Location = None, rotation: Rotation = None):
            self.location = location or Location()
            self.rotation = rotation or Rotation()
        
        def __repr__(self) -> str:
            return f"Transform({self.location}, {self.rotation})"
    
    class Vector3D:
        """Represents a 3D vector."""
        
        def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
            self.x = x
            self.y = y
            self.z = z
        
        def __repr__(self) -> str:
            return f"Vector3D(x={self.x}, y={self.y}, z={self.z})"
    
    class Color:
        """Represents an RGBA color."""
        
        def __init__(self, r: int = 0, g: int = 0, b: int = 0, a: int = 255):
            self.r = r
            self.g = g
            self.b = b
            self.a = a
        
        def __repr__(self) -> str:
            return f"Color(r={self.r}, g={self.g}, b={self.b}, a={self.a})"
    
    class VehicleControl:
        """Control commands for a vehicle."""
        
        def __init__(self):
            self.throttle: float = 0.0
            self.steer: float = 0.0
            self.brake: float = 0.0
            self.hand_brake: bool = False
            self.reverse: bool = False
            self.manual_gear_shift: bool = False
            self.gear: int = 0
    
    class WalkerControl:
        """Control commands for a walker (pedestrian)."""
        
        def __init__(self):
            self.direction = Vector3D(1.0, 0.0, 0.0)
            self.speed: float = 0.0
            self.jump: bool = False
    
    class Actor:
        """Base class for all actors in the simulation."""
        
        def __init__(self):
            self.id: int = 0
            self.type_id: str = ""
            self.is_alive: bool = False
        
        def get_transform(self) -> Transform:
            """Get the current transform of the actor."""
            raise NotImplementedError("Native extension not loaded")
        
        def set_transform(self, transform: Transform) -> None:
            """Set the transform of the actor."""
            raise NotImplementedError("Native extension not loaded")
        
        def destroy(self) -> bool:
            """Destroy the actor."""
            raise NotImplementedError("Native extension not loaded")
    
    class Vehicle(Actor):
        """A vehicle actor in the simulation."""
        
        def apply_control(self, control: VehicleControl) -> None:
            """Apply control to the vehicle."""
            raise NotImplementedError("Native extension not loaded")
    
    class Walker(Actor):
        """A walker (pedestrian) actor in the simulation."""
        
        def apply_control(self, control: WalkerControl) -> None:
            """Apply control to the walker."""
            raise NotImplementedError("Native extension not loaded")
    
    class Sensor(Actor):
        """A sensor actor in the simulation."""
        
        def listen(self, callback) -> None:
            """Register a callback for sensor data."""
            raise NotImplementedError("Native extension not loaded")
        
        def stop(self) -> None:
            """Stop the sensor from generating data."""
            raise NotImplementedError("Native extension not loaded")
    
    class TrafficLight(Actor):
        """A traffic light in the simulation."""
        pass
    
    class TrafficSign(Actor):
        """A traffic sign in the simulation."""
        pass
    
    class ActorBlueprint:
        """Blueprint for creating actors."""
        
        def __init__(self):
            self.id: str = ""
            self.tags: list = []
        
        def has_attribute(self, key: str) -> bool:
            """Check if the blueprint has an attribute."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_attribute(self, key: str):
            """Get an attribute by key."""
            raise NotImplementedError("Native extension not loaded")
        
        def set_attribute(self, key: str, value: str) -> None:
            """Set an attribute value."""
            raise NotImplementedError("Native extension not loaded")
    
    class BlueprintLibrary:
        """Collection of actor blueprints."""
        
        def filter(self, pattern: str) -> list:
            """Filter blueprints by pattern."""
            raise NotImplementedError("Native extension not loaded")
        
        def find(self, id: str) -> ActorBlueprint:
            """Find a blueprint by ID."""
            raise NotImplementedError("Native extension not loaded")
    
    class Waypoint:
        """Represents a waypoint on the road network."""
        
        def __init__(self):
            self.transform = Transform()
            self.road_id: int = 0
            self.lane_id: int = 0
    
    class Map:
        """Represents the map/road network."""
        
        def __init__(self):
            self.name: str = ""
        
        def get_spawn_points(self) -> list:
            """Get recommended spawn points."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_waypoint(self, location: Location) -> Waypoint:
            """Get the nearest waypoint to a location."""
            raise NotImplementedError("Native extension not loaded")
    
    class World:
        """Represents the simulation world."""
        
        def get_map(self) -> Map:
            """Get the current map."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_blueprint_library(self) -> BlueprintLibrary:
            """Get the blueprint library."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_spectator(self) -> Actor:
            """Get the spectator actor."""
            raise NotImplementedError("Native extension not loaded")
        
        def spawn_actor(self, blueprint: ActorBlueprint, transform: Transform, attach_to: Actor = None) -> Actor:
            """Spawn a new actor in the world."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_actors(self):
            """Get all actors in the world."""
            raise NotImplementedError("Native extension not loaded")
    
    class Client:
        """Client for connecting to the CARLA server."""
        
        def __init__(self, host: str = "localhost", port: int = 2000):
            """
            Create a new client connection.
            
            Args:
                host: Server hostname
                port: Server port
            """
            raise NotImplementedError(
                "Native carla extension not loaded. "
                "Please build or install the carla-client package."
            )
        
        def set_timeout(self, seconds: float) -> None:
            """Set the timeout for server operations."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_client_version(self) -> str:
            """Get the client API version."""
            return __version__
        
        def get_server_version(self) -> str:
            """Get the server API version."""
            raise NotImplementedError("Native extension not loaded")
        
        def get_world(self) -> World:
            """Get the current simulation world."""
            raise NotImplementedError("Native extension not loaded")
        
        def load_world(self, map_name: str) -> World:
            """Load a new map/world."""
            raise NotImplementedError("Native extension not loaded")
    
    # Command module for batch operations
    class command:
        """Commands for batch actor operations."""
        
        class SpawnActor:
            """Spawn an actor."""
            def __init__(self, blueprint: ActorBlueprint, transform: Transform, attach_to: Actor = None):
                pass
        
        class DestroyActor:
            """Destroy an actor."""
            def __init__(self, actor: Actor):
                pass
        
        class ApplyVehicleControl:
            """Apply control to a vehicle."""
            def __init__(self, actor: Actor, control: VehicleControl):
                pass
