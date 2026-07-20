# infrastructure

This flake contains all of the templates and helper scripts used to provision MacOS systems at incremental.design

<!--
    Todo: 
    - templates to provision NixOS systems
    - templates to stand up k0s on NixOS
-->

## How to use infrastructure:

### Installation:

1. Install [nix](https://determinate.systems/nix/)

2. `sudo -H nix run "github:incremental-design/projects?dir=infrastructure#install" --extra-experimental-features "nix-command flakes" -- --hostname <hostname>` where
  * `<hostname>` is the [hostname of your system](https://nix-darwin.github.io/nix-darwin/manual/#opt-networking.hostName) 

3. Reboot your computer.

#### Uninstallation

1. `nix run "github:incremental-design/projects?dir=infrastructure#install" --extra-experimental-features "nix-command flakes" -- --uninstall`

2. Reboot your computer.

### Modules

See [flake.nix -> description](./flake.nix)

## How Infrastructure works

See [install.nix](install.nix)
