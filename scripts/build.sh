#!/bin/bash
set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
step() { echo -e "\n${GREEN}${BOLD}  ✓ $1${NC}"; }

if [ "$EUID" -ne 0 ]; then echo -e "${RED}  ✗ Run with: sudo ./scripts/build.sh${NC}"; exit 1; fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_DIR/config"
OUTPUT_DIR="$PROJECT_DIR/output"
ISO_NAME="lobotomy-os-1.0"

if [ -f /.dockerenv ] || grep -q container /proc/1/cgroup 2>/dev/null; then
    BUILD_DIR="/tmp/lobotomy-build"
else
    BUILD_DIR="$PROJECT_DIR/build"
fi

echo -e "\n${BOLD}  Lobotomy OS — ISO Builder${NC}\n"

step "Step 1: Dependencies"
apt-get update -qq
apt-get install -y -qq live-build debootstrap squashfs-tools xorriso \
    grub-pc-bin grub-efi-amd64-bin mtools dosfstools 2>/dev/null || true

step "Step 2: Clean slate"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"
cd "$BUILD_DIR"

step "Step 3: Configure"
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
    --apt-recommends false

step "Step 4: Patching live-build (remove dead syslinux packages)"
if [ -f config/binary ]; then
    sed -i '/LB_BOOTLOADERS/d' config/binary
fi
echo 'LB_BOOTLOADERS="grub-efi"' >> config/binary

find config/ -type f -name "*.list*" | while read f; do
    sed -i '/syslinux/d' "$f" 2>/dev/null || true
    sed -i '/gfxboot/d' "$f" 2>/dev/null || true
done

LB_SCRIPTS="/usr/lib/live/build"
if [ -d "$LB_SCRIPTS" ]; then
    for script in "$LB_SCRIPTS"/lb_binary_syslinux* "$LB_SCRIPTS"/lb_chroot_syslinux*; do
        [ -f "$script" ] && chmod -x "$script" && echo "  Disabled: $(basename $script)"
    done
fi

mkdir -p config/package-lists
touch config/package-lists/syslinux-override.list.binary

step "Step 5: Package lists"
cp "$CONFIG_DIR/packages/packages.list" config/package-lists/lobotomy.list.chroot

step "Step 6: Theme and config"
if [ -d "$CONFIG_DIR/includes.chroot" ]; then
    mkdir -p config/includes.chroot
    cp -r "$CONFIG_DIR/includes.chroot/"* config/includes.chroot/
fi

step "Step 7: Hooks"
mkdir -p config/hooks/live
if [ -d "$CONFIG_DIR/hooks/live" ]; then
    cp "$CONFIG_DIR/hooks/live/"* config/hooks/live/
    chmod +x config/hooks/live/*
fi

step "Step 8: Building ISO (15-30 min)"
lb build --verbose 2>&1 | tee /tmp/lb-build.log || true

echo ""
echo "========== LAST 80 LINES OF BUILD LOG =========="
tail -80 /tmp/lb-build.log
echo "========== END LOG =========="

ISO_FILE=$(find "$BUILD_DIR" -name "*.iso" -type f 2>/dev/null | head -1)
if [ -n "$ISO_FILE" ]; then
    cp "$ISO_FILE" "$OUTPUT_DIR/${ISO_NAME}.iso"
    SIZE=$(du -sh "$OUTPUT_DIR/${ISO_NAME}.iso" | cut -f1)
    echo -e "\n${GREEN}${BOLD}  BUILD SUCCESSFUL — $SIZE${NC}"
    echo "  ISO: output/${ISO_NAME}.iso"
else
    echo -e "\n${RED}  Build failed. Full error above.${NC}"
    exit 1
fi
