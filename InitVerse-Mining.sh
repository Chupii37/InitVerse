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
    # clear  # Menonaktifkan clear untuk menghindari kedipan
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

# Main menu function
main_menu() {
    while true; do
        print_header
        echo -e "${CYAN}1. Setup Pool Mining${NC}"
        echo -e "${CYAN}2. Setup Solo Mining${NC}"
        echo -e "${CYAN}3. Check System Requirements${NC}"
        echo -e "${CYAN}4. Exit${NC}"
        echo -e "${PURPLE}=================================================${NC}"
        echo -e "${YELLOW}Please select an option (1-4):${NC}"
        
        # Menggunakan read dengan opsi -r untuk menghindari karakter tak terlihat
        read -r choice
        
        # Debugging: Menampilkan pilihan untuk memastikan input diterima dengan benar
        echo "You selected: $choice"
        
        # Mengecek apakah input sesuai dengan angka 1-4
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
        
        # Menghapus bagian sleep agar tidak ada jeda waktu tambahan
    done
}

# Start the script
main_menu
