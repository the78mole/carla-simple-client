FROM ubuntu:22.04

# Setup sources and multi-arch
RUN rm /etc/apt/sources.list
COPY jammy.source /etc/apt/sources.list.d/jammy.list
COPY arm-cross-compile-sources.list /etc/apt/sources.list.d/arm-cross-compile-sources.list

RUN apt update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt upgrade -y

RUN dpkg --add-architecture armhf && \
    dpkg --add-architecture arm64

RUN apt update

# Install cross-compilation tools and dependencies
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt install -y \
    gcc-arm-linux-gnueabi \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    build-essential \
    cmake \
    ninja-build \
    git \
    wget \
    curl \
    unzip \
    autoconf \
    automake \
    libtool \
    pkg-config \
    file \
    python3 \
    python3-dev \
    python3-pip \
    libpng-dev:arm64 \
    zlib1g-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

# Set cross-compilation environment variables
ENV CC=aarch64-linux-gnu-gcc \
    CXX=aarch64-linux-gnu-g++ \
    AR=aarch64-linux-gnu-ar \
    STRIP=aarch64-linux-gnu-strip \
    RANLIB=aarch64-linux-gnu-ranlib \
    PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig \
    CMAKE_TOOLCHAIN_FILE=/work/cmake/toolchain-arm64.cmake

# Copy ARM64 dependency build script
COPY build-arm64-deps.sh /usr/local/bin/
COPY arm64-toolchain.cmake /usr/local/bin/
RUN chmod +x /usr/local/bin/build-arm64-deps.sh

# Test cross-compiler
RUN echo 'int main(){return 0;}' > /tmp/test.c && \
    aarch64-linux-gnu-gcc /tmp/test.c -o /tmp/test_arm64 && \
    file /tmp/test_arm64 && \
    rm /tmp/test.c /tmp/test_arm64

WORKDIR /work
