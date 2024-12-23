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
FULL_NODE_URL="https://github.com/Project-InitVerse/ini-chain/archive/refs/tags/v1.0.0.tar.gz"
POOL_ADDRESS="pool-core-testnet.inichain.com:32672"

# Memperbarui sistem, biar gak ketinggalan zaman
echo -e "${BLUE}Yo, kita lagi ngupdate sistem nih! Biar gak ketinggalan zaman...${NC}"
sudo apt-get update && sudo apt-get upgrade -y
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Sistem udah kekinian! Semua paket terupdate!${NC}"
else
    echo -e "${RED}Aduh, ada yang salah. Gagal update nih!${NC}"
    exit 1
fi

# Install systemctl jika belum ada
if ! command -v systemctl &> /dev/null; then
    echo -e "${BLUE}Systemd belum terpasang. Sekarang kita pasang!${NC}"
    sudo apt-get install systemd -y
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Systemd berhasil dipasang!${NC}"
    else
        echo -e "${RED}Gagal pasang Systemd. Ada yang error nih!${NC}"
        exit 1
    fi
fi

# Mengonfigurasi Mining Pool
echo -e "${BLUE}Yuk mulai konfigurasi Mining Pool...${NC}"

# Meminta input untuk reward address dan memastikan address valid
while true; do
    read -p "Masukkan reward address (contoh: 0x...): " WALLET_ADDRESS
    if [[ -z "$WALLET_ADDRESS" ]]; then
        echo -e "${RED}Reward address gak boleh kosong, ya! Masukkan yang bener dong!${NC}"
    else
        echo -e "${GREEN}Reward address diterima: $WALLET_ADDRESS. Mantap!${NC}"
        break
    fi
done

# Meminta input untuk nama worker
read -p "Masukkan worker name (default: Worker001): " WORKER_NAME
WORKER_NAME="${WORKER_NAME:-Worker001}"
echo -e "${GREEN}Worker name yang dipilih: $WORKER_NAME. Keren kan?${NC}"

# Membuat folder dan mengunduh perangkat lunak mining
echo -e "${YELLOW}Downloading mining software...${NC}"
MINER_DIR="/root/ini-miner"
mkdir -p $MINER_DIR
cd $MINER_DIR
wget "$MINING_SOFTWARE_URL" -O iniminer-linux-x64

# Mengecek apakah file berhasil diunduh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Perangkat lunak berhasil diunduh! Gokil!${NC}"
else
    echo -e "${RED}Gagal ngunduh perangkat lunak! Wah, ada yang salah nih!${NC}"
    exit 1
fi

# Memberikan izin eksekusi pada file
chmod +x iniminer-linux-x64

# Menampilkan jumlah CPU core yang tersedia
echo -e "${CYAN}Total core CPU yang tersedia: $CPU_CORES. Banyak banget kan?${NC}"

# Menanyakan jumlah core CPU yang ingin digunakan untuk Mining Pool
echo -e "${CYAN}Berapa banyak core yang mau kamu pake buat Mining Pool? (1-${CPU_CORES}, default: 1):${NC}"
read pool_cores
pool_cores=${pool_cores:-1}

# Memulai Mining Pool dengan jumlah core yang dipilih
echo -e "${BLUE}Memulai Mining Pool dengan $pool_cores core CPU...${NC}"
MINING_POOL_CMD="./iniminer-linux-x64 --pool stratum+tcp://$WALLET_ADDRESS.$WORKER_NAME@$POOL_ADDRESS"
for ((i=0; i<pool_cores; i++)); do
    MINING_POOL_CMD+=" --cpu-devices $i"
done

# Menampilkan perintah yang akan dijalankan
echo -e "${GREEN}Ini dia perintah Mining Pool yang bakal dijalankan: ${BLUE}$MINING_POOL_CMD${NC}"

# Membuat unit systemd untuk Mining Pool
echo -e "[Unit]
Description=Mining Pool Service

After=network.target

[Service]
ExecStart=$MINER_DIR/iniminer-linux-x64 --pool stratum+tcp://$WALLET_ADDRESS.$WORKER_NAME@$POOL_ADDRESS
WorkingDirectory=$MINER_DIR
Restart=always
User=root

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/mining-pool.service

# Mengaktifkan dan memulai service Mining Pool
sudo systemctl daemon-reload
sudo systemctl enable mining-pool.service
sudo systemctl start mining-pool.service

# Menampilkan log Mining Pool selama 5 detik
echo -e "${BLUE}Menampilkan log Mining Pool selama 5 detik...${NC}"
sudo journalctl -u mining-pool.service -f & 
sleep 5
kill $!

# Membuat sesi `screen` untuk Solo Mining setelah log Mining Pool selesai
echo -e "${GREEN}Membuat sesi screen 'initverse' untuk Solo Mining...${NC}"
screen -dmS initverse bash -c "
    # Mengonfigurasi Solo Mining
    echo -e '${BLUE}Sekarang kita setup Solo Mining!${NC}'

    # Meminta input untuk alamat wallet Solo Mining
    while true; do
        read -p 'Masukkan alamat wallet untuk Solo Mining (contoh: 0x...): ' WALLET_ADDRESS
        if [[ -z \"\$WALLET_ADDRESS\" ]]; then
            echo -e '${RED}Alamat wallet untuk Solo Mining gak boleh kosong, ya!${NC}'
        else
            echo -e '${GREEN}Alamat wallet diterima: \$WALLET_ADDRESS${NC}'
            break
        fi
    done

    # Download dan setup full node untuk Solo Mining
    echo -e '${YELLOW}Downloading full node untuk Solo Mining...${NC}'
    wget '$FULL_NODE_URL' -O ini-chain.tar.gz
    tar -xzf ini-chain.tar.gz

    # Download geth
    wget https://github.com/Project-InitVerse/ini-chain/releases/download/v1.0.0/geth-linux-x64
    chmod +x geth-linux-x64

    # Mulai node untuk Solo Mining
    echo -e '${GREEN}Starting full node untuk Solo Mining...${NC}'
    ./geth-linux-x64 --datadir data --http.api='eth,admin,miner,net,web3,personal' --allow-insecure-unlock --testnet console &

    # Setup mining untuk Solo Mining
    echo -e '${YELLOW}Setting up mining untuk Solo Mining...${NC}'
    echo 'miner.setEtherbase(\"\$WALLET_ADDRESS\")'

    # Menanyakan jumlah core CPU yang ingin digunakan untuk Solo Mining
    echo -e '${CYAN}Berapa banyak core yang mau kamu pake buat Solo Mining? (1-${CPU_CORES}, default: 1):${NC}'
    read solo_cores
    solo_cores=${solo_cores:-1}

    echo 'miner.start(\$solo_cores)'
"

# Menyelesaikan setup
echo -e "${GREEN}Setup Solo Mining selesai dan berjalan di sesi 'initverse'!${NC}"
