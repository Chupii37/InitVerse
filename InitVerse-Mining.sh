#!/bin/bash

# Warna-warna kece untuk mempercantik tampilan
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # Normal tanpa warna

# Memperbarui sistem, biar gak ketinggalan zaman
echo -e "${BLUE}Yo, kita lagi ngupdate sistem nih! Biar gak ketinggalan zaman...${NC}"
sudo apt-get update && sudo apt-get upgrade -y
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Sistem udah kekinian! Semua paket terupdate!${NC}"
else
    echo -e "${RED}Aduh, ada yang salah. Gagal update nih!${NC}"
    exit 1
fi

# Instalasi NVM, biar bisa pakai Node.js yang keren
echo -e "${BLUE}Yuk kita pasang NVM, biar bisa install Node.js yang kece!${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
if [ $? -eq 0 ]; then
    echo -e "${GREEN}NVM sukses terpasang! Keren kan?${NC}"
else
    echo -e "${RED}Gagal pasang NVM! Ada yang gak beres nih...${NC}"
    exit 1
fi

# Menambahkan NVM ke dalam konfigurasi shell
echo 'export NVM_DIR="$HOME/.nvm"' >> $HOME/.bash_profile
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Ini buat muat nvm' >> $HOME/.bash_profile
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Ini buat bash completion nvm' >> $HOME/.bash_profile

# Muat ulang profil bash biar NVM-nya jalan
source $HOME/.bash_profile

# Instalasi Node.js versi LTS
echo -e "${BLUE}Sedang menginstal Node.js LTS... Pasti keren deh!${NC}"
nvm install --lts
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Node.js LTS udah terpasang! Kamu siap bikin aplikasi!${NC}"
else
    echo -e "${RED}Gagal pasang Node.js. Ada yang salah nih!${NC}"
    exit 1
fi

# Menampilkan versi Node.js dan NPM
echo -e "${BLUE}Versi Node.js yang terpasang:${NC}"
node -v
echo -e "${BLUE}Versi NPM yang terpasang:${NC}"
npm -v

