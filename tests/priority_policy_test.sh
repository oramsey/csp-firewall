#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose -f ../docker-compose.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Automated Priority Policy Test: Block High Priority ===${NC}"

# 1. Clean up any existing environment
echo "Initializing test environment..."
$COMPOSE_CMD down -v > /dev/null 2>&1

# 2. Start the system
# We must ensure policy_ON is active for this test
cat ../docker/firewall/policy_ON.yaml > ../docker/firewall/policy.yaml
echo "Starting firewall with current policy_ON.yaml configuration..."
$COMPOSE_CMD up -d --build --force-recreate > /dev/null 2>&1

# Wait for containers to boot
echo "Waiting for satellite to boot..."
sleep 15

# Function to run a command and check firewall logs
test_priority() {
    local container=$1
    local prio_level=$2
    local label=$3
    local expected_result="Priority level $prio_level not allowed"

    echo -n "Testing $label (Priority $prio_level)..."
    
    # Send a raw ping with the specific priority level
    # Header format: Prio is the top 2 bits. 
    # Prio 0 (Critical) = 0x00...
    # We'll use python to send a Prio 0 ping (Port 1) from Node 10 to Node 1
    # Prio 0, Src 10, Dst 1, DPort 1, SPort 10, Flags 0 -> 0x14 0x10 0x44 0x00
    # Let's rebuild the int:
    # prio (0) << 30 = 0x00000000
    # src (10) << 25 = 0x14000000
    # dst (1)  << 20 = 0x00100000
    # dport (1)<< 14 = 0x00004000
    # sport (10)<< 8 = 0x00000a00
    # Total = 0x14104a00 -> Little Endian: 00 4a 10 14
    
    PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x4a\x10\x14'); time.sleep(0.5); sock.close(); ctx.term()"
    
    docker exec -d "$container" python3 -c "$PYTHON_CMD"
    
    # Wait for flush
    sleep 3

    # Check firewall logs
    local log_output=$(docker logs --tail 20 firewall 2>&1)
    
    if echo "$log_output" | grep -qi "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Priority $prio_level correctly blocked)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Priority $prio_level was NOT blocked)"
        return 1
    fi
}

# 3. Perform Test
test_priority "ground-node-a" "0" "Critical Priority Abuse"
RESULT=$?

# 4. Final Result
echo -e "${BLUE}------------------------------------------------------${NC}"
if [ $RESULT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: The CSP Firewall blocks unauthorized high-priority packets.${NC}"
else
    echo -e "${RED}FAILURE: The priority policy was not enforced correctly.${NC}"
fi
echo -e "${BLUE}------------------------------------------------------${NC}"

# 5. Cleanup
echo "Cleaning up..."
$COMPOSE_CMD down > /dev/null 2>&1

exit $RESULT
