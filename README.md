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
