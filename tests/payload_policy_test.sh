#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose -f ../docker-compose.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Automated Payload Policy Test: DPI Command Blocking ===${NC}"

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
test_payload() {
    local container=$1
    local cmd_to_send=$2
    local label=$3
    local expected_result=$4

    echo -n "Testing $label..."
    
    # Execute the command
    echo "$cmd_to_send" | timeout 15s docker exec -i "$container" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    
    # Wait for flush
    sleep 2

    # Check firewall logs
    local log_output=$(docker logs --tail 10 firewall 2>&1)
    
    if echo "$log_output" | grep -q "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Payload correctly blocked)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Payload was NOT blocked as expected)"
        echo "      (Expected match: $expected_result)"
        return 1
    fi
}

# 3. Perform Tests
# Test obc_reset from Benign Node (10) -> Should be blocked because only Node 2 is authorized
# Note: The log says "unauthorized restricted command" for source mismatches
test_payload "ground-node-a" "1: obc_reset 0" "obc_reset (High-Risk Command)" "unauthorized restricted command"
REBOOT_RESULT=$?

# 4. Final Result
echo -e "${BLUE}------------------------------------------------------${NC}"
if [ $REBOOT_RESULT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: The CSP Firewall performs DPI and blocks unauthorized dangerous payloads.${NC}"
    RESULT=0
else
    echo -e "${RED}FAILURE: The payload policy was not enforced correctly.${NC}"
    RESULT=1
fi
echo -e "${BLUE}------------------------------------------------------${NC}"

# 5. Cleanup
echo "Cleaning up..."
$COMPOSE_CMD down > /dev/null 2>&1

exit $RESULT
