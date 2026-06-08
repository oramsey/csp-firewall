#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Live Port Policy Test ===${NC}"
echo "Assuming system is already running via manage.sh..."

# Function to run a command and check firewall logs
test_port_live() {
    local container=$1
    local port=$2
    local command_str=$3
    local label=$4
    local expected_result="Port $port blocked"

    echo -n "Testing $label (Port $port)..."
    
    # 1. Send the command
    echo "$command_str" | timeout 5s docker exec -i "$container" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    
    # 2. Give the firewall a moment to log and flush
    sleep 3

    # 3. Check the last 20 lines of firewall logs
    local log_output=$(docker logs --tail 20 firewall 2>&1)
    
    if echo "$log_output" | grep -qi "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Traffic to Port $port correctly blocked)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Traffic to Port $port was NOT blocked)"
        return 1
    fi
}

# Perform Tests
# Port 13: Debug (via log_set)
test_port_live "ground-node-a" "13" "log_set 3 1" "Debug Port Access"

# Port 14: Diagnostic (via tm_send_index)
test_port_live "ground-node-a" "14" "tm_send_index 1 0" "Diagnostic Port Access"

echo -e "${BLUE}======================================${NC}"
