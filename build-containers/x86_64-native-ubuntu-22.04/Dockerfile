# CARLA Simple Client - x86_64 Native Build Container for Ubuntu 22.04
# This container provides a clean Ubuntu 22.04 environment for building
# CARLA client examples natively on x86_64 architecture.

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    pkg-config \
    git \
    curl \
    wget \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    libboost-all-dev \
    libtiff5-dev \
    libjpeg-dev \
    libpng-dev \
    libxerces-c-dev \
    libsqlite3-dev \
    libomp-dev \
    && rm -rf /var/lib/apt/lists/*

# Create work directory
WORKDIR /workspace

# Set up build environment
ENV CC=gcc
ENV CXX=g++
ENV CMAKE_BUILD_TYPE=Release

# Create non-root user for builds (will be set by docker run)
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g $GROUP_ID carla && useradd -u $USER_ID -g $GROUP_ID -m -s /bin/bash carla
RUN chown carla:carla /workspace
USER carla

# Default command
CMD ["/bin/bash"]