# Use the stable Ubuntu 22.04
FROM ubuntu:22.04

LABEL maintainer="SPEL"
# Cache Buster: v2 (Ensures poisoned layers are ignored)

# Install dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    gcc make cmake libzmq3-dev python3 python3-zmq python-is-python3 pkg-config libcunit1-dev libsqlite3-dev git && \
    apt autoremove -y && \
    apt clean && rm -rf /var/lib/apt/lists/*

WORKDIR /suchai

# Copy flight software only (Includes its own internal libcsp)
COPY suchai-flight-software-v2 /suchai

# Build the ground node
RUN rm -rf build && \
    rm -rf src/lib/libcsp/.lock-waf* && \
    cmake -B build -DDOCKER_BUILD=1 -DAPP=simple -DSCH_COMM_NODE=10 -DSCH_LOG=WARN -DSCH_WDT_PERIOD_MS=9999999 && \
    cmake --build build

COPY docker/ground_node/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8001 8002 8003
ENTRYPOINT ["/entrypoint.sh"]
