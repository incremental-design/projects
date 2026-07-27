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

2. Use nix-darwin to configure your system, with `sudo -H nix run "github:incremental-design/projects?dir=infrastructure#install" --extra-experimental-features "nix-command flakes" -- system --hostname <hostname>` where
  - `<hostname>` is the [hostname of your system](https://nix-darwin.github.io/nix-darwin/manual/#opt-networking.hostName) 

3. Reboot your computer.

> [!TIP]
> You can verify the nix-darwin installation by running `sudo`. It should prompt you to use your watch or touch id to 
> You can also run `hostname` to verify that the mac hostname matches the value you supplied to the install script

4. Use home-manager to configure your home directory, with `nix run "github:incremental-design/projects?dir=infrastructure#install" -- extra-experimental-features "nix-command flakes" -- home`

<!--4. Use home-manager to configure your home directory, with `nix run "github:incremental-design/projects?dir=infrastructure#install" -- extra-experimental-features "nix-command flakes" -- home ` where 
  - `<>` is the -->

5. Log out and log back in

> [!TIP]
> Why not include the home manager configuration in the nix darwin configuration?
> 
> If the nix-darwin configuration contains the home manager configuration, then every
> user's settings would live in `/var/root/flake.nix`, which would not be accessible to
> non-sudoer users

#### Uninstallation

2. `nix run "github:incremental-design/projects?dir=infrastructure#install" --extra-experimental-features "nix-command flakes" -- uninstall-home`

3. log out and log back in

3. `sudo -H nix run "github:incremental-design/projects?dir=infrastructure#install" --extra-experimental-features "nix-command flakes" -- uninstall-system`

4. Reboot your computer.

### Modules

See [flake.nix -> description](flake.nix)

## How Infrastructure works

See [install.nix](install.nix)
