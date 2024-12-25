#!/bin/bash

# Warna untuk menampilkan pesan
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Update dan upgrade sistem terlebih dahulu
echo -e "${CYAN}🔄 Memperbarui dan meng-upgrade sistem...${NC}"
sudo apt-get update && sudo apt-get upgrade -y

# Memastikan Docker terinstal
echo -e "${CYAN}🐳 Memastikan Docker terinstal...${NC}"
if ! command -v docker &> /dev/null
then
    echo -e "${RED}❌ Docker tidak terinstal. Menginstal Docker...${NC}"
    sudo apt-get install -y docker.io
    sudo systemctl enable --now docker
else
    echo -e "${GREEN}✅ Docker sudah terinstal.${NC}"
fi

# Memastikan NVM, Node.js, dan npm terinstal
echo -e "${CYAN}😎 Memastikan NVM, Node.js, dan npm terinstal nih...${NC}"

# Cek apakah nvm sudah terinstal dan load NVM jika sudah ada
if ! command -v nvm &> /dev/null
then
    echo -e "${CYAN}📥 Menginstal NVM...${NC}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
else
    echo -e "${GREEN}✅ NVM sudah terinstal.${NC}"
fi

# Menginstal Node.js
echo -e "${CYAN}📦 Menginstal Node.js versi LTS...${NC}"
nvm install --lts

# Memastikan Python terinstal
echo -e "${CYAN}🐍 Memastikan Python terinstal...${NC}"
sudo apt-get install -y python3

# Mining Pool Setup
echo -e "${CYAN}💰 Masukkan wallet address Anda (contoh: 0x1234567890abcdef):${NC}"
read -r WALLET_ADDRESS

# Pastikan input address tidak kosong
if [[ -z "$WALLET_ADDRESS" ]]; then
    echo -e "${RED}❌ Error: Wallet address tidak boleh kosong.${NC}"
    exit 1
fi  

# Mendapatkan nama worker (gunakan default jika kosong)
echo -e "${CYAN}🧰 Masukkan nama worker (default: Worker001):${NC}"
read input_worker
WORKER_NAME=${input_worker:-Worker001}

# Menampilkan konfirmasi
echo -e "${GREEN}✅ Wallet address diset ke: $WALLET_ADDRESS${NC}"
echo -e "${GREEN}✅ Nama worker diset ke: $WORKER_NAME${NC}"

# Membuat folder untuk miner
mkdir -p ~/ini-miner
cd ~/ini-miner

# Download dan instal software mining
echo -e "${CYAN}📥 Mendownload software mining...${NC}"
wget https://github.com/Project-InitVerse/miner/releases/download/v1.0.0/iniminer-linux-x64 -O iniminer-linux-x64
chmod +x iniminer-linux-x64

# Menanyakan jumlah CPU yang akan digunakan
echo -e "${CYAN}💻 Masukkan jumlah CPU yang ingin digunakan (contoh: 2 untuk 2 CPU):${NC}"
read cpu_count
cpu_count=${cpu_count:-1}

# Membuat daftar opsi --cpu-devices untuk setiap inti CPU yang dipilih
cpu_devices=""
for ((i = 0; i < cpu_count; i++)); do
    cpu_devices="$cpu_devices --cpu-devices $i"
done

# Membuat Dockerfile untuk miner
echo -e "${CYAN}📦 Membuat Dockerfile untuk mining...${NC}"
cat <<EOF > Dockerfile
FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install NVM, Node.js, dan npm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
ENV NVM_DIR=/root/.nvm
RUN ["/bin/bash", "-c", "source /root/.nvm/nvm.sh && nvm install --lts"]

# Menambahkan software mining
COPY iniminer-linux-x64 /usr/local/bin/iniminer
RUN chmod +x /usr/local/bin/iniminer

# Menjalankan miner
CMD ["/bin/bash", "-c", "/usr/local/bin/iniminer --pool stratum+tcp://$WALLET_ADDRESS.$WORKER_NAME@pool-core-testnet.inichain.com:32672 $cpu_devices"]
EOF

# Membangun Docker image
echo -e "${CYAN}🔨 Membangun Docker image...${NC}"
docker build -t ini-miner .

# Menjalankan kontainer Docker untuk mining
echo -e "${CYAN}⚙️ Menjalankan kontainer Docker untuk mining...${NC}"
docker run -d --name ini-miner-container ini-miner

# Verifikasi apakah mining berjalan dengan benar
echo -e "${GREEN}✅ Mining telah dimulai dengan Docker.${NC}"
echo -e "${CYAN}🔍 Untuk memeriksa status mining, gunakan perintah berikut:${NC}"
echo -e "${CYAN}docker logs -f ini-miner-container${NC}"
