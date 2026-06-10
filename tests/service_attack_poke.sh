#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: Memory Poke (CSP_CMP_POKE) ===${NC}"
echo "This service (Port 0, Code 5) is used to write raw bytes into the satellite's RAM."

# Construct the raw CSP packet for CMP POKE
# Header (Little Endian): 00 0A 10 94 (Prio=2, Src=10, Dst=1, DPort=0, SPort=10, Flags=0)
# Payload: 00 05 (CMP Request, POKE)
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x0a\x10\x94\x00\x05'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CMP_POKE request from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "unauthorized restricted command"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the System Hijacking attempt!${NC}"
else
    echo -e "${RED}CRITICAL VULNERABILITY: The satellite's RAM was modified remotely!${NC}"
fi
