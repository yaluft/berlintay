#!/bin/bash
# Debian KDE Post-Install Setup Script
# Run with: bash post-install.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Debian KDE Post-Install Setup...${NC}"

# Update system
echo -e "${YELLOW}Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

# Enable contrib and non-free repositories
echo -e "${YELLOW}Enabling contrib and non-free repositories...${NC}"
sudo apt-add-repository contrib non-free -y
sudo apt update

# Install essential build tools and libraries
echo -e "${YELLOW}Installing essential packages...${NC}"
sudo apt install -y \
    build-essential \
    cmake \
    curl \
    wget \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    linux-headers-$(uname -r) \
    dkms \
    pkg-config \
    libssl-dev \
    libfuse2

# AMD RX 5600 XT GPU Setup
echo -e "${YELLOW}Setting up AMD GPU drivers and tools...${NC}"
sudo apt install -y \
    firmware-amd-graphics \
    libgl1-mesa-dri \
    libglx-mesa0 \
    mesa-vulkan-drivers \
    xserver-xorg-video-amdgpu \
    radeontop \
    vulkan-tools \
    mesa-utils

# Intel CPU microcode and drivers
echo -e "${YELLOW}Installing Intel drivers...${NC}"
sudo apt install -y \
    intel-microcode \
    thermald \
    powertop

# USB 3.1 and general USB support
echo -e "${YELLOW}Installing USB 3.1 support...${NC}"
sudo apt install -y \
    usbutils \
    usb-modeswitch \
    exfat-fuse \
    exfat-utils

# Audio setup (PipeWire as VoiceMeeter alternative)
echo -e "${YELLOW}Setting up audio system with PipeWire...${NC}"
sudo apt install -y \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    qpwgraph \
    pavucontrol \
    pulseaudio-utils

# Enable PipeWire
systemctl --user enable pipewire pipewire-pulse wireplumber

# Steam, Wine, and Proton setup
echo -e "${YELLOW}Installing Steam and Wine...${NC}"
# Enable 32-bit architecture
sudo dpkg --add-architecture i386
sudo apt update

# Install Wine
sudo apt install -y \
    wine \
    wine32 \
    wine64 \
    libwine \
    winetricks

# Install Steam
wget -O steam.deb https://cdn.cloudflare.steamstatic.com/client/installer/steam.deb
sudo dpkg -i steam.deb || sudo apt-get install -f -y
rm steam.deb

# Gaming tools and ReShade alternatives
echo -e "${YELLOW}Installing gaming tools...${NC}"
sudo apt install -y \
    gamemode \
    mangohud \
    vkbasalt \
    goverlay

# Create vkBasalt config for ReShade-like effects
mkdir -p ~/.config/vkBasalt
cat > ~/.config/vkBasalt/vkBasalt.conf << 'EOF'
effects = cas:tonemap:smaa
cas = 0.5
toggleKey = Home
EOF

# ADB Tools
echo -e "${YELLOW}Installing ADB tools...${NC}"
sudo apt install -y adb fastboot

# Development tools
echo -e "${YELLOW}Installing development tools...${NC}"
sudo apt install -y \
    git \
    vim \
    nano \
    htop \
    neofetch \
    python3 \
    python3-pip \
    nodejs \
    npm

# Zsh and Oh My Zsh
echo -e "${YELLOW}Installing Zsh and Oh My Zsh...${NC}"
sudo apt install -y zsh
# Install Oh My Zsh (non-interactive)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# Set Zsh as default shell
chsh -s $(which zsh)

# SSH and RDP
echo -e "${YELLOW}Setting up SSH and RDP...${NC}"
sudo apt install -y \
    openssh-server \
    openssh-client \
    remmina \
    remmina-plugin-rdp \
    xrdp

# Enable SSH
sudo systemctl enable ssh
sudo systemctl start ssh

# OBS Studio
echo -e "${YELLOW}Installing OBS Studio...${NC}"
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt update
sudo apt install -y obs-studio

# Blender
echo -e "${YELLOW}Installing Blender...${NC}"
sudo apt install -y blender

