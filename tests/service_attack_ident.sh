#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: Node Identification (CSP_CMP_IDENT) ===${NC}"
echo "This service (Port 0, Code 1) is used for version fingerprinting."

# Construct the raw CSP packet for CMP IDENT
# MAC=01, Header=000A1094 (Src=10, Dst=1, DPort=0), Payload=0001
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x0a\x10\x94\x00\x01'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CMP_IDENT request from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "unauthorized restricted command"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the Fingerprinting attempt!${NC}"
else
    echo -e "${RED}VULNERABILITY DETECTED: The satellite's firmware version was exposed!${NC}"
fi
