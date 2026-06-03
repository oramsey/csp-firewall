#!/bin/bash
# Start ZMQ Hub B
echo "Starting ZMQ Hub B..."
cd /suchai/scripts/csp_zmq
python3 zmqhub.py --mon &
sleep 2
# Launch Flight Software as PID 1
echo "Starting Satellite Node..."
cd /suchai/build/apps/simple
exec ./suchai-app
