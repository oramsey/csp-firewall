#!/bin/bash

# Configuration
COMPOSE_CMD="docker compose"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

function clean_zombies() {
    echo -e "${RED}Cleaning up old containers...${NC}"
    $COMPOSE_CMD down 2>/dev/null
}

function start_system() {
    clean_zombies

    echo -e "${GREEN}Starting CSP Firewall Network with YAML Policy Engine...${NC}"
    $COMPOSE_CMD up -d --build --force-recreate

    echo -e "${GREEN}System is running!${NC}"
    echo "------------------------------------------------"
    echo "Terminal commands to interact:"
    echo "  Ground Node: sudo docker attach ground-node-a"
    echo "  Sat Node:    sudo docker attach sat-node-b"
    echo "------------------------------------------------"
    echo "Press Ctrl+C to stop the system properly."

    trap stop_system SIGINT
    $COMPOSE_CMD logs -f
}

function stop_system() {
    echo -e "\n${RED}Shutting down system...${NC}"
    $COMPOSE_CMD down
    exit 0
}

start_system
