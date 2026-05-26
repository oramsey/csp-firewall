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
# It will connect to the local hub by default (localhost:8001/8002)
echo "Starting Benign Ground Node..."
cd /suchai/build/apps/simple
./suchai-app
