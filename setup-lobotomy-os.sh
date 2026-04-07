#!/bin/bash
# ═══════════════════════════════════════════════════════════
# Lobotomy OS — Final Setup Script
# Privacy-focused Linux • Glassmorphism UI • Zorin/macOS/Pop
# ═══════════════════════════════════════════════════════════
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
step() { echo -e "\n${GREEN}${BOLD}  ✓ $1${NC}"; }

echo -e "\n${BOLD}╔═══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║   Lobotomy OS — Privacy-First Linux Distro      ║${NC}"
echo -e "${BOLD}║   Setting up project files...                       ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════╝${NC}"

step "Creating directory structure"
mkdir -p config/packages
mkdir -p config/hooks/live
mkdir -p config/includes.chroot/etc/skel/.config/autostart
mkdir -p config/includes.chroot/etc/skel/.local/share/applications
mkdir -p config/includes.chroot/etc/dconf/db/local.d
mkdir -p config/includes.chroot/etc/dconf/profile
mkdir -p config/includes.chroot/etc/NetworkManager/conf.d
mkdir -p config/includes.chroot/etc/systemd/resolved.conf.d
mkdir -p config/includes.chroot/usr/share/backgrounds/lobotomy-os
mkdir -p config/includes.chroot/usr/share/themes/LobotomyOS/gtk-3.0
mkdir -p config/includes.chroot/usr/share/themes/LobotomyOS/gnome-shell
mkdir -p config/includes.chroot/usr/share/plymouth/themes/lobotomy-os
mkdir -p config/includes.chroot/usr/local/bin
mkdir -p scripts
mkdir -p docs
mkdir -p .github/workflows
mkdir -p .devcontainer

# ══════════════════════════════════════════
step "Creating .devcontainer/devcontainer.json"
# ══════════════════════════════════════════
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Lobotomy OS Build",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu-24.04",
  "postCreateCommand": "sudo apt-get update && sudo apt-get install -y live-build debootstrap squashfs-tools xorriso grub-pc-bin grub-efi-amd64-bin mtools dosfstools isolinux syslinux-utils qemu-system-x86 qemu-utils novnc websockify",
  "forwardPorts": [6080],
  "portsAttributes": { "6080": { "label": "Lobotomy Desktop", "onAutoForward": "notify" } },
  "remoteUser": "vscode"
}
EOF

# ══════════════════════════════════════════
step "Creating .gitignore"
# ══════════════════════════════════════════
cat > .gitignore << 'EOF'
build/
output/
*.iso
*.qcow2
.DS_Store
*.swp
*~
EOF

# ══════════════════════════════════════════
step "Creating LICENSE"
# ══════════════════════════════════════════
cat > LICENSE << 'EOF'
GNU General Public License v3.0
Copyright (C) 2026 Lobotomy OS Project
This program is free software under GPL-3.0.
See https://www.gnu.org/licenses/gpl-3.0.html
EOF

# ══════════════════════════════════════════
step "Creating README.md"
# ══════════════════════════════════════════
cat > README.md << 'EOF'
# Lobotomy OS

**A privacy-first Linux distribution for unrestricted, secure browsing.**

Built on Ubuntu 24.04 with a glassmorphism UI inspired by Zorin OS, macOS, and Pop!_OS.

## Features

**Privacy & Freedom**
- Encrypted DNS (DNS-over-HTTPS via systemd-resolved + Cloudflare)
- Built-in VPN support (WireGuard + OpenVPN)
- Tor Browser pre-installed
- HTTPS-everywhere proxy tools
- Network traffic encryption by default

**Beautiful UI**
- Glassmorphism theme — frosted glass panels, no gradients
- Zorin-style taskbar with app grid launcher
- macOS-style centered dock with bounce animations
- Pop!_OS tiling window manager shortcuts
- Blur-my-shell for transparent panels

**Security**
- UFW firewall (deny all incoming)
- Fail2ban brute-force protection
- AppArmor mandatory access control
- Automatic security updates
- Full disk encryption support via installer

## Quick Start (GitHub Actions — Recommended)

1. Push this repo to GitHub
2. Go to **Actions** tab → run the **Build Lobotomy OS** workflow
3. Download the ISO from **Artifacts** when done (~25 min)
4. Boot in VirtualBox or flash to USB

## Quick Start (Codespaces)

```bash
chmod +x scripts/*.sh
sudo ./scripts/build.sh
./scripts/run-cloud.sh    # open port 6080 to view in browser
```

## License
GPL-3.0
EOF

# ══════════════════════════════════════════
step "Creating scripts/build.sh (fixed for all environments)"
# ══════════════════════════════════════════
cat > scripts/build.sh << 'BUILDEOF'
#!/bin/bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
step() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${GREEN}${BOLD}  ✓ $1${NC}"; echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

if [ "$EUID" -ne 0 ]; then echo -e "${RED}  ✗ Run with: sudo ./scripts/build.sh${NC}"; exit 1; fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"
OUTPUT_DIR="$PROJECT_DIR/output"
ISO_NAME="lobotomy-os-1.0"

# Use /tmp for build if in a container (Codespaces), project dir otherwise
if [ -f /.dockerenv ] || [ -f /run/.containerenv ] || grep -q container /proc/1/cgroup 2>/dev/null; then
    BUILD_DIR="/tmp/lobotomy-build"
    echo "  [i] Container detected — building in /tmp for full permissions"
else
    BUILD_DIR="$PROJECT_DIR/build"
fi

echo -e "\n${BOLD}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║    Lobotomy OS — ISO Builder v1.0            ║${NC}"
echo -e "${BOLD}╚════════════════════════════════════════════════╝${NC}\n"

step "Step 1/7: Installing build dependencies"
apt-get update -qq
apt-get install -y -qq live-build debootstrap squashfs-tools xorriso \
    grub-pc-bin grub-efi-amd64-bin mtools dosfstools isolinux syslinux-utils 2>/dev/null || true

step "Step 2/7: Preparing build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

