#!/bin/bash

# Start ZMQ Hub B in the background
# Hub B represents the space segment network
echo "Starting ZMQ Hub B..."
cd /suchai/scripts/csp_zmq
python3 zmqhub.py --mon &
cd /suchai

# Wait for the hub to initialize
sleep 2

# Start Satellite Node (Node 1)
echo "Ensuring build is up to date..."
cd /suchai
if [ ! -d "build" ]; then
    cmake -B build -DAPP=simple -DSCH_COMM_NODE=1
fi
cmake --build build

cd /suchai/build/apps/simple
exec ./suchai-app
