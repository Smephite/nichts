# nichts

My personal collection of NixOS configuration files

## TODO

- [ ] remove the options directory and move configuration to a new
      modules/hardware (or something along the lines)

## Project Structure

```
.
├── flake.lock
├── flake.nix
├── hosts
│  ├── common
│  │  ├── configuration.nix
│  │  ├── default.nix
│  │  └── packages.nix
│  ├── default.nix
│  ├── flocke
│  │  ├── configuration.nix
│  │  ├── default.nix
│  │  ├── hardware-configuration.nix
│  │  └── packages.nix
│  ├── iso
│  │  ├── configuration.nix
│  │  ├── default.nix
│  │  ├── hardware-configuration.nix
│  │  ├── hardware-configuration2.nix
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
│  │  ├── vesktop.nix
│  │  ├── vivado.nix
│  │  ├── WM
│  │  │  ├── default.nix
│  │  │  ├── hyprland.nix
│  │  │  ├── i3
│  │  │  │  ├── default.nix
│  │  │  │  ├── i3-new.nix
│  │  │  │  └── polybar.sh
│  │  │  └── waybar.nix
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
│  ├── system
│  │  ├── auto-partition.nix
│  │  ├── bluetooth.nix
│  │  ├── default.nix
│  │  └── nix
│  │     ├── default.nix
│  │     └── nix.nix
│  ├── theming
│  │  ├── base
│  │  │  └── default.nix
│  │  ├── catppuccin
│  │  │  ├── cursor.nix
│  │  │  ├── default.nix
│  │  │  ├── firefox.nix
│  │  │  ├── hyprland.nix
│  │  │  ├── test_waybar_with_theme.sh
│  │  │  ├── waybar.css
│  │  │  └── waybar.nix
│  │  ├── default.nix
│  │  └── options.nix
│  └── tui
│     ├── btop.nix
│     ├── default.nix
│     ├── helix
│     │  ├── default.nix
│     │  ├── helix.nix
│     │  └── languages.nix
│     ├── neovim.nix
│     ├── newsboat.nix
│     └── yazi.nix
├── notes.md
├── options
│  ├── boot
│  │  └── grub-boot.nix
│  ├── common
│  │  ├── gpu
│  │  │  ├── nvidia.nix
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
