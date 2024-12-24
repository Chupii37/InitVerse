#!/bin/bash

# Warna untuk menampilkan pesan
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fungsi untuk memvalidasi wallet address (cek apakah dimulai dengan "0x")
validate_wallet() {
    if [[ "$1" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        return 0  # Valid
    else
        return 1  # Invalid
    fi
}

# Memastikan systemctl terinstal
echo -e "${CYAN}🚀 Hey, kita cek dulu pembaruan sistem dan pastikan systemctl sudah terinstal!${NC}"
sudo apt-get update && sudo apt-get upgrade -y

# Memastikan systemctl terinstal
echo -e "${CYAN}🛠️ Memastikan systemctl terinstal...${NC}"
sudo apt-get install -y systemd

# Memastikan NVM, Node.js, dan npm terinstal
echo -e "${CYAN}😎 NVM, Node.js, dan npm? Kita pastikan semua terinstal nih...${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.bashrc
nvm install --lts

# Memastikan python terinstal
echo -e "${CYAN}🐍 Python-nya sudah ada belum ya? Kita cek dulu...${NC}"
sudo apt-get install -y python3

# Mining Pool Setup
echo -e "${CYAN}💰 Masukkan wallet address (contoh: 0x...) yang keren punya!${NC}"
# Mendapatkan wallet address dengan validasi
WALLET_ADDRESS=""
while [ -z "$WALLET_ADDRESS" ] || ! validate_wallet "$WALLET_ADDRESS"; do
    read WALLET_ADDRESS
    if [ -z "$WALLET_ADDRESS" ]; then
        echo -e "${RED}⚠️ Oops! Wallet address gak boleh kosong, ya! Coba masukkan yang valid dong!${NC}"
    elif ! validate_wallet "$WALLET_ADDRESS"; then
        echo -e "${RED}⚠️ Alamat wallet gak valid! Harus dimulai dengan '0x' dan diikuti oleh 40 karakter alfanumerik!${NC}"
    fi
done

# Mendapatkan nama worker (gunakan default jika kosong)
echo -e "${CYAN}🤖 Masukkan nama worker (default: Worker001), atau terserah kamu deh...${NC}"
read input_worker
WORKER_NAME=${input_worker:-Worker001}

# Menampilkan konfirmasi
echo -e "${GREEN}🎉 Wallet address diset ke: $WALLET_ADDRESS${NC}"
echo -e "${GREEN}🖥️ Nama worker diset ke: $WORKER_NAME${NC}"

# Membuat folder untuk miner
echo -e "${CYAN}🛠️ Yuk, kita siapin folder untuk miner-nya...${NC}"
mkdir -p ~/ini-miner
cd ~/ini-miner

# Download dan instal software mining
echo -e "${CYAN}🚀 Mendownload software mining... Mohon tunggu, jangan kemana-mana!${NC}"
wget https://github.com/Project-InitVerse/miner/releases/download/v1.0.0/iniminer-linux-x64 -O iniminer-linux-x64

# Mengecek apakah download berhasil
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Gagal mendownload software mining! Cek koneksi internet atau URL-nya, ya!${NC}"
    exit 1
fi

# Mengubah izin agar file bisa dieksekusi
chmod +x iniminer-linux-x64

# Mengecek apakah chmod berhasil
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Gagal memberikan izin eksekusi! Jangan lupa, kamu harus punya izin untuk itu!${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Software mining berhasil diunduh dan diinstal! Sekarang siap menambang!${NC}"

# Menanyakan jumlah CPU yang akan digunakan
echo -e "${CYAN}🤖 Masukkan jumlah CPU yang ingin digunakan (contoh: 2 untuk 2 CPU):${NC}"
read cpu_count
cpu_count=${cpu_count:-1}

# Menjalankan mining dengan systemd
echo -e "${CYAN}🔧 Mengonfigurasi systemd untuk menjalankan mining... Bentar, ya...${NC}"

# Membuat unit systemd untuk menjalankan mining
cat <<EOF | sudo tee /etc/systemd/system/ini-miner.service > /dev/null
[Unit]
Description=InitVerse Miner
After=network.target

[Service]
User=$USER
ExecStart=/bin/bash -c 'cd $HOME/ini-miner && ./iniminer-linux-x64 --pool stratum+tcp://$WALLET_ADDRESS.$WORKER_NAME@pool-core-testnet.inichain.com:32672 --cpu $cpu_count'
WorkingDirectory=$HOME/ini-miner
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Mengaktifkan dan memulai mining dengan systemd
echo -e "${CYAN}⚡ Mengaktifkan dan memulai systemd service untuk mining...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable ini-miner
sudo systemctl start ini-miner

# Verifikasi apakah mining berjalan dengan benar
echo -e "${GREEN}🎉 Mining telah dimulai dengan systemd! Let's go!${NC}"
echo -e "${CYAN}🔍 Untuk memeriksa status mining, gunakan perintah berikut:${NC}"
echo -e "${CYAN}sudo journalctl -u ini-miner -f --no-hostname -o cat${NC}"
