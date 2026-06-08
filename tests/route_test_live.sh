#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Live Payload Policy Test (ROUTE_SET) ===${NC}"
echo "Assuming system is already running via manage.sh..."

echo -n "Testing ROUTE_SET injection from Benign Node (10)..."

# Construct the raw CSP packet for ROUTE_SET
# We explicitly set LINGER to 0 and terminate the context so the script doesn't hang!
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x0a\x10\x94\x00\x02'); time.sleep(0.5); sock.close(); ctx.term()"

# Run the injector in detached mode so it doesn't freeze the terminal
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"

# Give the firewall and Docker logging plenty of time to flush
sleep 3

# Check the last 50 lines for any of the rejection keywords
# We use a broad tail and case-insensitive match to be very robust
log_output=$(docker logs --tail 50 firewall 2>&1)

if echo "$log_output" | grep -qi "unauthorized restricted command" || echo "$log_output" | grep -qi "REJECTED"; then
    echo -e " [ ${GREEN}PASS${NC} ] (Malicious route correctly REJECTED)"
    RESULT=0
else
    echo -e " [ ${RED}FAIL${NC} ] (Malicious route was NOT rejected)"
    echo -e "${RED}Debug: Last 5 lines of firewall logs:${NC}"
    echo "$log_output" | tail -n 5
    RESULT=1
fi

echo -e "${BLUE}======================================${NC}"
exit $RESULT