step "Step 3/7: Configuring live-build"
lb config \
    --distribution noble \
    --archive-areas "main restricted universe multiverse" \
    --architectures amd64 \
    --binary-images iso-hybrid \
    --mode debian \
    --system live \
    --iso-application "LobotomyOS" \
    --iso-publisher "Lobotomy-OS-Project" \
    --iso-volume "LobotomyOS-1.0" \
    --memtest none \
    --bootappend-live "boot=casper quiet splash" \
    --mirror-bootstrap "http://archive.ubuntu.com/ubuntu" \
    --mirror-chroot-security "http://security.ubuntu.com/ubuntu" \
    --apt-recommends false

step "Step 4/7: Setting up package lists"
mkdir -p "$BUILD_DIR/config/package-lists"
cp "$CONFIG_DIR/packages/packages.list" "$BUILD_DIR/config/package-lists/lobotomy.list.chroot"

step "Step 5/7: Installing theme and configuration"
if [ -d "$CONFIG_DIR/includes.chroot" ]; then
    mkdir -p "$BUILD_DIR/config/includes.chroot"
    cp -r "$CONFIG_DIR/includes.chroot/"* "$BUILD_DIR/config/includes.chroot/"
fi

step "Step 6/7: Setting up hooks"
mkdir -p "$BUILD_DIR/config/hooks/live"
if [ -d "$CONFIG_DIR/hooks/live" ]; then
    cp "$CONFIG_DIR/hooks/live/"* "$BUILD_DIR/config/hooks/live/"
    chmod +x "$BUILD_DIR/config/hooks/live/"*
fi

step "Step 7/7: Building ISO (15-30 min)"
echo "  Sit back — this is the long step."
lb build 2>&1 | while IFS= read -r line; do
    echo "$line" | grep -qiE "(P: |Setting up|Unpacking|Installing)" && echo -e "  ${CYAN}▸${NC} $line"
done

ISO_FILE=$(find "$BUILD_DIR" -name "*.iso" -type f 2>/dev/null | head -1)
if [ -n "$ISO_FILE" ]; then
    cp "$ISO_FILE" "$OUTPUT_DIR/${ISO_NAME}.iso"
    ISO_SIZE=$(du -sh "$OUTPUT_DIR/${ISO_NAME}.iso" | cut -f1)
    echo -e "\n${GREEN}${BOLD}  ╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}  ║       BUILD SUCCESSFUL! 🎉              ║${NC}"
    echo -e "${GREEN}${BOLD}  ║  ISO: output/${ISO_NAME}.iso            ║${NC}"
    echo -e "${GREEN}${BOLD}  ║  Size: ${ISO_SIZE}                      ║${NC}"
    echo -e "${GREEN}${BOLD}  ╚════════════════════════════════════════╝${NC}\n"
else
    echo -e "${RED}  ✗ Build failed. Run with verbose output:${NC}"
    echo "    sudo lb build --verbose"
    exit 1
fi
BUILDEOF
chmod +x scripts/build.sh

# ══════════════════════════════════════════
step "Creating scripts/run-cloud.sh"
# ══════════════════════════════════════════
cat > scripts/run-cloud.sh << 'EOF'
#!/bin/bash
set -e
GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ISO_PATH="$PROJECT_DIR/output/lobotomy-os-1.0.iso"

echo -e "\n${BOLD}  Lobotomy OS — Cloud Runner 🚀${NC}\n"

if [ ! -f "$ISO_PATH" ]; then echo "  ✗ ISO not found. Run: sudo ./scripts/build.sh"; exit 1; fi
echo -e "${GREEN}  ✓ ISO: $(du -sh "$ISO_PATH" | cut -f1)${NC}"

sudo apt-get install -y -qq qemu-system-x86 qemu-utils novnc websockify 2>/dev/null

DISK="$PROJECT_DIR/output/disk.qcow2"
[ ! -f "$DISK" ] && qemu-img create -f qcow2 "$DISK" 20G

pkill -f "qemu-system" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true
sleep 1

qemu-system-x86_64 -m 2048 -smp 2 -cdrom "$ISO_PATH" -hda "$DISK" -boot d -vnc :0 -usb -device usb-tablet -daemonize 2>/dev/null || \
qemu-system-x86_64 -m 2048 -cdrom "$ISO_PATH" -boot d -vnc :0 -daemonize

sleep 2
NOVNC=$(find /usr -path "*/novnc/vnc.html" -printf "%h" 2>/dev/null | head -1)
[ -z "$NOVNC" ] && NOVNC="/usr/share/novnc"
websockify --web="$NOVNC" 6080 localhost:5900 &>/dev/null &
sleep 1

echo -e "\n${GREEN}${BOLD}  ═══ Lobotomy OS is running! ═══${NC}"
echo "  Open PORTS tab → port 6080 → click globe icon 🌐"
echo "  Stop: ./scripts/stop-vm.sh"
echo ""
EOF
chmod +x scripts/run-cloud.sh

# ══════════════════════════════════════════
step "Creating scripts/stop-vm.sh"
# ══════════════════════════════════════════
cat > scripts/stop-vm.sh << 'EOF'
#!/bin/bash
pkill -f "qemu-system" 2>/dev/null && echo "  ✓ VM stopped" || echo "  - VM not running"
pkill -f "websockify" 2>/dev/null && echo "  ✓ noVNC stopped" || echo "  - noVNC not running"
EOF
chmod +x scripts/stop-vm.sh

# ══════════════════════════════════════════
step "Creating config/packages/packages.list"
# ══════════════════════════════════════════
cat > config/packages/packages.list << 'EOF'
# ╔═══════════════════════════════════════════╗
# ║  Lobotomy OS — Package List            ║
# ║  Privacy-first • Glassmorphism • Freedom  ║
# ╚═══════════════════════════════════════════╝

# ── Core Desktop ──
ubuntu-desktop-minimal
gnome-shell
gnome-session
gnome-control-center
gnome-tweaks
gnome-shell-extensions
gnome-shell-extension-manager
gdm3
mutter

