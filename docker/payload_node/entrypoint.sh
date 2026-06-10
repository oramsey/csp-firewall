#!/bin/bash
# Start ZMQ Hub B
echo "Starting ZMQ Hub for Payload Node..."
cd /suchai/scripts/csp_zmq
python3 zmqhub.py --mon &
sleep 2
# Launch Flight Software as PID 1
echo "Starting Payload Node (Node 2)..."
cd /suchai/build/apps/simple
exec ./suchai-app
