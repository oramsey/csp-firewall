# Use the official Ubuntu 24.04 image as the base
FROM ubuntu:24.04

LABEL maintainer="SPEL"

# Install build tools and dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    gcc make cmake libzmq3-dev python3 python3-pip python3-zmq pkg-config libcunit1-dev libsqlite3-dev git && \
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory inside the container
WORKDIR /suchai

# Copy the flight software source
# Note: This assumes the build context is the project root
COPY suchai-flight-software-v2 /suchai
COPY libcsp-gs /suchai/src/lib/libcsp

# Build the ground node (Node 10)
# We use the 'simple' app as the ground node
RUN rm -rf build && \
    cmake -B build -DAPP=simple -DSCH_COMM_NODE=10 && \
    cmake --build build

# Copy the entrypoint script
COPY docker/ground_node/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ZMQ Hub ports
# Port 8001: XPUB (SUB)
# Port 8002: XSUB (PUB)
# Port 8003: Monitor
EXPOSE 8001 8002 8003

ENTRYPOINT ["/entrypoint.sh"]