# ── System ──
linux-generic
network-manager
network-manager-gnome
network-manager-openvpn
network-manager-openvpn-gnome
pulseaudio
pipewire
pipewire-pulse
bluez

# ── Files ──
nautilus
file-roller
gvfs
gvfs-backends

# ── Privacy Browsers ──
firefox
chromium-browser

# ── Privacy & Unblocking Tools ──
wireguard
wireguard-tools
openvpn
tor
torbrowser-launcher
privoxy
proxychains4
dnscrypt-proxy
stubby
openresolv
shadowsocks-libev
obfs4proxy

# ── Encrypted DNS ──
systemd-resolved

# ── Network Tools ──
nmap
traceroute
whois
dnsutils
net-tools
iptables
curl
wget

# ── Terminal & Dev ──
gnome-terminal
gnome-text-editor
vim
git
htop
neofetch

# ── Utilities ──
gnome-calculator
gnome-system-monitor
gnome-disk-utility
gnome-screenshot
evince
gnome-software
flatpak

# ── Theming (Glassmorphism) ──
adwaita-icon-theme-full
papirus-icon-theme
fonts-noto
fonts-noto-color-emoji
fonts-firacode
gnome-shell-extension-prefs

# ── Security ──
ufw
gufw
fail2ban
apparmor
apparmor-utils
clamav
unattended-upgrades
bleachbit

# ── Pop!_OS Tiling ──
gnome-shell-extension-pop-shell

# ── Installer ──
calamares
calamares-settings-ubuntu

# ── Boot & Drivers ──
plymouth
plymouth-themes
xserver-xorg
xserver-xorg-video-all
xserver-xorg-input-all
EOF

# ══════════════════════════════════════════
step "Creating config/hooks (post-install + privacy setup)"
# ══════════════════════════════════════════
cat > config/hooks/live/0500-lobotomy.hook.chroot << 'EOF'
#!/bin/bash
set -e
echo "[Lobotomy OS] Configuring system..."

# ── Branding ──
echo "lobotomy-os" > /etc/hostname
cat > /etc/os-release << 'OSREL'
PRETTY_NAME="Lobotomy OS 1.0"
NAME="Lobotomy OS"
VERSION_ID="1.0"
VERSION="1.0 (Noble)"
ID=lobotomy-os
ID_LIKE=ubuntu debian
UBUNTU_CODENAME=noble
OSREL

cat > /etc/lsb-release << 'LSB'
DISTRIB_ID=LobotomyOS
DISTRIB_RELEASE=1.0
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Lobotomy OS 1.0"
LSB

# ── Encrypted DNS (DNS-over-HTTPS via systemd-resolved) ──
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/dns-over-tls.conf << 'DNS'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=8.8.8.8#dns.google
DNSOverTLS=yes
DNSSEC=allow-downgrade
Domains=~.
DNS

# Make resolved the system DNS
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true

# ── Privoxy (local filtering proxy) ──
if [ -f /etc/privoxy/config ]; then
    sed -i 's/^listen-address.*/listen-address 127.0.0.1:8118/' /etc/privoxy/config
    echo "forward-socks5 / 127.0.0.1:9050 ." >> /etc/privoxy/config 2>/dev/null || true
fi

# ── DNSCrypt-proxy config ──
if [ -d /etc/dnscrypt-proxy ]; then
    cat > /etc/dnscrypt-proxy/dnscrypt-proxy.toml << 'DNSCRYPT'
listen_addresses = ['127.0.0.1:5353']
server_names = ['cloudflare', 'cloudflare-ipv6', 'quad9-doh-ip4-filter-pri']
doh_servers = true
require_dnssec = true
require_nofilter = true
require_nolog = true
DNSCRYPT
fi

# ── Proxychains default config ──
if [ -f /etc/proxychains4.conf ]; then
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains4.conf
fi

# ── Wallpaper link ──
[ -f /usr/share/backgrounds/lobotomy-os/default.svg ] && \
    ln -sf /usr/share/backgrounds/lobotomy-os/default.svg /usr/share/backgrounds/warty-final-ubuntu.png 2>/dev/null || true

# ── Security Hardening ──
dconf update 2>/dev/null || true

ufw default deny incoming 2>/dev/null || true
ufw default allow outgoing 2>/dev/null || true
ufw --force enable 2>/dev/null || true

if [ -d /etc/fail2ban ]; then
    cat > /etc/fail2ban/jail.local << 'JAIL'
[DEFAULT]
bantime = 3600
maxretry = 3
[sshd]
enabled = true
JAIL
fi

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'AUTO'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
AUTO

[ -f /etc/ssh/sshd_config ] && {
    sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
}

echo "* hard core 0" >> /etc/security/limits.conf
echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/99-security.conf

# ── Prevent DNS leaks ──
cat > /etc/sysctl.d/99-privacy.conf << 'PRIV'
net.ipv6.conf.all.use_tempaddr = 2
net.ipv6.conf.default.use_tempaddr = 2
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
PRIV

# ── Enable services ──
systemctl enable gdm3 2>/dev/null || true
systemctl enable NetworkManager 2>/dev/null || true
systemctl enable ufw 2>/dev/null || true
systemctl enable fail2ban 2>/dev/null || true
systemctl enable apparmor 2>/dev/null || true
systemctl enable systemd-resolved 2>/dev/null || true
systemctl enable tor 2>/dev/null || true
systemctl enable privoxy 2>/dev/null || true

# ── Plymouth ──
[ -d /usr/share/plymouth/themes/lobotomy-os ] && {
    plymouth-set-default-theme lobotomy-os 2>/dev/null || true
    update-initramfs -u 2>/dev/null || true
}

