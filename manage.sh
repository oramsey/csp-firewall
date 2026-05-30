#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose"
CONTAINERS="ground-node-a sat-node-b malicious-node firewall"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

function clean_zombies() {
    echo -e "${RED}Cleaning up old containers...${NC}"
    # Stop any background compose
    $COMPOSE_CMD down --remove-orphans 2>/dev/null
    # Force remove named containers if they still exist
    docker rm -f $CONTAINERS 2>/dev/null
}

function start_system() {
    clean_zombies

    # Ask for policy preference
    echo -n "Enable Node-Level Security Policy? (Blocks Node 11) [y/N]: "
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        export NODE_POLICY_ENABLED=1
        echo -e "${GREEN}Policy ENABLED${NC}"
    else
        export NODE_POLICY_ENABLED=0
        echo -e "${RED}Policy DISABLED${NC}"
    fi
    
    echo -e "${GREEN}Starting CSP Firewall Network...${NC}"
    $COMPOSE_CMD up -d --build

    echo -e "${GREEN}System is running!${NC}"
    echo "------------------------------------------------"
    echo "Terminal commands to interact:"
    echo "  Ground Node: sudo docker attach ground-node-a"
    echo "  Sat Node:    sudo docker attach sat-node-b"
    echo "------------------------------------------------"
    echo "Press Ctrl+C to stop the system properly."

    # Wait for Ctrl+C
    trap stop_system SIGINT
    # Tail the logs so the user sees what's happening
    $COMPOSE_CMD logs -f
}

function stop_system() {
    echo -e "\n${RED}Shutting down system...${NC}"
    $COMPOSE_CMD down
    echo -e "${GREEN}Done.${NC}"
    exit 0
}

# Run the system
start_system
