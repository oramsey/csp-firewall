#!/bin/bash
# Start ZMQ Hub A
echo "Starting ZMQ Hub A..."
cd /suchai/scripts/csp_zmq
python3 zmqhub.py --mon &
sleep 2
# Launch Flight Software as PID 1 for keyboard input
echo "Starting Ground Node..."
cd /suchai/build/apps/simple
exec ./suchai-app
