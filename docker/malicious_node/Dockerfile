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
COPY suchai-flight-software-v2 /suchai
COPY libcsp-gs /suchai/src/lib/libcsp

# Build the Malicious node (Node 11)
# We point it to 'ground-hub-a' which will be the service name in docker-compose
RUN rm -rf build && \
    cmake -B build -DAPP=simple \
    -DSCH_COMM_NODE=11 \
    -DSCH_COMM_ZMQ_IN="\"tcp://ground-hub-a:8001\"" \
    -DSCH_COMM_ZMQ_OUT="\"tcp://ground-hub-a:8002\"" && \
    cmake --build build

# Copy the entrypoint script
COPY docker/malicious_node/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
