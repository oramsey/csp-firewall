# Use the stable Ubuntu 22.04
FROM ubuntu:22.04

LABEL maintainer="SPEL"
# Cache Buster: v2

# Install dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    gcc make cmake libzmq3-dev python3 python3-zmq python-is-python3 pkg-config libcunit1-dev libsqlite3-dev git && \
    apt autoremove -y && \
    apt clean && rm -rf /var/lib/apt/lists/*

WORKDIR /suchai

# Copy flight software only
COPY suchai-flight-software-v2 /suchai

# Build malicious node (Node 11)
RUN rm -rf build && \
    rm -rf src/lib/libcsp/.lock-waf* && \
    cmake -B build -DDOCKER_BUILD=1 -DAPP=simple -DSCH_COMM_NODE=11 -DSCH_LOG=WARN -DSCH_WDT_PERIOD_MS=9999999 \
    -DSCH_COMM_ZMQ_IN="\"tcp://ground-node-a:8001\"" \
    -DSCH_COMM_ZMQ_OUT="\"tcp://ground-node-a:8002\"" && \
    cmake --build build

COPY docker/malicious_node/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
