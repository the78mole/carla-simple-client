# CARLA Python Client Example

This example demonstrates how to connect to a CARLA server and control a vehicle using Python.

## Prerequisites

- A running CARLA server (version 0.9.16)
- Python 3.8+
- carla-client package installed

## Installation

**Using uv (recommended):**

```bash
uv pip install carla-client
```

**Using pip:**

```bash
pip install carla-client
```

**From source (development):**

```bash
cd carla-simple-client
uv pip install -e ".[dev]"
```

## Usage

```bash
# Default: connect to localhost:2000
python example_client.py

# Specify host and port
python example_client.py 192.168.1.100 2000

# With custom timeout
python example_client.py localhost 2000 --timeout 30.0
```

## What it does

1. Connects to a CARLA server
2. Prints client and server version info
3. Selects a random vehicle blueprint
4. Spawns the vehicle at a random spawn point
5. Drives the vehicle forward for 5 seconds
6. Stops and destroys the vehicle

## Example Output

```
Connecting to CARLA server at localhost:2000...
Client API version: 0.9.16
Server API version: 0.9.16
Connected to world: Town05_Opt
Selected vehicle: vehicle.audi.a2
Spawning at: (100.5, -50.3, 0.5)
Spawned: vehicle.audi.a2
Vehicle is moving forward...
Simulation running for 5 seconds...
Vehicle stopped.
Vehicle destroyed.
Example completed successfully!
```
