#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose -f ../docker-compose.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Automated Payload Policy Test: Block ROUTE_SET ===${NC}"

echo "Initializing test environment..."
$COMPOSE_CMD down -v > /dev/null 2>&1

echo "Starting firewall with current policy.yaml configuration..."
$COMPOSE_CMD up -d --build --force-recreate > /dev/null 2>&1

echo "Waiting for system to boot..."
sleep 12

echo -n "Testing ROUTE_SET injection from Benign Node (10)..."

# Construct the raw CSP packet for ROUTE_SET
# We explicitly set LINGER to 0 and terminate the context so the script doesn't hang!
PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x0a\x10\x94\x00\x02'); time.sleep(0.5); sock.close(); ctx.term()"

# Run the injector in detached mode so it doesn't freeze the terminal
docker exec -d "ground-node-a" python3 -c "$PYTHON_CMD"

sleep 3

# Check for rejection in logs
log_output=$(docker logs --tail 50 firewall 2>&1)

if echo "$log_output" | grep -qi "unauthorized restricted command" || echo "$log_output" | grep -qi "REJECTED"; then
    echo -e " [ ${GREEN}PASS${NC} ] (Malicious route correctly blocked)"
    RESULT=0
else
    echo -e " [ ${RED}FAIL${NC} ] (Malicious route was NOT blocked)"
    RESULT=1
fi

echo -e "${BLUE}------------------------------------------------------${NC}"
if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: The CSP Firewall performs DPI and blocks ROUTE_SET payloads.${NC}"
else
    echo -e "${RED}FAILURE: The payload policy was not enforced correctly.${NC}"
fi
echo -e "${BLUE}------------------------------------------------------${NC}"

echo "Cleaning up..."
$COMPOSE_CMD down > /dev/null 2>&1

exit $RESULT
