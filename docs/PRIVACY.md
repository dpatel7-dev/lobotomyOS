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
