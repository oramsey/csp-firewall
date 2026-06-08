#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose -f ../docker-compose.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Automated Port Policy Test: Restricted Port Blocking ===${NC}"

# 1. Clean up any existing environment
echo "Initializing test environment..."
$COMPOSE_CMD down -v > /dev/null 2>&1

# 2. Start the system
echo "Starting firewall with current policy.yaml configuration..."
$COMPOSE_CMD up -d --build --force-recreate > /dev/null 2>&1

# Wait for containers to boot
echo "Waiting for satellite to boot..."
sleep 10

# Function to run a command and check firewall logs
test_port() {
    local container=$1
    local port=$2
    local command_str=$3
    local label=$4
    local expected_result="Port $port blocked"

    echo -n "Testing $label (Port $port)..."
    
    # Execute the command from Benign Node (10)
    echo "$command_str" | timeout 15s docker exec -i "$container" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    
    # Wait for flush
    sleep 2

    # Check firewall logs
    local log_output=$(docker logs --tail 10 firewall 2>&1)
    
    if echo "$log_output" | grep -q "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Port $port correctly blocked)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Port $port was NOT blocked)"
        return 1
    fi
}

# 3. Perform Tests (Using Benign Node 10)
test_port "ground-node-a" "13" "log_set 3 1" "Debug Port Access"
DBG_RESULT=$?

test_port "ground-node-a" "14" "tm_send_index 1 0" "Diagnostic Port Access"
DIAG_RESULT=$?

# 4. Final Result
echo -e "${BLUE}------------------------------------------------------${NC}"
if [ $DBG_RESULT -eq 0 ] && [ $DIAG_RESULT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: The CSP Firewall blocks trusted IDs from dangerous ports.${NC}"
    RESULT=0
else
    echo -e "${RED}FAILURE: The port policy was not enforced correctly.${NC}"
    RESULT=1
fi
echo -e "${BLUE}------------------------------------------------------${NC}"

# 5. Cleanup
echo "Cleaning up..."
$COMPOSE_CMD down > /dev/null 2>&1

exit $RESULT
