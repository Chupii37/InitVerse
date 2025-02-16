#!/bin/bash

# Color definitions for better output visibility
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Function to log messages with color
log_message() {
    echo -e "$1"
}

# Function to display the logo
display_logo() {
    log_message "${CYAN}🎨 Displaying logo...${RESET}"
    wget -qO- https://raw.githubusercontent.com/Chupii37/Chupii-Node/refs/heads/main/Logo.sh | bash || handle_error "🚨 Failed to fetch the logo script."
}

# Error handling function
handle_error() {
    log_message "${RED}⚠️ $1${RESET}"
    exit 1
}

# Update and upgrade system packages
update_system() {
    log_message "${YELLOW}🔄 Updating system...${RESET}"
    sudo apt-get update && sudo apt-get upgrade -y || handle_error "🚨 System update failed."
}

# Check if Docker is installed
check_docker() {
    log_message "${YELLOW}🔍 Checking Docker installation...${RESET}"
    if ! command -v docker &> /dev/null; then
        handle_error "🚨 Docker is not installed. Please install Docker and try again."
    fi
}

# Check if wget is installed
check_wget() {
    log_message "${YELLOW}🔍 Checking wget installation...${RESET}"
    if ! command -v wget &> /dev/null; then
        handle_error "🚨 wget is not installed. Please install wget and try again."
    fi
}

# Create the folder inichain-docker and navigate into it
create_folder() {
    log_message "${YELLOW}📂 Creating folder inichain-docker...${RESET}"
    mkdir -p inichain-docker || handle_error "🚨 Failed to create folder."
    cd inichain-docker || handle_error "🚨 Failed to change directory."
}

# Prompt for wallet address
get_wallet_address() {
    log_message "${CYAN}💰 Enter your wallet address: ${RESET}"
    read WALLET_ADDRESS
    if [[ -z "$WALLET_ADDRESS" ]]; then
        handle_error "🚨 Wallet address is required."
    fi
}

# Prompt for worker name with default
get_worker_name() {
    log_message "${CYAN}👤 Enter worker name (default: Worker001): ${RESET}"
    read WORKER_NAME
    worker_name=${WORKER_NAME:-Worker001}  # Use default if empty
}

# Prompt for CPU usage (default to all cores)
get_cpu_usage() {
    log_message "${CYAN}💻 Enter the number of CPUs you want to use (example: 2 for 2 CPUs): ${RESET}"
    read cpu_count
    cpu_count=${cpu_count:-1}  # Default to 1 if empty
    if ! [[ "$cpu_count" =~ ^[0-9]+$ ]]; then
        handle_error "🚨 Invalid input for CPU count. Please enter a number."
    fi
    cpu_devices=""
    for ((i=0; i<cpu_count; i++)); do
        cpu_devices="--cpu-devices $i $cpu_devices"
    done
}

# Prompt for pool selection
get_pool_selection() {
    log_message "${CYAN}🌍 Select mining pool (a, b, or c): ${RESET}"
    read POOL
    case "$POOL" in
        a|A) pool="pool-a.yatespool.com:31588" ;;
        b|B) pool="pool-b.yatespool.com:32488" ;;
        c|C) pool="pool-c.yatespool.com:31189" ;;
        *) handle_error "🚨 Invalid pool selection. Please select 'a', 'b', or 'c'." ;;
    esac
    log_message "${CYAN}Selected pool: $pool${RESET}"  # Debugging log to verify pool selection
}

# Display the confirmation messages
display_confirmation() {
    log_message "${GREEN}✅ Wallet address set to: $WALLET_ADDRESS${RESET}"
    log_message "${GREEN}✅ Worker name set to: $WORKER_NAME${RESET}"
    log_message "${GREEN}✅ Number of CPUs to use: $cpu_count${RESET}"
    log_message "${GREEN}✅ Mining pool selected: $pool${RESET}"
}

# Create the Dockerfile with the provided inputs
create_dockerfile() {
    log_message "${CYAN}📝 Creating Dockerfile...${RESET}"
    cat > Dockerfile <<EOF
FROM ubuntu:20.04

# Install wget for downloading the miner
RUN apt-get update && apt-get install -y wget

WORKDIR /miner

# Download and set permissions for the miner binary
RUN wget https://github.com/Project-InitVerse/miner/releases/download/v1.0.0/iniminer-linux-x64 -O iniminer-linux-x64 && \
    chmod +x iniminer-linux-x64

# Run the miner with the provided parameters
CMD ["/bin/bash", "-c", "./iniminer-linux-x64 --pool stratum+tcp://$WALLET_ADDRESS.$WORKER_NAME@$pool $cpu_devices"]
EOF
}

# Build the Docker image
build_docker_image() {
    log_message "${GREEN}🚀 Building Docker image...${RESET}"
    docker build -t iniminer . || handle_error "🚨 Docker build failed."
}

# Run the Docker container
run_docker_container() {
    log_message "${GREEN}🏃‍♂️ Running Docker container...${RESET}"
    docker run -d --name iniminer --restart unless-stopped iniminer || handle_error "🚨 Docker container failed to start."
}

# Display the logo
display_logo

# Perform system update and check for Docker and wget
update_system
check_docker
check_wget

# Prepare the directory for Docker setup
create_folder

# Get necessary inputs from the user
get_wallet_address
get_worker_name
get_cpu_usage
get_pool_selection

# Generate the Dockerfile based on user input
create_dockerfile

# Build and run the Docker container
build_docker_image
run_docker_container

# Final success message with emoji
log_message "${GREEN}🎉🚀✨ Your Docker container is now running with automatic restart enabled! 🎉 To view the logs in real-time, run the following command:${RESET}"
log_message "${CYAN}docker logs -f iniminer${RESET}"
