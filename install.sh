#!/bin/bash
clear

# Configuration settings
RAM_GB="32"
CPU_CORES="8"
DISK_ADD="40"

echo "=========================================================="
echo "          SAFE & CLEAN LOCAL QEMU VPS SETUP               "
echo "=========================================================="
echo ""

# Ask for credentials safely
read -p "🔹 Enter Username (Default: ubuntu): " USER_NAME
USER_NAME=${USER_NAME:-ubuntu}

# Read password silently so it stays private on your screen
read -s -p "🔹 Enter Password: " USER_PASS
echo ""

# Update and install dependencies locally
echo "⏳ Installing system dependencies..."
sudo apt-get update -y > /dev/null 2>&1
sudo apt-get install -y qemu-system-x86 qemu-utils wget cloud-image-utils > /dev/null 2>&1

# Create target directory
sudo mkdir -p /home/daytona
sudo chmod 777 /home/daytona

# Download Ubuntu Cloud Image safely if it doesn't exist
if [ ! -f "/home/daytona/ubuntu22.qcow2" ]; then
    echo "📥 Downloading Ubuntu 22.04 Cloud Image (this may take a few minutes)..."
    sudo wget -q --show-progress https://ubuntu.com -O /home/daytona/ubuntu22.qcow2
    sudo chmod 666 /home/daytona/ubuntu22.qcow2
fi

# ⚠️ FIXED: Added single quotes 'EOF' so your password is written literally 
cat << 'EOF' > user-data
#cloud-config
ssh_pwauth: True
chpasswd:
  list: |
    REPLACE_USER:REPLACE_PASS
  expire: False
EOF

# Swap out the placeholders safely using sed
sed -i "s/REPLACE_USER/$USER_NAME/g" user-data
sed -i "s/REPLACE_PASS/$USER_PASS/g" user-data

echo "⚙️ Building cloud infrastructure..."
cloud-localds seed.img user-data > /dev/null 2>&1

echo "💾 Expanding disk allocation (+${DISK_ADD}GB)..."
sudo qemu-img resize /home/daytona/ubuntu22.qcow2 +${DISK_ADD}G > /dev/null 2>&1

clear
echo "=========================================================="
echo "🚀 BOOTING VIRTUAL MACHINE..."
echo "=========================================================="
echo "👤 Username : $USER_NAME"
echo "🔒 Password : (Your secure password)"
echo "--------------------------------------------------------"
echo "💡 To exit the VM screen at any time: Press Ctrl+A, then X"
echo "=========================================================="
echo ""

# Boot QEMU purely locally with zero third-party tracking links
qemu-system-x86_64 \
    -hda /home/daytona/ubuntu22.qcow2 \
    -m "${RAM_GB}G" \
    -smp $CPU_CORES \
    -drive file=seed.img,format=raw \
    -nographic \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device e1000,netdev=net0
