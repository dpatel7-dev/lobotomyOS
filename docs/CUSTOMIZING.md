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
