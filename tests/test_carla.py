"""
Basic tests for the carla module.

Note: Most functionality tests require a running CARLA server.
These tests verify the module can be imported and basic classes exist.
"""

import pytest


def test_import_carla():
    """Test that the carla module can be imported."""
    import carla
    assert carla.__version__ == "0.9.16"


def test_location_class():
    """Test the Location class."""
    import carla
    
    loc = carla.Location(1.0, 2.0, 3.0)
    assert loc.x == 1.0
    assert loc.y == 2.0
    assert loc.z == 3.0


def test_rotation_class():
    """Test the Rotation class."""
    import carla
    
    rot = carla.Rotation(10.0, 20.0, 30.0)
    assert rot.pitch == 10.0
    assert rot.yaw == 20.0
    assert rot.roll == 30.0


def test_transform_class():
    """Test the Transform class."""
    import carla
    
    loc = carla.Location(1.0, 2.0, 3.0)
    rot = carla.Rotation(10.0, 20.0, 30.0)
    transform = carla.Transform(loc, rot)
    
    assert transform.location.x == 1.0
    assert transform.rotation.pitch == 10.0


def test_vector3d_class():
    """Test the Vector3D class."""
    import carla
    
    vec = carla.Vector3D(1.0, 2.0, 3.0)
    assert vec.x == 1.0
    assert vec.y == 2.0
    assert vec.z == 3.0


def test_color_class():
    """Test the Color class."""
    import carla
    
    color = carla.Color(255, 128, 64, 200)
    assert color.r == 255
    assert color.g == 128
    assert color.b == 64
    assert color.a == 200


def test_vehicle_control_class():
    """Test the VehicleControl class."""
    import carla
    
    control = carla.VehicleControl()
    assert control.throttle == 0.0
    assert control.steer == 0.0
    assert control.brake == 0.0
    assert control.hand_brake is False
    assert control.reverse is False


def test_walker_control_class():
    """Test the WalkerControl class."""
    import carla
    
    control = carla.WalkerControl()
    assert control.speed == 0.0
    assert control.jump is False


def test_all_exports():
    """Test that all expected classes are exported."""
    import carla
    
    expected_exports = [
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
    
    for name in expected_exports:
        assert hasattr(carla, name), f"Missing export: {name}"
