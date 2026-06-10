#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: Free Memory (CSP_MEMFREE) ===${NC}"
echo "This service (Port 3) is used to monitor the satellite's remaining RAM."

# MAC=01, Header=00CA1094 (Prio=2, Src=10, Dst=1, DPort=3, SPort=10, Flags=0)
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\xca\x10\x94'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CSP_MEMFREE request from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "Port 3 blocked"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the Resource Monitoring attempt!${NC}"
else
    echo -e "${RED}VULNERABILITY DETECTED: The satellite's free memory was exposed!${NC}"
fi
