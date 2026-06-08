#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Automated Node Policy Test: Rogue Node Isolation ===${NC}"

# 1. Clean up any existing environment
echo "Initializing test environment..."
$COMPOSE_CMD down -v > /dev/null 2>&1

# 2. Start the system
echo "Starting firewall with current policy.yaml configuration..."
$COMPOSE_CMD up -d --build --force-recreate > /dev/null 2>&1

# Wait for containers to boot and compile
echo "Waiting for satellite to boot..."
sleep 10

# Function to run a command and check firewall logs
test_node() {
    local container=$1
    local node_id=$2
    local expected_result=$3 # "ALLOWED" or "REJECTED"

    echo -n "Testing Node $node_id..."
    
    # Send a remote command (obc_ident) to Node 1
    echo "1: obc_ident" | timeout 15s docker exec -i "$container" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    
    # Wait for flush
    sleep 2

    # Check firewall logs
    local log_output=$(docker logs --tail 10 firewall 2>&1)
    
    if echo "$log_output" | grep -q "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Traffic was $expected_result)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Traffic was NOT $expected_result)"
        return 1
    fi
}

# 3. Perform Tests
# Benign Node (10) -> Should be ALLOWED
test_node "ground-node-a" "10" "ALLOWED"
BENIGN_RESULT=$?

# Malicious Node (11) -> Should be REJECTED
test_node "malicious-node" "11" "REJECTED"
MALICIOUS_RESULT=$?

# 4. Final Result
echo -e "${BLUE}------------------------------------------------------${NC}"
if [ $BENIGN_RESULT -eq 0 ] && [ $MALICIOUS_RESULT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: The CSP Firewall correctly isolates the rogue node.${NC}"
    RESULT=0
else
    echo -e "${RED}FAILURE: The node policy did not enforce isolation correctly.${NC}"
    RESULT=1
fi
echo -e "${BLUE}------------------------------------------------------${NC}"

# 5. Cleanup
echo "Cleaning up..."
$COMPOSE_CMD down > /dev/null 2>&1

exit $RESULT
