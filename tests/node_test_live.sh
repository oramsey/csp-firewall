#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Live Node Policy Test ===${NC}"
echo "Assuming system is already running via manage.sh..."

# Function to run a command and check firewall logs
test_node_live() {
    local container=$1
    local node_id=$2
    local expected_result=$3 # "ALLOWED" or "REJECTED"
    local label=$4

    echo -n "Testing $label (Node $node_id)..."
    
    # 1. Send the command
    echo "1: obc_ident" | timeout 5s docker exec -i "$container" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
    
    # 2. Give the firewall a moment to log and flush
    sleep 3

    # 3. Check the last 20 lines of firewall logs
    local log_output=$(docker logs --tail 20 firewall 2>&1)
    
    if echo "$log_output" | grep -qi "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Traffic was $expected_result)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Traffic was NOT $expected_result)"
        return 1
    fi
}

# Perform Tests
test_node_live "ground-node-a" "10" "ALLOWED" "Benign Node Authorization"
test_node_live "malicious-node" "11" "REJECTED" "Malicious Node Block"

echo -e "${BLUE}======================================${NC}"
