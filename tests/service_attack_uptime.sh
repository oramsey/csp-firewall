#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: System Uptime (CSP_UPTIME) ===${NC}"
echo "This service (Port 6) is used to monitor how long the satellite has been running."

# MAC=01, Header=008A1194 (Prio=2, Src=10, Dst=1, DPort=6, SPort=10, Flags=0)
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x8a\x11\x94'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CSP_UPTIME request from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "Port 6 blocked"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the System Monitoring attempt!${NC}"
else
    echo -e "${RED}VULNERABILITY DETECTED: The satellite's uptime was exposed!${NC}"
fi
