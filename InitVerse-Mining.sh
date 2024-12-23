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

# Update system
echo -e "${BLUE}Yo, kita lagi ngupdate sistem nih! Biar gak ketinggalan zaman...${NC}"
sudo apt-get update && sudo apt-get upgrade -y
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Sistem udah kekinian! Semua paket terupdate!${NC}"
else
    echo -e "${RED}Aduh, ada yang salah. Gagal update nih!${NC}"
    exit 1
fi

# Memastikan alamat wallet sudah ada atau meminta input jika kosong
while true; do
    if [[ -z "$WALLET_ADDRESS" ]]; then
        echo -e "${RED}Reward address belum diset. Silakan masukkan alamat wallet untuk Solo Mining!${NC}"
        read -p "Masukkan alamat wallet (contoh: 0x...): " WALLET_ADDRESS
    else
        echo -e "${GREEN}Reward address sudah diset: $WALLET_ADDRESS${NC}"
        break
    fi
done

# Meminta input nama worker
read -p "Masukkan nama worker (default: Worker001): " WORKER_NAME
WORKER_NAME="${WORKER_NAME:-Worker001}"
echo -e "${GREEN}Worker name yang dipilih: $WORKER_NAME${NC}"

# Mengecek jumlah core CPU yang tersedia
echo -e "${CYAN}Total core CPU yang tersedia: $CPU_CORES. Banyak banget kan?${NC}"

# Meminta input jumlah core CPU untuk Mining Pool
read -p "Berapa banyak core yang mau kamu pake buat Mining Pool? (1-${CPU_CORES}, default: 1): " pool_cores
pool_cores=${pool_cores:-1}

# Mengunduh software mining jika diperlukan
mkdir -p $MINER_DIR
cd $MINER_DIR
wget "$MINING_SOFTWARE_URL" -O iniminer-linux-x64

# Mengecek apakah file berhasil diunduh
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Perangkat lunak berhasil diunduh!${NC}"
else
    echo -e "${RED}Gagal ngunduh perangkat lunak!${NC}"
    exit 1
fi

# Memberikan izin eksekusi pada file
chmod +x iniminer-linux-x64

# Memulai Mining Pool dengan systemd (tidak di dalam screen)
echo -e "${BLUE}Memulai Mining Pool dengan $pool_cores core CPU...${NC}"

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

# Memberikan waktu 5 detik untuk melihat log
sleep 5

# Menghentikan log mining pool
kill $!

# Solo Mining akan dijalankan dalam sesi screen terpisah
echo -e "${GREEN}Sekarang kita masuk ke sesi 'initverse' untuk Solo Mining...${NC}"

# Membuat sesi screen untuk Solo Mining
screen -dmS initverse bash -c "
    # Periksa apakah wallet address sudah diset, jika belum minta input dari user
    if [[ -z '$WALLET_ADDRESS' ]]; then
        echo -e '${RED}Alamat wallet belum diset, silakan masukkan alamat wallet untuk Solo Mining!${NC}'
        read -p 'Masukkan alamat wallet untuk Solo Mining (contoh: 0x...): ' WALLET_ADDRESS
    else
        echo -e '${GREEN}Alamat wallet sudah diset: $WALLET_ADDRESS${NC}'
    fi

    # Menampilkan jumlah CPU core yang tersedia
    echo -e '${CYAN}Total core CPU yang tersedia: $CPU_CORES. Banyak banget kan?${NC}'

    # Meminta input jumlah core CPU untuk Solo Mining
    read -p 'Berapa banyak core yang mau kamu pake buat Solo Mining? (1-${CPU_CORES}, default: 1): ' solo_cores
    solo_cores=${solo_cores:-1}

    # Setup etherbase untuk Solo Mining
    echo 'miner.setEtherbase(\"$WALLET_ADDRESS\")' > /root/ini-miner/data/geth/console
    echo -e '${YELLOW}Setting up mining untuk Solo Mining...${NC}'

    # Setup mining untuk Solo Mining
    echo 'miner.start('$solo_cores')'  # Mining dengan jumlah core yang dipilih
"

# Menampilkan informasi bahwa sesi 'initverse' sudah dijalankan
echo -e "${GREEN}Setup Solo Mining selesai dan berjalan di sesi 'initverse'!${NC}"

# Pindah ke sesi `screen` otomatis
screen -r initverse

# Menu untuk pilihan
while true; do
    echo -e "${CYAN}Apa yang ingin Anda lakukan?${NC}"
    echo "1. Hentikan Solo Mining dan Mining Pool"
    echo "2. Hentikan dan hapus semua file (Solo Mining dan Mining Pool)"
    echo "3. Keluar (Tidak menutup sesi screen, mining tetap berjalan)"

    read -p "Pilih opsi (1-3): " option

    case $option in
        1)
            # Menghentikan Solo Mining dan Mining Pool
            screen -S initverse -X quit
            sudo systemctl stop mining-pool.service
            sudo systemctl disable mining-pool.service
            echo -e "${GREEN}Solo Mining dan Mining Pool dihentikan!${NC}"
            ;;
        2)
            # Menghentikan dan menghapus semua file (Solo Mining, Pool Mining, dan screen)
            screen -S initverse -X quit
            sudo systemctl stop mining-pool.service
            sudo systemctl disable mining-pool.service
            sudo rm -rf $MINER_DIR
            sudo rm /etc/systemd/system/mining-pool.service
            sudo systemctl daemon-reload
            echo -e "${GREEN}Semua file dan layanan telah dihapus!${NC}"
            exit 0  # Keluar dari skrip dan kembali ke SSH
            ;;
        3)
            # Keluar dari skrip tanpa menutup sesi screen
            echo -e "${GREEN}Keluar dari skrip, tetapi sesi 'initverse' tetap berjalan.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opsi tidak valid. Silakan pilih antara 1 hingga 3.${NC}"
            ;;
    esac
    # Menampilkan kembali menu setelah aksi selesai
    echo -e "${CYAN}Kembali ke menu utama...${NC}"
done
