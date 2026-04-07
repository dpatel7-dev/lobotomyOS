#!/bin/bash
set -e
export MKSQUASHFS_OPTIONS="-no-progress"
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
    --system live \
    --iso-application "LobotomyOS" \
    --iso-publisher "LobotomyOS" \
    --iso-volume "LobotomyOS" \
    --memtest none \
    --linux-flavours "generic" \
    --bootappend-live "boot=casper quiet splash" \
    --parent-mirror-bootstrap "http://archive.ubuntu.com/ubuntu" \
    --parent-mirror-chroot "http://archive.ubuntu.com/ubuntu" \
    --parent-mirror-chroot-security "http://archive.ubuntu.com/ubuntu" \
    --parent-mirror-binary "http://archive.ubuntu.com/ubuntu" \
    --parent-mirror-binary-security "http://archive.ubuntu.com/ubuntu" \
    --mirror-bootstrap "http://archive.ubuntu.com/ubuntu" \
    --mirror-chroot "http://archive.ubuntu.com/ubuntu" \
    --mirror-chroot-security "http://archive.ubuntu.com/ubuntu" \
    --mirror-binary "http://archive.ubuntu.com/ubuntu" \
    --mirror-binary-security "http://archive.ubuntu.com/ubuntu" \
    --bootloaders "grub-efi" \
    --binary-filesystem fat32 \
    --initsystem systemd \
    --apt-recommends false

# Force GRUB-EFI only — skip syslinux (avoids missing theme packages)
sed -i 's/LB_BOOTLOADERS=.*/LB_BOOTLOADERS="grub-efi"/' config/binary 2>/dev/null || true
echo 'LB_BOOTLOADERS="grub-efi"' >> config/binary

step "Step 4/7: Setting up package lists"

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
lb build --verbose 2>&1 | while IFS= read -r line; do
    echo -e "  ${CYAN}▸${NC} $line"
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
