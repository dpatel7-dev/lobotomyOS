#!/bin/bash
pkill -f "qemu-system" 2>/dev/null && echo "  ✓ VM stopped" || echo "  - VM not running"
pkill -f "websockify" 2>/dev/null && echo "  ✓ noVNC stopped" || echo "  - noVNC not running"
