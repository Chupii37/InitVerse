#!/bin/bash

# Warna-warna kece untuk mempercantik tampilan
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # Normal tanpa warna

# Global variables
WALLET_ADDRESS=""
WORKER_NAME="Worker001"
CPU_CORES=$(nproc)
MINING_SOFTWARE_URL="https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64"
POOL_ADDRESS="pool-core-testnet.inichain.com:32672"
MINER_DIR="/root/ini-miner"
FULL_NODE_URL="https://github.com/Project-InitVerse/ini-chain/releases/download/v1.0.0/ini-chain.tar.gz"

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${MAGENTA}       InitVerse Setup${NC}"  # Pesan sambutan baru
    echo -e "${CYAN}=================================================${NC}"
}

# Function to check system requirements
check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Check CPU
    echo -e "${CYAN}CPU Information:${NC}"
    lscpu | grep "Model name"
    echo -e "Available cores: ${GREEN}$CPU_CORES${NC}"
    
    # Check RAM
    total_ram=$(free -h | awk '/^Mem:/{print $2}')
    echo -e "Total RAM: ${GREEN}$total_ram${NC}"
    
    # Check disk space
    disk_space=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "Available disk space: ${GREEN}$disk_space${NC}"
    
    # Check for required software
    echo -e "\n${CYAN}Checking required software:${NC}"
    for cmd in wget tar gzip; do
        if command -v $cmd >/dev/null 2>&1; then
            echo -e "$cmd: ${GREEN}Installed${NC}"
        else
            echo -e "$cmd: ${RED}Not installed${NC}"
        fi
    done
}

# Function to setup pool mining
setup_pool_mining() {
    echo -e "${YELLOW}Setting up Pool Mining...${NC}"
    
    # Get wallet address if not already set
    while [ -z "$WALLET_ADDRESS" ] || ! validate_wallet "$WALLET_ADDRESS"; do
        echo -e "${CYAN}Enter your wallet address (0x...):${NC}"
        read WALLET_ADDRESS
    done
    
    # Get worker name
    echo -e "${CYAN}Enter worker name (default: Worker001):${NC}"
    read input_worker
    WORKER_NAME=${input_worker:-$WORKER_NAME}
    
    # Create directory and download mining software
    mkdir -p ini-miner && cd ini-miner
    
    # Download and extract mining software
    echo -e "${YELLOW}Downloading mining software...${NC}"
    wget "$MINING_SOFTWARE_URL" -O iniminer-linux-x64
    chmod +x iniminer-linux-x64
    
    # Check if executable exists
    if [ ! -f "./iniminer-linux-x64" ]; then
        echo -e "${RED}Error: Mining software not found${NC}"
        return 1
    fi
    
    # Set up mining command
    MINING_CMD="./iniminer-linux-x64 --pool stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@${POOL_ADDRESS}"
    
    # Get number of CPU cores to use
    echo -e "${CYAN}Enter number of CPU cores to use (1-${CPU_CORES}, default: 1):${NC}"
    read cores
    cores=${cores:-1}
    
    for ((i=0; i<cores; i++)); do
        MINING_CMD+=" --cpu-devices $i"
    done
    
    # Start mining
    echo -e "${GREEN}Starting mining with command:${NC}"
    echo -e "${BLUE}$MINING_CMD${NC}"
    eval "$MINING_CMD"
}

# Function to set up solo mining
setup_solo_mining() {
    echo -e "${YELLOW}Setting up Solo Mining...${NC}"
    
    # Get wallet address if not already set
    while [ -z "$WALLET_ADDRESS" ] || ! validate_wallet "$WALLET_ADDRESS"; do
        echo -e "${CYAN}Enter your wallet address (0x...):${NC}"
        read WALLET_ADDRESS
    done
    
    # Download and set up full node
    echo -e "${YELLOW}Downloading full node...${NC}"
    wget "$FULL_NODE_URL" -O ini-chain.tar.gz
    tar -xzf ini-chain.tar.gz
    
    # Download Geth
    wget https://github.com/Project-InitVerse/ini-chain/releases/download/v1.0.0/geth-linux-x64
    chmod +x geth-linux-x64
    
    # Start node
    echo -e "${GREEN}Starting full node...${NC}"
    ./geth-linux-x64 --datadir data --http.api="eth,admin,miner,net,web3,personal" --allow-insecure-unlock --testnet console
    
    # Set up mining
    echo -e "${YELLOW}Setting up mining...${NC}"
    echo "miner.setEtherbase(\"$WALLET_ADDRESS\")"
    
    # Get number of CPU cores to use
    echo -e "${CYAN}Enter number of CPU cores to use (1-${CPU_CORES}, default: 1):${NC}"
    read cores
    cores=${cores:-1}
    
    # Command to start mining
    echo "miner.start($cores)"
}

# Main menu function
main_menu() {
    while true; do
        clear
        print_header
        echo -e "${CYAN}1. Setup Pool Mining${NC}"
        echo -e "${CYAN}2. Setup Solo Mining${NC}"
        echo -e "${CYAN}3. Check System Requirements${NC}"
        echo -e "${CYAN}4. Exit${NC}"
        echo -e "${PURPLE}=================================================${NC}"
        echo -e "${YELLOW}Please select an option (1-4):${NC}"
        read choice
        
        # Debugging: Show the value of $choice
        echo "You selected: $choice"
        
        # Make sure the choice is a valid option (1-4)
        if [[ "$choice" =~ ^[1-4]$ ]]; then
            case $choice in
                1) setup_pool_mining ;;
                2) setup_solo_mining ;;
                3) check_requirements ;;
                4) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
            esac
        else
            echo -e "${RED}Invalid option, please choose between 1 and 4.${NC}"
        fi
        
        # Allow user to press Enter to return to main menu
        if [ "$choice" != "4" ]; then
            echo -e "\n${YELLOW}Press Enter to return to main menu...${NC}"
            read
        fi
    done
}

# Start the script
main_menu
