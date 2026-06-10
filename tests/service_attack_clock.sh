#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: System Clock (CSP_CMP_CLOCK) ===${NC}"
echo "This service (Port 0, Code 6) is used for time manipulation attacks."

# Construct the raw CSP packet for CMP CLOCK
# Header (Little Endian): 00 0A 10 94 (Prio=2, Src=10, Dst=1, DPort=0, SPort=10, Flags=0)
# Payload: 00 06 (CMP Request, CLOCK)
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x0a\x10\x94\x00\x06'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CMP_CLOCK request from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "unauthorized restricted command"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the Time Manipulation attempt!${NC}"
else
    echo -e "${RED}VULNERABILITY DETECTED: The satellite's system clock was exposed or modified!${NC}"
fi
