#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== CSP Service Attack: Remote Reboot (CSP_REBOOT) ===${NC}"
echo "This service (Port 4) is a Denial of Service (DoS) vector that crashes the satellite."

# MAC=01, Header=000A1194 (Prio=2, Src=10, Dst=1, DPort=4, SPort=10, Flags=0)
# Payload=80000000 (Magic word for reboot)
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x0a\x11\x94\x80\x00\x00\x00'); time.sleep(0.5); sock.close(); ctx.term()"

echo -n "Sending CSP_REBOOT kill-packet from Ground Node..."
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"
echo -e " [ ${GREEN}SENT${NC} ]"

sleep 3

# Check if firewall caught it
log_output=$(docker logs --tail 20 firewall 2>&1)

if echo "$log_output" | grep -qi "Port 4 blocked"; then
    echo -e "${GREEN}SUCCESS: Firewall intercepted the Denial of Service attack!${NC}"
else
    echo -e "${RED}CRITICAL VULNERABILITY: The satellite was remotely rebooted!${NC}"
fi
