#!/bin/bash

# Start ZMQ Hub A in the background
# -i 8002: Input port (XSUB) - nodes PUB to this
# -o 8001: Output port (XPUB) - nodes SUB from this
# --mon: Enable monitor
echo "Starting ZMQ Hub A..."
cd /suchai/scripts/csp_zmq
python3 zmqhub.py --mon &
cd /suchai

# Wait for the hub to initialize
sleep 2

# Start Benign Ground Node (Node 10)
echo "Ensuring build is up to date..."
cd /suchai
# Only configure if build folder doesn't exist, then build
if [ ! -d "build" ]; then
    cmake -B build -DAPP=simple -DSCH_COMM_NODE=10 -DSCH_LOG=WARN -DSCH_WDT_PERIOD_MS=9999999
fi
cmake --build build

cd /suchai/build/apps/simple
exec ./suchai-app
