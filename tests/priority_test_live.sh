#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Running Live Priority Policy Test ===${NC}"
echo "Assuming system is already running via manage.sh..."

test_priority_live() {
    local container=$1
    local prio_level=$2
    local label=$3
    local expected_result="Priority level $prio_level not allowed"

    echo -n "Testing $label (Priority $prio_level)..."
    
    # Header format: Prio is the top 2 bits. 
    # Prio 0 (Critical) = 0x00...
    # Prio 0, Src 10, Dst 1, DPort 1, SPort 10, Flags 0 -> 0x14 0x10 0x44 0x00
    # Little Endian: 00 4a 10 14
    PYTHON_CMD="import zmq; import time; ctx = zmq.Context(); sock = ctx.socket(zmq.PUB); sock.setsockopt(zmq.LINGER, 0); sock.connect('tcp://localhost:8002'); time.sleep(0.5); sock.send(b'\x01\x00\x4a\x10\x14'); time.sleep(0.5); sock.close(); ctx.term()"
    
    docker exec -d "$container" python3 -c "$PYTHON_CMD"
    
    # Give the firewall a moment to log and flush
    sleep 3

    # Check the last 20 lines of firewall logs
    local log_output=$(docker logs --tail 20 firewall 2>&1)
    
    if echo "$log_output" | grep -qi "$expected_result"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Priority $prio_level correctly blocked)"
        return 0
    else
        echo -e " [ ${RED}FAIL${NC} ] (Priority $prio_level was NOT blocked)"
        return 1
    fi
}

# Perform Tests
test_priority_live "ground-node-a" "0" "Critical Priority Abuse"

echo -e "${BLUE}======================================${NC}"
