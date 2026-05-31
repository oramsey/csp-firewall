#!/bin/bash

# Start Malicious Ground Node (Node 11)
echo "Ensuring build is up to date..."
cd /suchai
if [ ! -d "build" ]; then
    cmake -B build -DAPP=simple \
    -DSCH_COMM_NODE=11 \
    -DSCH_LOG=WARN \
    -DSCH_WDT_PERIOD_MS=9999999 \
    -DSCH_COMM_ZMQ_IN="\"tcp://ground-node-a:8001\"" \
    -DSCH_COMM_ZMQ_OUT="\"tcp://ground-node-a:8002\""
fi
cmake --build build

cd /suchai/build/apps/simple
exec ./suchai-app

