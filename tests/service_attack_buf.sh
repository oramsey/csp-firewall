#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: Free Buffers (CSP_BUF_FREE) ===${NC}"
echo "This service (Port 5) is used to monitor the satellite's remaining CSP network buffers."

# MAC=01, Header=004A1194 (Prio=2, Src=10, Dst=1, DPort=5, SPort=10, Flags=0)
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x4a\x11\x94'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CSP_BUF_FREE request from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "Port 5 blocked"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the Resource Monitoring attempt!${NC}"
else
    echo -e "${RED}VULNERABILITY DETECTED: The satellite's network buffer count was exposed!${NC}"
fi