# Cek apakah python3.10 tersedia di sistem
echo -e "${BLUE}Cek apakah Python 3.10 tersedia...${NC}"
python_version=$(python3.10 --version 2>/dev/null)

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Python 3.10 terdeteksi! Lanjutkan dengan instalasi venv.${NC}"
else
    echo -e "${RED}Python 3.10 gak ditemukan! Mencoba versi lain...${NC}"
    # Cek apakah python3 ada versi lainnya
    python_version=$(python3 --version 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Python 3.x ditemukan: $python_version. Menggunakan versi ini untuk venv.${NC}"
    else
        echo -e "${RED}Gagal menemukan Python! Pastikan Python 3 terinstal!${NC}"
        exit 1
    fi
fi

# Instalasi python3-venv sesuai versi Python yang ada
echo -e "${BLUE}Menginstal python3-venv untuk versi Python yang terdeteksi...${NC}"
sudo apt install python3-venv -y
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Python venv berhasil terinstal!${NC}"
else
    echo -e "${RED}Gagal menginstal Python venv! Ada yang ngaco nih...${NC}"
    exit 1
fi

# Mencoba menginstall symcl jika tersedia di repositori atau mengunduh dari sumber lain
echo -e "${BLUE}Sekarang install symcl, biar makin mantap!${NC}"

# Cek apakah symcl tersedia di repositori atau kita perlu install dari sumber lain
sudo apt-get install symcl -y
if [ $? -ne 0 ]; then
    echo -e "${RED}Paket symcl tidak ditemukan di repositori. Mencoba mengunduhnya secara manual...${NC}"
    # Coba mengunduh symcl atau menggunakan pip jika symcl adalah paket Python
    echo -e "${CYAN}Mencoba mengunduh dan menginstal symcl menggunakan pip...${NC}"
    pip install symcl
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Symcl berhasil diinstal menggunakan pip!${NC}"
    else
        echo -e "${RED}Gagal menginstal symcl menggunakan pip!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}Symcl terpasang dengan sukses!${NC}"
fi

# Mengonfigurasi Mining Pool
echo -e "${BLUE}Yuk mulai konfigurasi Mining Pool...${NC}"

# Meminta input untuk reward address dan memastikan address valid
while true; do
    read -p "Masukkan reward address (contoh: 0x...): " reward_address
    if [[ -z "$reward_address" ]]; then
        echo -e "${RED}Reward address gak boleh kosong, ya! Masukkan yang bener dong!${NC}"
    else
        echo -e "${GREEN}Reward address diterima: $reward_address. Mantap!${NC}"
        break
    fi
done

# Meminta input untuk nama worker
read -p "Masukkan worker name (default: Workerr001): " worker_name
worker_name="${worker_name:-Workerr001}"
echo -e "${GREEN}Worker name yang dipilih: $worker_name. Keren kan?${NC}"

# Membuat folder dan mengunduh perangkat lunak mining
echo -e "${BLUE}Bikin folder buat mining dan unduh perangkat lunak...${NC}"
mkdir -p ~/ini-miner
cd ~/ini-miner
wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64 -O iniminer-linux-x64

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
CPU_CORES=$(nproc)
echo -e "${CYAN}Total core CPU yang tersedia: $CPU_CORES. Banyak banget kan?${NC}"

# Menanyakan jumlah core CPU yang ingin digunakan untuk Mining Pool
echo -e "${CYAN}Berapa banyak core yang mau kamu pake buat Mining Pool? (1-${CPU_CORES}, default: 1):${NC}"
read pool_cores
pool_cores=${pool_cores:-1}

# Memulai Mining Pool dengan jumlah core yang dipilih
echo -e "${BLUE}Memulai Mining Pool dengan $pool_cores core CPU...${NC}"
MINING_POOL_CMD="./iniminer-linux-x64 --pool stratum+tcp://$reward_address.$worker_name@pool-core-testnet.inichain.com:32672"
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
ExecStart=$MINING_POOL_CMD
WorkingDirectory=/home/username/ini-miner
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/mining-pool.service

# Mengaktifkan dan memulai service Mining Pool
sudo systemctl daemon-reload
sudo systemctl enable mining-pool.service
sudo systemctl start mining-pool.service

# Mengonfigurasi Solo Mining
echo -e "${BLUE}Sekarang kita setup Solo Mining!${NC}"

# Meminta input untuk alamat wallet Solo Mining
while true; do
    read -p "Masukkan alamat wallet untuk Solo Mining (contoh: 0x...): " WALLET_ADDRESS
    if [[ -z "$WALLET_ADDRESS" ]]; then
        echo -e "${RED}Alamat wallet untuk Solo Mining gak boleh kosong, ya!${NC}"
    else
        echo -e "${GREEN}Alamat wallet diterima: $WALLET_ADDRESS${NC}"
        break
    fi
done

# Membuat folder Solo Mining setelah wallet address dimasukkan
echo -e "${CYAN}Membuat folder khusus untuk Solo Mining...${NC}"
SOLO_MINING_DIR=~/solo-mining
mkdir -p $SOLO_MINING_DIR
cd $SOLO_MINING_DIR

# Mengunduh perangkat lunak geth untuk Solo Mining
echo -e "${BLUE}Mengunduh perangkat lunak geth untuk solo mining...${NC}"
wget https://github.com/Project-InitVerse/ini-chain/releases/download/v1.0.0/geth-linux-x64

# Menampilkan jumlah CPU yang tersisa untuk Solo Mining
echo -e "${CYAN}Sisa CPU yang tersedia untuk solo mining: $CPU_CORES${NC}"

# Menanyakan jumlah core CPU yang ingin digunakan untuk Solo Mining
echo -e "${CYAN}Berapa banyak core yang mau kamu pake buat Solo Mining? (1-${CPU_CORES}, default: 1):${NC}"
read solo_cores
solo_cores=${solo_cores:-1}

# Menyiapkan perintah untuk Solo Mining
echo -e "${BLUE}Memulai Solo Mining dengan $solo_cores core CPU...${NC}"
echo "./geth-linux-x64 --datadir data --http.api=\"eth,admin,miner,net,web3,personal\" --allow-insecure-unlock --testnet console" > solo_mining_cmd.sh
echo "miner.setEtherbase('$WALLET_ADDRESS')" >> solo_mining_cmd.sh
echo "miner.start($solo_cores)" >> solo_mining_cmd.sh

# Membuat unit systemd untuk Solo Mining
echo -e "[Unit]
Description=Solo Mining Service
After=network.target

[Service]
ExecStart=/bin/bash /home/$USER/solo-mining/solo_mining_cmd.sh
WorkingDirectory=/home/$USER/solo-mining
Restart=always
User=$USER

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/solo-mining.service

# Mengaktifkan dan memulai service Solo Mining
sudo systemctl daemon-reload
sudo systemctl enable solo-mining.service
sudo systemctl start solo-mining.service

# Menyelesaikan Setup
echo -e "${GREEN}Woohoo! Setup Mining Pool dan Solo Mining udah selesai! Ayo mulai nambang!${NC}"
