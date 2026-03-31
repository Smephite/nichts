# Repository Structure

Personal NixOS configuration flake.

## `flake.nix`

Entry point. Defines all inputs (nixpkgs, home-manager, agenix, lanzaboote, plasma-manager, etc.) and builds host configurations from `./hosts`.

## `overlay.nix`

Nixpkgs overlays for packages sourced from custom branches/forks (nylon-wg, librepods, claude-desktop).

## `hosts/`

Host definitions. `hosts/default.nix` wires up base modules and defines each `nixosSystem`.

- **`_common/`** — Shared configuration and packages applied to **all** hosts.
- **`_workstations/`** — Configuration and packages shared across workstation/desktop hosts.
- **`_servers/`** — Configuration and packages shared across server hosts.
- **`heartofgold/`**, **`silverwind/`**, **`starhaven/`** — Per-host config, hardware-configuration, and packages. Each host has a `default.nix` that composes its role (`_common`, `_workstations`/`_servers`) with host-specific settings.

## `modules/`

Reusable NixOS/home-manager modules, imported by all hosts via `hosts/default.nix`.

- **`cli/`** — Shell and CLI tool configs (fish, starship, atuin, git, nh).
- **`gui/`** — Graphical application configs (e.g. `browser/firefox`).
- **`system/`** — Core system settings:
  - `desktop/` — Display manager (`dm/`) and window manager (`wm/`), monitor config.
  - `gpu/` — GPU drivers (nvidia).
  - `network/` — Networking, VPN (nylon-wg, openconnect).
  - `udev/` — Udev rules (e.g. microchip).
  - Top-level: fonts, nix settings, TTY, authorized_keys, general system config.
- **`services/`** — System services (pipewire, ssh-notify).
- **`other/`** — Misc modules (home-manager setup, librepods).

## `secrets/`

Agenix-encrypted secrets (`.age` files). `secrets.nix` defines which keys can decrypt which secrets; `public_keys.nix` holds the public keys.

## `wg/`

WireGuard public keys.

## Adding an External Flake as an Overlay

1. **Add the input** in `flake.nix` under `inputs`, pinning nixpkgs:
   ```nix
   my-package = {
     url = "github:owner/repo";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   ```
2. **Register the overlay** in `overlay.nix` — either use the flake's exported overlay directly or define one inline:
   ```nix
   # If the flake exports an overlay:
   add_my_package = inputs.my-package.overlays.default;
   # Otherwise, pull a package manually:
   add_my_package = final: prev: {
     my-package = inputs.my-package.packages.${prev.stdenv.hostPlatform.system}.default;
   };
   ```
   Then append it to the `nixpkgs.overlays` list.
3. **Add the package** to the desired host's `packages.nix` (or `_common`/`_workstations`/`_servers` for broader availability):
   ```nix
   environment.systemPackages = with pkgs; [ my-package ];
   ```
4. **Update the lock file**: `nix flake lock --update-input my-package`.