# yt-dlp
echo -e "${YELLOW}Installing yt-dlp...${NC}"
sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
sudo chmod a+rx /usr/local/bin/yt-dlp

# Deezer (via Flatpak)
echo -e "${YELLOW}Installing Deezer...${NC}"
flatpak install flathub dev.aunetx.deezer -y

# KeyViz (build from source)
echo -e "${YELLOW}Building KeyViz...${NC}"
cd /tmp
git clone https://github.com/mulaRahul/keyviz.git
cd keyviz
cargo build --release 2>/dev/null || {
    # Install Rust if not present
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    cargo build --release
}
sudo cp target/release/keyviz /usr/local/bin/
cd ~

# Vencord (Discord with modifications)
echo -e "${YELLOW}Installing Vencord...${NC}"
# First install Discord
wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
sudo dpkg -i discord.deb || sudo apt-get install -f -y
rm discord.deb

# Install Vencord Installer
cd /tmp
git clone https://github.com/Vencord/Installer.git vencord-installer
cd vencord-installer
# Run installer (you'll need to run this manually after script completes)
echo -e "${YELLOW}Note: Run 'cd /tmp/vencord-installer && sudo ./VencordInstallerCli' after script completes${NC}"

# Gemini CLI
echo -e "${YELLOW}Installing Gemini CLI...${NC}"
pip3 install --user gemini-cli

# Corsair mouse support
echo -e "${YELLOW}Installing Corsair device support...${NC}"
sudo apt install -y ckb-next

# Hyprland setup (Note: This is a Wayland compositor, separate from KDE)
echo -e "${YELLOW}Setting up Hyprland (optional Wayland compositor)...${NC}"
# Dependencies for Hyprland
sudo apt install -y \
    meson \
    wayland-protocols \
    libwayland-dev \
    libxkbcommon-dev \
    libpixman-1-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libgtk-3-dev \
    libgles2-mesa-dev \
    libegl1-mesa-dev \
    libgbm-dev \
    libinput-dev \
    libxcb-render-util0-dev \
    libxcb-icccm4-dev \
    libxcb-xfixes0-dev \
    libxcb-composite0-dev \
    libxcb-xinput-dev \
    libxcb-xkb-dev \
    libx11-xcb-dev \
    libseat-dev \
    hwdata

# Clone and setup Hyprconf
echo -e "${YELLOW}Setting up Hyprconf...${NC}"
mkdir -p ~/hyprland-setup
cd ~/hyprland-setup
git clone https://github.com/shell-ninja/hyprconf.git

# Additional multimedia codecs
echo -e "${YELLOW}Installing multimedia codecs...${NC}"
sudo apt install -y \
    ffmpeg \
    libavcodec-extra \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-plugins-good \
    gstreamer1.0-libav

# Performance tweaks
echo -e "${YELLOW}Applying performance tweaks...${NC}"
# Enable gamemode for better gaming performance
sudo usermod -a -G gamemode $USER

# Set up swappiness for better performance
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Enable TRIM for SSDs
sudo systemctl enable fstrim.timer

# Create useful directories
echo -e "${YELLOW}Creating useful directories...${NC}"
mkdir -p ~/Documents/Scripts
mkdir -p ~/Documents/Projects
mkdir -p ~/Games

# Final cleanup
echo -e "${YELLOW}Cleaning up...${NC}"
sudo apt autoremove -y
sudo apt autoclean

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Post-install setup complete!${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "${YELLOW}Please note:${NC}"
echo -e "1. Reboot to ensure all drivers are loaded"
echo -e "2. Run Vencord installer: cd /tmp/vencord-installer && sudo ./VencordInstallerCli"
echo -e "3. Configure Hyprland if you want to use it instead of KDE"
echo -e "4. Log out and back in for Zsh to take effect"
echo -e "5. Configure ckb-next for your Corsair mouse"
echo -e "6. Run 'qpwgraph' to set up audio routing (VoiceMeeter alternative)"
echo -e "${GREEN}===============================================${NC}"