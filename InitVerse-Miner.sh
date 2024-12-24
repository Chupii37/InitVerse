#!/bin/bash

# Menentukan warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Memperbarui dan mengupgrade sistem
echo -e "${CYAN}Memperbarui dan mengupgrade sistem...${NC}"
sudo apt-get update && sudo apt-get upgrade -y

# Install curl jika belum ada
echo -e "${YELLOW}Menginstal curl...${NC}"
sudo apt-get install -y curl

# Instalasi NVM (Node Version Manager)
echo -e "${GREEN}Siap-siap, kita akan install NVM!${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
echo 'export NVM_DIR="$HOME/.nvm"' >> $HOME/.bash_profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> $HOME/.bash_profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> $HOME/.bash_profile

# Memuat konfigurasi NVM
source $HOME/.bash_profile

# Instalasi versi LTS Node.js
echo -e "${GREEN}Menginstal Node.js LTS...${NC}"
nvm install --lts

# Menampilkan versi Node.js dan npm
node -v
npm -v

# Instalasi Python jika belum ada
echo -e "${YELLOW}Ayo kita instal Python supaya bisa... mining?${NC}"
sudo apt install -y python3 python3-pip

# Instalasi systemctl (jika belum terinstall)
echo -e "${CYAN}Memastikan systemctl terinstal...${NC}"
sudo apt-get install -y systemd

# Mengonfigurasi wallet address dan nama worker
while true; do
    echo -e "${BLUE}Masukkan wallet address (contoh: 0x...)${NC}:"
    read wallet_address
    # Memastikan wallet address diisi
    if [ -z "$wallet_address" ]; then
        echo -e "${RED}Wallet address tidak boleh kosong! Skrip dibatalkan.${NC}"
        exit 1
    else
        break
    fi
done

# Meminta nama worker (gunakan default jika kosong)
echo -e "${BLUE}Masukkan nama worker (default: worker001):${NC}"
read worker_name
worker_name=${worker_name:-worker001}

# Membuat folder untuk miner (menggunakan nama folder ini-miner)
miner_folder="$HOME/ini-miner"
echo -e "${YELLOW}Membuat folder untuk miner di $miner_folder...${NC}"
mkdir -p $miner_folder
cd $miner_folder

# Mengunduh software mining
echo -e "${GREEN}Mengunduh software mining...${NC}"
curl -L -o iniminer-linux-x64 https://github.com/Project-InitVerse/miner/releases/download/v1.0.0/iniminer-linux-x64

# Memastikan file berhasil diunduh
if [ ! -f iniminer-linux-x64 ]; then
    echo -e "${RED}Gagal mengunduh software mining. Skrip dibatalkan.${NC}"
    exit 1
fi

# Memberikan izin eksekusi pada file
chmod +x iniminer-linux-x64

# Menanyakan berapa banyak CPU yang akan digunakan untuk mining
echo -e "${YELLOW}Berapa banyak CPU yang akan kamu gunakan untuk mining? (Misal: 4)${NC}"
read cpu_count
cpu_count=${cpu_count:-1}

# Menyiapkan file systemd untuk menjalankan mining
echo -e "${CYAN}Membuat service systemd untuk mining...${NC}"

# Membuat file unit systemd dengan path yang benar
if [ "$(id -u)" -eq 0 ]; then
    # Jika menjalankan sebagai root, gunakan $HOME yang sesuai untuk root
    exec_start="/ini-miner/iniminer-linux-x64 -t $cpu_count --pool stratum+tcp://$wallet_address.$worker_name@pool-core-testnet.inichain.com:32672"
else
    # Jika bukan root, gunakan $HOME untuk user biasa
    exec_start="$HOME/ini-miner/iniminer-linux-x64 -t $cpu_count --pool stratum+tcp://$wallet_address.$worker_name@pool-core-testnet.inichain.com:32672"
fi

# Membuat file unit systemd untuk service
echo -e "${GREEN}Membuat file systemd untuk mining service...${NC}"
cat << EOF | sudo tee /etc/systemd/system/mining.service
[Unit]
Description=Mining Service
After=network.target

[Service]
ExecStart=$exec_start
Restart=always
User=$USER
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Memuat dan menjalankan service
echo -e "${CYAN}Memuat dan menjalankan service dengan systemd...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable mining.service
sudo systemctl start mining.service

echo -e "${GREEN}Skrip selesai! Mining sedang berjalan dengan systemd. Good luck!${NC}"

# Menambahkan pemeriksaan log tanpa rentang waktu
echo -e "${CYAN}Memeriksa log dari mining service...${NC}"
sudo journalctl -u mining.service -f --no-hostname -o cat
