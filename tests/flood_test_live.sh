#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Live Anti-Flooding Policy Test ===${NC}"
echo "Assuming system is already running via manage.sh..."

echo -n "Sending 5 normal pings from Node 10..."
for i in {1..5}; do
    echo "com_ping 1" | timeout 5s docker exec -i "ground-node-a" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    sleep 0.5
done
echo -e " [ ${GREEN}SENT${NC} ]"

echo -n "Sending 6th ping (Flood Trigger)..."
echo "com_ping 1" | timeout 5s docker exec -i "ground-node-a" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
sleep 2

log_output=$(docker logs --tail 20 firewall 2>&1)
if echo "$log_output" | grep -q "Rate limit exceeded"; then
    echo -e " [ ${GREEN}PASS${NC} ] (Traffic correctly REJECTED)"
    RESULT=0
else
    echo -e " [ ${RED}FAIL${NC} ] (Traffic was NOT REJECTED)"
    RESULT=1
fi

echo -e "${BLUE}======================================${NC}"
exit $RESULT