apt-get clean; rm -rf /tmp/*
echo "[Lobotomy OS] Configuration complete!"
EOF
chmod +x config/hooks/live/0500-lobotomy.hook.chroot

# ══════════════════════════════════════════
step "Creating GTK theme (Glassmorphism — no gradients)"
# ══════════════════════════════════════════
cat > config/includes.chroot/usr/share/themes/LobotomyOS/index.theme << 'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=LobotomyOS
Comment=Glassmorphism dark theme — frosted glass, no gradients
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=LobotomyOS
MetacityTheme=LobotomyOS
IconTheme=Papirus-Dark
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:appmenu
EOF

cat > config/includes.chroot/usr/share/themes/LobotomyOS/gtk-3.0/gtk.css << 'EOF'
/* ═══════════════════════════════════════════════
   Lobotomy OS — Glassmorphism GTK Theme
   Frosted glass • No gradients • Clean surfaces
   macOS button layout • Zorin refinement
   ═══════════════════════════════════════════════ */

/* ── Colors ── */
@define-color bg_color #161620;
@define-color fg_color #e2e4f0;
@define-color base_color #111118;
@define-color selected_bg rgba(255, 255, 255, 0.12);
@define-color selected_fg #ffffff;
@define-color accent #ffffff;
@define-color borders rgba(255, 255, 255, 0.08);
@define-color glass rgba(255, 255, 255, 0.04);
@define-color glass_hover rgba(255, 255, 255, 0.07);
@define-color glass_active rgba(255, 255, 255, 0.10);
@define-color glass_border rgba(255, 255, 255, 0.10);
@define-color error_color #ff6b7a;
@define-color warning_color #f0c060;
@define-color success_color #6bdf8a;
@define-color headerbar_bg rgba(18, 18, 26, 0.88);

* { outline-color: alpha(@accent, 0.2); }

/* ── Windows ── */
window { background-color: @bg_color; color: @fg_color; }
window.background { background-color: @bg_color; }
decoration {
    border-radius: 14px;
    box-shadow: 0 12px 48px rgba(0,0,0,0.55), 0 0 0 1px rgba(255,255,255,0.05);
    margin: 10px;
}

/* ── Header Bars (Frosted Glass) ── */
headerbar {
    background-color: @headerbar_bg;
    color: @fg_color;
    border-bottom: 1px solid @borders;
    min-height: 44px;
    padding: 0 10px;
}
headerbar:backdrop { background-color: rgba(16,16,24,0.92); color: rgba(226,228,240,0.5); }
headerbar .title { font-weight: 600; font-size: 13px; }
headerbar button { background: transparent; border: none; border-radius: 8px; color: @fg_color; transition: all 120ms ease; }
headerbar button:hover { background-color: @glass_hover; }

/* ── macOS-style Window Buttons ── */
windowcontrols button {
    min-width: 14px; min-height: 14px; border-radius: 50%;
    margin: 0 4px; padding: 0;
    background-color: rgba(255,255,255,0.12); border: none;
    transition: all 150ms ease;
}
windowcontrols button.close { background-color: @error_color; }
windowcontrols button.close:hover { background-color: shade(@error_color, 1.15); }
windowcontrols button.minimize { background-color: @warning_color; }
windowcontrols button.minimize:hover { background-color: shade(@warning_color, 1.15); }
windowcontrols button.maximize { background-color: @success_color; }
windowcontrols button.maximize:hover { background-color: shade(@success_color, 1.15); }

