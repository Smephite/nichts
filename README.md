# nichts
My personal collection of NixOS configuration files

## TODO
- [ ] remove the options directory and move configuration to a new modules/hardware (or something along the lines)
- [ ] add a proper neovim configuration with nix


## Project Structure 
```
.
├── assets
│  └── wallpaper
│     └── default.png
├── flake.lock
├── flake.nix
├── hosts
│  ├── common
│  │  ├── configuration.nix
│  │  ├── default.nix
│  │  ├── hyprland.nix
│  │  ├── packages.nix
│  │  ├── theming
│  │  │  ├── default.nix
│  │  │  ├── wallpapers
│  │  │  │  └── default.jpg
│  │  │  ├── waybar-style.css
│  │  │  └── waybar-style.css.bak
│  │  └── waybar.nix
│  ├── default.nix
│  ├── flocke
│  │  ├── configuration.nix
│  │  ├── default.nix
│  │  ├── hardware-configuration.nix
│  │  └── packages.nix
│  └── schnee
│     ├── configuration.nix
│     ├── default.nix
│     ├── hardware-configuration.nix
│     └── packages.nix
├── LICENSE
├── modules
│  ├── cli
│  │  ├── atuin.nix
│  │  ├── default.nix
│  │  ├── fish.nix
│  │  ├── git.nix
│  │  ├── neovim.nix
│  │  ├── nh.nix
│  │  ├── ranger.nix
│  │  ├── starship.nix
│  │  ├── zellij.nix
│  │  └── zsh.nix
│  ├── default.nix
│  ├── gui
│  │  ├── alacritty.nix
│  │  ├── cursor.nix
│  │  ├── default.nix
│  │  ├── firefox.nix
│  │  ├── foot.nix
│  │  ├── greetd.nix
│  │  ├── gtk.nix
│  │  ├── kitty.nix
│  │  ├── librewolf.nix
│  │  ├── minecraft.nix
│  │  ├── mpv.nix
│  │  ├── obs.nix
│  │  ├── protonvpn.nix
│  │  ├── qt.nix
│  │  ├── rofi.nix
│  │  ├── schizofox.nix
│  │  ├── steam.nix
│  │  ├── stylix.nix
│  │  ├── vesktop.nix
│  │  ├── vivado.nix
│  │  ├── WM
│  │  │  ├── default.nix
│  │  │  ├── hyprland.nix
│  │  │  └── i3
│  │  │     ├── default.nix
│  │  │     ├── i3-new.nix
│  │  │     └── polybar.sh
│  │  └── zathura.nix
│  ├── other
│  │  ├── default.nix
│  │  ├── displaymanager.nix
│  │  ├── home-manager.nix
│  │  ├── system.nix
│  │  └── xdg.nix
│  ├── services
│  │  ├── default.nix
│  │  ├── firewall.nix
│  │  ├── pipewire.nix
│  │  ├── satpaper.nix
│  │  └── ssh.nix
│  └── tui
│     ├── btop.nix
│     ├── default.nix
│     ├── neovim.nix
│     ├── newsboat.nix
│     └── yazi.nix
├── notes.md
├── options
│  ├── boot
│  │  └── grub-boot.nix
│  ├── common
│  │  ├── bluetooth.nix
│  │  ├── gpu
│  │  │  ├── nvidia.nix
│  │  │  ├── nvidia_535_wayland.nix
│  │  │  └── nvidia_wayland.nix
│  │  ├── networking.nix
│  │  ├── pin-registry.nix
│  │  └── preserve-system.nix
│  └── desktop
│     ├── fonts.nix
│     └── monitors.nix
├── overlay.nix
└── README.md
```


