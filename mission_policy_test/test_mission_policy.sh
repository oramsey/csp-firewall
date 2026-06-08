#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Mission-Based Policy Test: Orbital Pass Enforcement ===${NC}"

# Check if skyfield is installed on host
if ! python3 -c "import skyfield" > /dev/null 2>&1; then
    echo -e "${YELLOW}Installing required Python libraries for Orbital Prediction...${NC}"
    if ! command -v pip3 > /dev/null; then
        echo -e "${YELLOW}Installing python3-pip...${NC}"
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install -y python3-pip > /dev/null 2>&1
    fi
    pip3 install -r mission_policy_test/requirements.txt --break-system-packages > /dev/null 2>&1
fi

echo -e "\n${BLUE}[1] Running Orbital Simulation (ISS TLE Data)...${NC}"
# Run the python script to predict the pass
PYTHON_OUTPUT=$(python3 mission_policy_test/pass_predictor.py)
echo "$PYTHON_OUTPUT"

# Extract the status from the output
if echo "$PYTHON_OUTPUT" | grep -q "Commands ALLOWED"; then
    IS_PASSING=true
    echo -e "${GREEN}--> Conclusion: We are inside the authorized mission window.${NC}"
else
    IS_PASSING=false
    echo -e "${RED}--> Conclusion: We are OUTSIDE the authorized mission window.${NC}"
fi

echo -e "\n${BLUE}[2] Enforcing Policy on CSP Firewall...${NC}"
# Based on the python simulation, we update the YAML policy dynamically

if [ "$IS_PASSING" = true ]; then
    # If the satellite is overhead, we allow telecommands (Port 10)
    sed 's/action: drop.*# MISSION_POLICY_TC/action: allow # MISSION_POLICY_TC/' docker/firewall/policy.yaml > tmp_policy.yaml
    cat tmp_policy.yaml > docker/firewall/policy.yaml
    rm tmp_policy.yaml
    echo "Policy Updated: Telecommands (Port 10) ALLOWED."
else
    # If the satellite is not overhead, we block telecommands (Port 10)
    sed 's/action: allow.*# MISSION_POLICY_TC/action: drop # MISSION_POLICY_TC/' docker/firewall/policy.yaml > tmp_policy.yaml
    cat tmp_policy.yaml > docker/firewall/policy.yaml
    rm tmp_policy.yaml
    echo "Policy Updated: Telecommands (Port 10) BLOCKED."
fi

# Restart the firewall so the validator picks up the new YAML changes
echo "Rebuilding Firewall to apply new mission rules..."
docker compose up -d --build --force-recreate firewall > /dev/null 2>&1
echo "Waiting for firewall to boot..."
sleep 15

echo -e "\n${BLUE}[3] Testing Firewall Enforcement (Automated Telecommand)...${NC}"
echo -n "Sending '1: obc_ident' from Ground Node..."

# Fire the command
echo "1: obc_ident" | timeout 5s docker exec -i "ground-node-a" /suchai/build/apps/simple/suchai-app > /dev/null 2>&1
sleep 2

log_output=$(docker logs --tail 15 firewall 2>&1)

if [ "$IS_PASSING" = true ]; then
    # We expect the command to be allowed
    if echo "$log_output" | grep -qi "ALLOWED: Transmitting"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Firewall obeyed mission window and allowed the command)"
    else
        echo -e " [ ${RED}FAIL${NC} ] (Firewall incorrectly blocked the command during a pass)"
    fi
else
    # We expect the command to be blocked by the dynamic port rule
    if echo "$log_output" | grep -qi "REJECTED by Rule"; then
        echo -e " [ ${GREEN}PASS${NC} ] (Firewall obeyed mission window and blocked the command)"
    else
        echo -e " [ ${RED}FAIL${NC} ] (Firewall incorrectly allowed the command outside the window)"
    fi
fi

echo -e "${BLUE}===========================================================${NC}"