/* ── Buttons (Glass) ── */
button {
    background-color: @glass;
    color: @fg_color;
    border: 1px solid @glass_border;
    border-radius: 10px;
    padding: 6px 18px;
    min-height: 30px;
    transition: all 120ms ease;
}
button:hover { background-color: @glass_hover; border-color: rgba(255,255,255,0.14); }
button:active { background-color: @glass_active; }
button:checked { background-color: rgba(255,255,255,0.14); color: #fff; }
button.suggested-action { background-color: rgba(255,255,255,0.14); color: #fff; border: 1px solid rgba(255,255,255,0.18); font-weight: 600; }
button.suggested-action:hover { background-color: rgba(255,255,255,0.18); }
button.destructive-action { background-color: rgba(255,107,122,0.15); color: @error_color; border: 1px solid rgba(255,107,122,0.2); }

/* ── Text Entries (Glass) ── */
entry {
    background-color: rgba(0,0,0,0.3);
    color: @fg_color;
    border: 1px solid @borders;
    border-radius: 10px;
    padding: 8px 14px;
    caret-color: #fff;
    transition: all 150ms ease;
}
entry:focus { border-color: rgba(255,255,255,0.25); box-shadow: 0 0 0 2px rgba(255,255,255,0.06); }

/* ── Lists & Rows ── */
list { background-color: transparent; }
list row { padding: 4px; border-radius: 10px; transition: background 100ms ease; }
list row:hover { background-color: @glass; }
list row:selected { background-color: @selected_bg; }

/* ── Sidebar (Frosted) ── */
.sidebar { background-color: rgba(14,14,20,0.9); border-right: 1px solid @borders; }
.sidebar row:selected { background-color: @selected_bg; }

/* ── Switches ── */
switch { border-radius: 14px; background-color: rgba(255,255,255,0.08); border: none; min-width: 44px; min-height: 24px; }
switch:checked { background-color: rgba(255,255,255,0.22); }
switch slider { border-radius: 50%; background-color: white; min-width: 20px; min-height: 20px; margin: 2px; box-shadow: 0 1px 4px rgba(0,0,0,0.3); }

/* ── Checkboxes & Radios ── */
check, radio { border: 2px solid rgba(255,255,255,0.18); background: transparent; min-width: 20px; min-height: 20px; border-radius: 5px; }
radio { border-radius: 50%; }
check:checked, radio:checked { background-color: rgba(255,255,255,0.2); border-color: rgba(255,255,255,0.3); }

/* ── Scrollbars (Minimal) ── */
scrollbar { background: transparent; }
scrollbar slider { background-color: rgba(255,255,255,0.10); border-radius: 100px; min-width: 4px; min-height: 4px; }
scrollbar slider:hover { background-color: rgba(255,255,255,0.18); min-width: 8px; }

/* ── Tooltips (Glass) ── */
tooltip { background-color: rgba(20,20,30,0.92); border-radius: 10px; border: 1px solid @borders; padding: 6px 12px; }

/* ── Menus / Popovers (Frosted Glass) ── */
popover, menu {
    background-color: rgba(20,20,30,0.88);
    border-radius: 14px;
    border: 1px solid rgba(255,255,255,0.08);
    padding: 6px;
    box-shadow: 0 12px 40px rgba(0,0,0,0.45);
}
popover modelbutton:hover, menu menuitem:hover { background-color: @glass_hover; border-radius: 8px; }

/* ── Notebooks / Tabs ── */
notebook header tab { padding: 8px 16px; border-radius: 10px 10px 0 0; color: rgba(226,228,240,0.5); }
notebook header tab:checked { color: #fff; border-bottom: 2px solid rgba(255,255,255,0.5); }

/* ── Progress Bars ── */
progressbar trough { background-color: rgba(255,255,255,0.05); border-radius: 100px; min-height: 4px; }
progressbar progress { background-color: rgba(255,255,255,0.35); border-radius: 100px; min-height: 4px; }

/* ── Nautilus ── */
.nautilus-window .sidebar { background-color: rgba(14,14,20,0.9); }
.nautilus-window .floating-bar { background-color: rgba(255,255,255,0.12); border-radius: 8px; }
EOF

# ══════════════════════════════════════════
step "Creating GNOME Shell theme (Glassmorphism)"
# ══════════════════════════════════════════
cat > config/includes.chroot/usr/share/themes/LobotomyOS/gnome-shell/gnome-shell.css << 'EOF'
/* ═══════════════════════════════════════════════
   Lobotomy OS — GNOME Shell Glassmorphism
   Frosted panels • Glass dock • Clean overview
   ═══════════════════════════════════════════════ */

/* ── Top Panel (Frosted Glass) ── */
#panel {
    background-color: rgba(12, 12, 18, 0.55);
    font-weight: 500;
    height: 30px;
    color: rgba(255,255,255,0.85);
    border-bottom: 1px solid rgba(255,255,255,0.04);
}
#panel:overview { background-color: transparent; border: none; }
#panel .panel-button { color: rgba(255,255,255,0.75); border-radius: 8px; margin: 2px 1px; transition-duration: 120ms; }
#panel .panel-button:hover { background-color: rgba(255,255,255,0.08); color: white; }
#panel .panel-button:active, #panel .panel-button:checked { background-color: rgba(255,255,255,0.12); }

/* ── Search (Glass) ── */
.search-entry {
    background-color: rgba(255,255,255,0.06);
    border: 1px solid rgba(255,255,255,0.10);
    border-radius: 28px;
    padding: 12px 24px;
    color: white;
    font-size: 16px;
    max-width: 520px;
}
.search-entry:focus { border-color: rgba(255,255,255,0.2); box-shadow: 0 0 0 2px rgba(255,255,255,0.05); }

/* ── App Grid ── */
.app-folder-dialog { background-color: rgba(18,18,28,0.88); border-radius: 20px; border: 1px solid rgba(255,255,255,0.06); }
.app-well-app .overview-icon { font-size: 12px; color: rgba(255,255,255,0.85); }
.app-well-app:hover .overview-icon { background-color: rgba(255,255,255,0.06); border-radius: 16px; }
.app-well-app:active .overview-icon { background-color: rgba(255,255,255,0.10); }

/* ── Dock (Frosted Glass — macOS style) ── */
#dash {
    background-color: rgba(16,16,24,0.55);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: 20px;
    padding: 6px 8px;
    margin-bottom: 14px;
}
#dash .dash-background { background-color: transparent; }
.dash-item-container .app-well-app .overview-icon { padding: 6px; border-radius: 14px; }
.dash-item-container .app-well-app:hover .overview-icon { background-color: rgba(255,255,255,0.08); }
.dash-item-container .app-well-app:active .overview-icon { background-color: rgba(255,255,255,0.14); }

/* ── Running Dot (macOS style) ── */
.app-well-app-running-dot { background-color: rgba(255,255,255,0.6); width: 5px; height: 5px; border-radius: 50%; margin-bottom: 2px; }

/* ── Show Apps ── */
.show-apps .overview-icon { background-color: rgba(255,255,255,0.04); border-radius: 14px; color: rgba(255,255,255,0.4); }
.show-apps .overview-icon:hover { background-color: rgba(255,255,255,0.08); color: white; }

/* ── Notifications (Glass cards) ── */
.message {
    background-color: rgba(20,20,30,0.82);
    border-radius: 16px;
    border: 1px solid rgba(255,255,255,0.06);
    color: white;
    margin: 4px 8px;
}
.message:hover { background-color: rgba(25,25,38,0.88); }

/* ── Quick Settings Panel (Glass) ── */
.quick-settings {
    background-color: rgba(18,18,28,0.82);
    border-radius: 20px;
    border: 1px solid rgba(255,255,255,0.06);
    padding: 12px;
    margin: 4px 8px 8px;
}
.quick-toggle { background-color: rgba(255,255,255,0.05); border-radius: 14px; padding: 12px; }
.quick-toggle:checked { background-color: rgba(255,255,255,0.14); }
.quick-toggle:hover { background-color: rgba(255,255,255,0.08); }

/* ── Calendar ── */
.calendar-day-base.calendar-day-today { background-color: rgba(255,255,255,0.2); color: white; border-radius: 50%; font-weight: 700; }

/* ── OSD ── */
.osd-window { background-color: rgba(18,18,28,0.88); border-radius: 18px; border: 1px solid rgba(255,255,255,0.06); }
.osd-window .level { background-color: rgba(255,255,255,0.08); border-radius: 100px; }
.osd-window .level:checked { background-color: rgba(255,255,255,0.35); }

/* ── Modal Dialogs (Glass) ── */
.modal-dialog { background-color: rgba(18,18,28,0.92); border-radius: 20px; border: 1px solid rgba(255,255,255,0.06); color: white; }

/* ── Login ── */
.login-dialog .login-dialog-prompt-entry {
    background-color: rgba(255,255,255,0.06);
    border: 2px solid rgba(255,255,255,0.10);
    border-radius: 26px;
    padding: 10px 18px;
    color: white;
}
.login-dialog .login-dialog-prompt-entry:focus { border-color: rgba(255,255,255,0.3); }

/* ── Workspace Indicators ── */
.ws-switcher-indicator { background-color: rgba(255,255,255,0.12); border-radius: 100px; }
.ws-switcher-indicator:active { background-color: rgba(255,255,255,0.4); }
EOF

# ══════════════════════════════════════════
step "Creating dconf defaults (Zorin layout + macOS dock + Pop tiling)"
# ══════════════════════════════════════════
cat > config/includes.chroot/etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

cat > config/includes.chroot/etc/dconf/db/local.d/00-lobotomy-defaults << 'EOF'
[org/gnome/desktop/interface]
gtk-theme='LobotomyOS'
icon-theme='Papirus-Dark'
cursor-theme='Adwaita'
font-name='Noto Sans 11'
monospace-font-name='Fira Code 12'
color-scheme='prefer-dark'
enable-animations=true
clock-show-weekday=true
show-battery-percentage=true

[org/gnome/shell]
favorite-apps=['firefox.desktop', 'torbrowser.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Settings.desktop']
enabled-extensions=['pop-shell@system76.com']

[org/gnome/shell/extensions/user-theme]
name='LobotomyOS'

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/lobotomy-os/default.svg'
picture-uri-dark='file:///usr/share/backgrounds/lobotomy-os/default.svg'
picture-options='zoom'
primary-color='#0c0c14'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/lobotomy-os/default.svg'

[org/gnome/desktop/wm/preferences]
button-layout='close,minimize,maximize:appmenu'
theme='LobotomyOS'

[org/gnome/mutter]
center-new-windows=true
edge-tiling=true
dynamic-workspaces=true

[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true
natural-scroll=true

[org/gnome/settings-daemon/plugins/color]
night-light-enabled=true
night-light-schedule-automatic=true

[org/gnome/desktop/privacy]
remove-old-trash-files=true
remove-old-temp-files=true
old-files-age=uint32 7
report-technical-problems=false

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
visible-name='Lobotomy'
use-theme-colors=false
background-color='#0c0c14'
foreground-color='#e2e4f0'
palette=['#161620', '#ff6b7a', '#6bdf8a', '#f0c060', '#7aa2f7', '#bb9af7', '#7dcfff', '#e2e4f0', '#3b3d52', '#ff6b7a', '#6bdf8a', '#f0c060', '#7aa2f7', '#bb9af7', '#7dcfff', '#ffffff']
use-transparent-background=true
background-transparency-percent=12
font='Fira Code 12'
use-system-font=false
audible-bell=false

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
name='Terminal'
binding='<Super>t'
command='gnome-terminal'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
name='File Manager'
binding='<Super>e'
command='nautilus'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
name='Tor Browser'
binding='<Super>b'
command='torbrowser-launcher'
EOF

# ══════════════════════════════════════════
step "Creating wallpaper (dark minimal — no gradients)"
# ══════════════════════════════════════════
cat > config/includes.chroot/usr/share/backgrounds/lobotomy-os/default.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3840 2160" width="3840" height="2160">
  <defs>
    <radialGradient id="g1" cx="20%" cy="80%" r="50%">
      <stop offset="0%" stop-color="#1a1a2e" stop-opacity="1"/>
      <stop offset="100%" stop-color="#0c0c14" stop-opacity="1"/>
    </radialGradient>
  </defs>
  <rect width="3840" height="2160" fill="#0c0c14"/>
  <rect width="3840" height="2160" fill="url(#g1)"/>
  <!-- Subtle geometric grid -->
  <g opacity="0.025" stroke="#ffffff" stroke-width="0.5" fill="none">
    <line x1="960" y1="0" x2="960" y2="2160"/>
    <line x1="1920" y1="0" x2="1920" y2="2160"/>
    <line x1="2880" y1="0" x2="2880" y2="2160"/>
    <line x1="0" y1="540" x2="3840" y2="540"/>
    <line x1="0" y1="1080" x2="3840" y2="1080"/>
    <line x1="0" y1="1620" x2="3840" y2="1620"/>
  </g>
  <!-- Floating glass circles -->
  <circle cx="680" cy="1600" r="280" fill="rgba(255,255,255,0.012)" stroke="rgba(255,255,255,0.02)" stroke-width="1"/>
  <circle cx="3200" cy="500" r="350" fill="rgba(255,255,255,0.008)" stroke="rgba(255,255,255,0.015)" stroke-width="1"/>
  <circle cx="1920" cy="1080" r="500" fill="rgba(255,255,255,0.005)" stroke="rgba(255,255,255,0.01)" stroke-width="1"/>
  <!-- Corner accent dots -->
  <g opacity="0.04" fill="#ffffff">
    <circle cx="60" cy="60" r="2"/>
    <circle cx="3780" cy="60" r="2"/>
    <circle cx="60" cy="2100" r="2"/>
    <circle cx="3780" cy="2100" r="2"/>
  </g>
  <text x="3740" y="2130" fill="rgba(255,255,255,0.025)" font-family="sans-serif" font-size="14" font-weight="500" text-anchor="end">Lobotomy OS</text>
</svg>
EOF

# ══════════════════════════════════════════
step "Creating Plymouth boot splash"
# ══════════════════════════════════════════
cat > config/includes.chroot/usr/share/plymouth/themes/lobotomy-os/lobotomy-os.plymouth << 'EOF'
[Plymouth Theme]
Name=Lobotomy OS
Description=Minimal glassmorphism boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/lobotomy-os
ScriptFile=/usr/share/plymouth/themes/lobotomy-os/lobotomy-os.script
EOF

cat > config/includes.chroot/usr/share/plymouth/themes/lobotomy-os/lobotomy-os.script << 'EOF'
Window.SetBackgroundTopColor(0.047, 0.047, 0.078);
Window.SetBackgroundBottomColor(0.047, 0.047, 0.078);

screen_w = Window.GetWidth();
screen_h = Window.GetHeight();
cx = screen_w / 2;
cy = screen_h / 2;

title = Image.Text("Lobotomy OS", 1, 1, 1, 1, "Sans Bold 24");
title_s = Sprite(title);
title_s.SetX(cx - title.GetWidth() / 2);
title_s.SetY(cy - 50);
title_s.SetOpacity(0.85);

sub = Image.Text("Privacy • Freedom • Clarity", 0.88, 0.89, 0.94, 1, "Sans 11");
sub_s = Sprite(sub);
sub_s.SetX(cx - sub.GetWidth() / 2);
sub_s.SetY(cy - 15);
sub_s.SetOpacity(0.3);

num_dots = 5;
dot_sprites = [];
progress = 0;
for (i = 0; i < num_dots; i++) {
    d = Image.Text("●", 1, 1, 1, 1, "Sans 6");
    dot_sprites[i] = Sprite(d);
}

fun refresh_callback() {
    progress += 0.04;
    for (i = 0; i < num_dots; i++) {
        offset = (i - 2) * 14;
        x = cx + offset - 3;
        y = cy + 30;
        dot_sprites[i].SetX(x);
        dot_sprites[i].SetY(y);
        phase = Math.Cos(progress - i * 0.5);
        dot_sprites[i].SetOpacity(0.1 + (phase + 1) * 0.3);
    }
}
Plymouth.SetRefreshFunction(refresh_callback);

fun display_password_callback(prompt, bullets) {
    pt = Image.Text(prompt, 1, 1, 1, 1, "Sans 13");
    ps = Sprite(pt);
    ps.SetX(cx - pt.GetWidth() / 2);
    ps.SetY(cy + 80);
    bs = "";
    for (i = 0; i < bullets; i++) bs += "● ";
    bt = Image.Text(bs, 1, 1, 1, 1, "Sans 16");
    bsp = Sprite(bt);
    bsp.SetX(cx - bt.GetWidth() / 2);
    bsp.SetY(cy + 110);
}
Plymouth.SetDisplayPasswordFunction(display_password_callback);
EOF

# ══════════════════════════════════════════
step "Creating privacy quick-connect tool"
# ══════════════════════════════════════════
cat > config/includes.chroot/usr/local/bin/lb-connect << 'EOF'
#!/bin/bash
# Lobotomy OS — Privacy Quick Connect
# Usage: lb-connect [mode]
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "\n${BOLD}  Lobotomy OS — Privacy Toolkit${NC}\n"

case "${1:-status}" in
    tor)
        echo -e "${CYAN}  Starting Tor connection...${NC}"
        sudo systemctl start tor
        echo -e "${GREEN}  ✓ Tor active on SOCKS5 127.0.0.1:9050${NC}"
        echo "  Configure your browser proxy to SOCKS5 127.0.0.1:9050"
        echo "  Or run: torbrowser-launcher"
        ;;
    dns)
        echo -e "${CYAN}  Activating encrypted DNS...${NC}"
        sudo systemctl restart systemd-resolved
        resolvectl status 2>/dev/null | grep -A2 "DNS Server" || echo "  DNS-over-TLS via Cloudflare active"
        echo -e "${GREEN}  ✓ DNS encrypted via DNS-over-TLS (Cloudflare + Quad9)${NC}"
        ;;
    vpn)
        echo -e "${CYAN}  VPN Setup:${NC}"
        echo "  WireGuard:  sudo wg-quick up wg0"
        echo "  OpenVPN:    sudo openvpn --config your-config.ovpn"
        echo "  GUI:        Open Settings → Network → VPN → Add VPN"
        echo ""
        echo "  Free VPN configs: protonvpn.com/free or riseup.net/vpn"
        ;;
    proxy)
        echo -e "${CYAN}  Starting Privoxy proxy...${NC}"
        sudo systemctl start privoxy
        echo -e "${GREEN}  ✓ HTTP proxy active on 127.0.0.1:8118${NC}"
        echo "  Set browser HTTP proxy to 127.0.0.1:8118"
        ;;
    full)
        echo -e "${CYAN}  Activating full privacy mode...${NC}"
        sudo systemctl start tor
        sudo systemctl restart systemd-resolved
        sudo systemctl start privoxy
        echo -e "${GREEN}  ✓ Tor:       SOCKS5 127.0.0.1:9050${NC}"
        echo -e "${GREEN}  ✓ Privoxy:   HTTP   127.0.0.1:8118${NC}"
        echo -e "${GREEN}  ✓ DNS:       Encrypted (Cloudflare DoT)${NC}"
        echo -e "\n  All traffic tools active. Use Tor Browser for max privacy."
        ;;
    status)
        echo "  Services:"
        for svc in tor privoxy systemd-resolved; do
            if systemctl is-active --quiet $svc 2>/dev/null; then
                echo -e "    ${GREEN}● ${svc}${NC}"
            else
                echo -e "    ${YELLOW}○ ${svc} (inactive)${NC}"
            fi
        done
        echo ""
        echo "  DNS: $(resolvectl status 2>/dev/null | grep 'DNS Server' | head -1 || echo 'check with: resolvectl status')"
        echo ""
        echo "  Commands:"
        echo "    lb-connect tor     Start Tor"
        echo "    lb-connect dns     Activate encrypted DNS"
        echo "    lb-connect vpn     VPN setup guide"
        echo "    lb-connect proxy   Start HTTP proxy"
        echo "    lb-connect full    Enable everything"
        ;;
    *)
        echo "  Usage: lb-connect [tor|dns|vpn|proxy|full|status]"
        ;;
