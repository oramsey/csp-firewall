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
# It will connect to the local Hub B (localhost:8001/8002)
echo "Starting Satellite Node..."
cd /suchai/build/apps/simple
exec ./suchai-app
