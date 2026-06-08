#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose -f ../docker-compose.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Automated Anti-Flooding Policy Test ===${NC}"

# 1. Clean up any existing environment
echo "Initializing test environment..."
$COMPOSE_CMD down -v > /dev/null 2>&1

# 2. Start the system
echo "Starting firewall with current policy.yaml configuration..."
$COMPOSE_CMD up -d --build --force-recreate > /dev/null 2>&1

# Wait for containers to boot
echo "Waiting for satellite to boot..."
sleep 10

echo -n "Sending 5 normal pings from Node 10..."
for i in {1..5}; do
    echo "com_ping 1" | timeout 5s docker exec -i "ground-node-a" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    sleep 0.5
done
echo -e " [ ${GREEN}DONE${NC} ]"

echo -n "Sending 6th ping (Flood Trigger)..."
echo "com_ping 1" | timeout 5s docker exec -i "ground-node-a" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
sleep 2

log_output=$(docker logs --tail 20 firewall 2>&1)
if echo "$log_output" | grep -q "Rate limit exceeded"; then
    echo -e " [ ${GREEN}PASS${NC} ] (Rate limit triggered)"
    RESULT=0
else
    echo -e " [ ${RED}FAIL${NC} ] (Rate limit NOT triggered)"
    RESULT=1
fi

echo -e "${BLUE}------------------------------------------------------${NC}"
if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: The CSP Firewall correctly limits packet rates.${NC}"
else
    echo -e "${RED}FAILURE: Anti-Flooding policy failed.${NC}"
fi
echo -e "${BLUE}------------------------------------------------------${NC}"

echo "Cleaning up..."
$COMPOSE_CMD down > /dev/null 2>&1

exit $RESULT