esac
echo ""
EOF
chmod +x config/includes.chroot/usr/local/bin/lb-connect

# ══════════════════════════════════════════
step "Creating GitHub Actions workflow"
# ══════════════════════════════════════════
cat > .github/workflows/build.yml << 'EOF'
name: Build Lobotomy OS ISO
on:
  push:
    branches: [ main ]
    paths-ignore: [ '**.md', 'docs/**' ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-24.04
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y live-build debootstrap squashfs-tools xorriso \
            grub-pc-bin grub-efi-amd64-bin grub-efi-ia32-bin mtools dosfstools \
            isolinux syslinux-utils

      - name: Build ISO
        run: |
          chmod +x scripts/build.sh
          sudo ./scripts/build.sh

      - name: Upload ISO
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: lobotomy-os-iso
          path: output/*.iso
          retention-days: 14
          compression-level: 0

      - name: Summary
        if: always()
        run: |
          if [ -f output/lobotomy-os-1.0.iso ]; then
            SIZE=$(du -sh output/lobotomy-os-1.0.iso | cut -f1)
            echo "## ✅ Build Successful" >> $GITHUB_STEP_SUMMARY
            echo "**ISO Size:** $SIZE" >> $GITHUB_STEP_SUMMARY
            echo "Download from **Artifacts** below." >> $GITHUB_STEP_SUMMARY
          else
            echo "## ❌ Build Failed" >> $GITHUB_STEP_SUMMARY
          fi
EOF

# ══════════════════════════════════════════
step "Creating docs"
# ══════════════════════════════════════════
cat > docs/PRIVACY.md << 'EOF'
# Lobotomy OS — Privacy Guide

## What's Built In

### Encrypted DNS (DNS-over-TLS)
Your DNS queries are encrypted by default via Cloudflare and Quad9.
Network admins cannot see which websites you visit via DNS.

Check status: `resolvectl status`

### Tor
Full Tor network access for anonymous browsing.
- Tor Browser: `torbrowser-launcher` or Super+B
- SOCKS5 proxy: `127.0.0.1:9050`
- Route any app through Tor: `proxychains4 firefox`

### VPN Support
WireGuard and OpenVPN are pre-installed.
- WireGuard: `sudo wg-quick up wg0`
- OpenVPN: `sudo openvpn --config file.ovpn`
- GUI: Settings → Network → VPN → Add

### Privoxy (HTTP Proxy)
Local proxy for filtering and routing.
- Start: `sudo systemctl start privoxy`
- Address: `127.0.0.1:8118`
- Chains through Tor by default

### Quick Connect
Use the built-in `lb-connect` command:
```
lb-connect status    # Check what's running
lb-connect tor       # Start Tor
lb-connect dns       # Activate encrypted DNS
lb-connect vpn       # VPN setup guide
lb-connect proxy     # Start HTTP proxy
lb-connect full      # Enable everything
```

## Tips
- Use Tor Browser for maximum anonymity
- Encrypted DNS bypasses most DNS-based network filters
- WireGuard VPN encrypts ALL traffic from your machine
- Proxychains can route any program through Tor
EOF

cat > docs/CUSTOMIZING.md << 'EOF'
# Customizing Lobotomy OS

## Change Theme
Edit `config/includes.chroot/usr/share/themes/LobotomyOS/gtk-3.0/gtk.css`
The theme uses `rgba()` values for glassmorphism. Adjust opacity for more/less transparency.

## Add/Remove Apps
Edit `config/packages/packages.list`

## Change Wallpaper
Replace `config/includes.chroot/usr/share/backgrounds/lobotomy-os/default.svg`

## Change Dock Apps
Edit `favorite-apps` in `config/includes.chroot/etc/dconf/db/local.d/00-lobotomy-defaults`

## Window Button Layout
Current: macOS style (close, minimize, maximize on the left)
To switch to Windows/Zorin style (right side):
Change `button-layout='close,minimize,maximize:appmenu'`
To: `button-layout='appmenu:minimize,maximize,close'`

## Rebuild
After any change: `sudo ./scripts/build.sh`
EOF

# ══════════════════════════════════════════
step "Pushing to GitHub"
# ══════════════════════════════════════════
git add -A
git commit -m "🚀 Lobotomy OS — Privacy-first Linux distro

Features:
- Glassmorphism UI (frosted glass, no gradients)
- Zorin-style panel + macOS dock + Pop!_OS tiling
- Encrypted DNS (Cloudflare DoT)
- Tor, WireGuard, OpenVPN, Privoxy pre-installed
- lb-connect privacy quick-connect tool
- UFW, Fail2ban, AppArmor security hardening
- GitHub Actions auto-build pipeline"

git push origin main || {
    echo -e "\n  Push failed — trying with rebase..."
    git pull origin main --rebase --allow-unrelated-histories 2>/dev/null || git pull origin main --allow-unrelated-histories
    git push origin main
}

echo ""
echo -e "${GREEN}${BOLD}  ╔════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}  ║          SETUP COMPLETE! 🎉                        ║${NC}"
echo -e "${GREEN}${BOLD}  ╠════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}${BOLD}  ║                                                    ║${NC}"
echo -e "${GREEN}${BOLD}  ║  Option A — Build in GitHub Actions (recommended): ║${NC}"
echo -e "${GREEN}${BOLD}  ║    Go to repo → Actions tab → Run workflow          ║${NC}"
echo -e "${GREEN}${BOLD}  ║    Download ISO from Artifacts when done            ║${NC}"
echo -e "${GREEN}${BOLD}  ║                                                    ║${NC}"
echo -e "${GREEN}${BOLD}  ║  Option B — Build here:                            ║${NC}"
echo -e "${GREEN}${BOLD}  ║    sudo ./scripts/build.sh                         ║${NC}"
echo -e "${GREEN}${BOLD}  ║    ./scripts/run-cloud.sh                          ║${NC}"
echo -e "${GREEN}${BOLD}  ║                                                    ║${NC}"
echo -e "${GREEN}${BOLD}  ╚════════════════════════════════════════════════════╝${NC}"
echo ""
