#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Live Payload Policy Test ===${NC}"
echo "Assuming system is already running via manage.sh..."

# Function to run a command and check firewall logs
test_payload_live() {
    local container=$1
    local cmd_to_send=$2
    local label=$3
    local expected_result=$4

    echo -n "Testing $label..."
    
    # 1. Send the command
    echo "$cmd_to_send" | timeout 10s docker exec -i "$container" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    
    # 2. Give the firewall a moment to log and flush
    sleep 3

    # 3. Check the last 20 lines of firewall logs
    local log_output=$(docker logs --tail 20 firewall 2>&1)
    
    if echo "$log_output" | grep -qi "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Payload was correctly REJECTED)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Payload was NOT rejected)"
        return 1
    fi
}

# Perform Tests
test_payload_live "ground-node-a" "1: obc_reset 0" "obc_reset from Node 10" "unauthorized restricted command"

echo -e "${BLUE}======================================${NC}"
