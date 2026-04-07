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
