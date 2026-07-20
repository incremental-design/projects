{pkgs, ...}:
pkgs.writeShellApplication {
  name = "install";
  meta = {
    description = ''
      setup a MacOS or NixOS system


      on MacOS:
         ___________
        /           |
       /   incremental-design/projects?dir=infrastructure#install
       |            |
       |            |                 /
       |            |                  |- Applications/ <---------------------------------,
       |            |                  |                                                  |
       |_____,______|                  |- Library/      <---------------------------------|
             |                         |                                                  |
             |                         |- System/                                         |
             |                         |                                                  |
             |                         |- Users/        <---------------------------------|
             |                         |                                                  |
             |                         |- Volumes/                                        |
             |                         |                                                  |
             |                         |- bin/                                            |
             |                         |                                                  |
             |                         |- cores/                                          |
             |                         |                                                  |
             |                         |- dev/                                            |
             |                         |                                                  |
             |                         |- etc/          <---------------------------------|
             |                         |                                                  |
             |                         |- home/                                           |
             |                         |                                                  |
             |                         |- nix/                                            |
             |                         |                                                  |
             |                         |- opt/                                            |
             |                         |                                                  |
             |                         |- private/                                        |
             |                         |                                                  |
             |                         |- sbin/                                           |
             |                         |                                                  |
             |                         |- tmp/                                            |
             |                         |                                                  |
             |                         |- usr/                                            |
             |                         |                                                  |
             |                         |- run/         <----------------------------------|
             |                         |                                                  |
             |                         |- var/                                            |
             |                               |                                            |
             |                               :                                            |
             |                               :                                            |
             |                               |- personalized_factory/                     |
             |                               |                                            |
             |                               |- protected/                                |
             |                               |                                            |
             |                               |- root/                                     |
             |                                   |                                        |
             |                                   |                                        |
             '------------(1)--------------->    '- flake.nix -----------------(2)--------'


      1. initializes a flake.nix with overrides from CLI input into /var/root
      2. runs darwin-rebuild switch to build and apply patches to MacOS system folders

      on NixOS

      nothing yet - not implemented
    '';
  };
  runtimeInputs = [
    pkgs.coreutils
    pkgs.gnused
  ];
  text = ''
    set -e

    if [ "$EUID" -ne 0 ]; then
      echo "run this script with sudo -H" >&2
      exit 1
    fi

    FLAG=""

    LEN_ARGS="$#"
    HOSTNAME=""
    UNINSTALL=""
    HELP=""

    set_flag(){
        if [ -n "$FLAG" ]; then
            echo "$FLAG not followed by argument, got \"$1\"" >&2
            exit 1
        else
            FLAG="$1"
        fi
    }

    set_arg(){
        case "$FLAG" in
            "")
              echo "\"$1\" not preceded by any flag" >&2
              exit 1
            ;;
            "--hostname")
              HOSTNAME="$1";
            ;;
            "--uninstall"|"-u")
              UNINSTALL="$1";
            ;;
            "--help"|"-h")
              HELP="$1";
            ;;
        esac
        FLAG=""
    }

    # we have to use a bare while loop for arg and flag parsing because otherwise $# $@ $1 refers to function args not script args
    while [ "$#" -gt 0 ]; do

      case "$1" in
          "--hostname")
              set_flag "$1"
              shift
          ;;
          "--uninstall"|"-u"|"--help"|"-h")
              # uninstall and help are special because they are flags with no args following them
              set_flag "$1"
              set_arg "$1"
              shift
          ;;
          *)
              set_arg "$1"
              shift
          ;;
      esac
    done

    # uninstall should not be passed with other args
    if [ -n "$UNINSTALL" ] && [ "$LEN_ARGS" -gt 1 ]; then
        echo "cannot pass \"$UNINSTALL\" with other args. run install --help for usage" >&2
        exit 1
    fi

    if [ -n "$HELP" ]; then
    cat >&2 <<EOF
    Usage:
    sudo -H nix run \
    --extra-experimental-features "nix-command flakes" \
    incremental-design/projects?dir=infrastructure#install \
    -- (--uninstall | --hostname <NAME>)
    EOF
      exit 0
    fi

    if [ -z "$HOSTNAME" ] && [ -z "$UNINSTALL" ]; then
        echo "you must set a --hostname" >&2
        exit 1
    fi

    backup_darwin_flake(){
        if ! { rm -f "/var/root/flake.lock" && mv "/var/root/flake.nix" "/var/root/flake.nix.old"; }; then
            return 1
        fi
    }

    backup_darwin_flake_uninstall(){
        if ! backup_darwin_flake; then
            echo "could not back up \"/var/root/flake.nix\" to \"/var/root/flake.nix.old\". Not proceeding with uninstallation" >&2
            EXIT=1
            CMD=""
        else
            CMD="uninstall_macos"
        fi
    }

    nix_darwin_uninstall(){
        if ! nix run nix-darwin#darwin-uninstaller; then
          echo "could not \"nix run nix-darwin#darwin-uninstaller\". Not uninstalling nix-darwin. See https://github.com/nix-darwin/nix-darwin#uninstalling for instructions on how to uninstall manually" >&2
          EXIT=1
          CMD=""
        else
          CMD="backup_darwin_flake_uninstall"
        fi
    }

    uninstall_macos(){
        if ! [ -f "/var/root/flake.nix" ]; then
            echo "uninstall complete" >&2
            CMD=""
        else
            CMD="nix_darwin_uninstall"
        fi
    }


    backup_darwin_flake_install(){
        if ! backup_darwin_flake; then
            echo "could not back up \"/var/root/flake.nix\" to \"/var/root/flake.nix.old\". Not proceeding with installation" >&2
            EXIT=1
            CMD=""
        else
            CMD="install_macos"
        fi
    }

    restore_darwin_flake(){
        if ! mv "/var/root/flake.nix.old" "/var/root/flake.nix"; then
            echo "could not restore \"/var/root/flake.nix.old\" to \"/var/root/flake.nix\"" >&2
            EXIT=1
        else
            echo "restored /var/root/flake.nix" >&2
        fi
        CMD=""
    }

    nix_darwin_switch(){
        if ! nix run \
          --extra-experimental-features "nix-command flakes" \
          nix-darwin/nix-darwin-26.05#darwin-rebuild \
          -- \
          switch \
          --flake "/var/root/.#default" \
          --show-trace
        then
            echo "failed to \"nix run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch\"" >&2
            CMD="restore_darwin_flake"
        fi
        # todo, this terminates with 0 but later we will want to kick things over to home manager
        CMD=""
    }

    init_darwin_flake(){

        local macos_system_arch

        if ! macos_system_arch=$(uname -m); then
            echo "failed to get system architecture with \"uname -m\"" >&2
            EXIT=1
            CMD=""
            return
        fi

        if [ "$macos_system_arch" = "arm64" ]; then
            macos_system_arch='macos_system_arch = "aarch64-darwin";'
        else
            macos_system_arch='macos_system_arch = "x86_64-darwin";'
        fi

        if nix flake init -t "github:incremental-design/projects?ref=make-infrastructure-darwin-install&dir=infrastructure#macos" && \
           sed -i "" "s|macos_system_arch = \"aarch64-darwin\";|''${macos_system_arch}|g" "/var/root/flake.nix" && \
           sed -i "" "s|# networking.hostName|networking.hostName = \"''${HOSTNAME}\";|g" "/var/root/flake.nix";
        then
            CMD="nix_darwin_switch"
        else
            echo "failed to run \"nix flake init -t 'github:incremental-design/projects?dir=infrastructure#macos'\"" >&2
            EXIT=1
            if [ -f "/var/root/flake.nix.old" ]; then
                CMD="restore_darwin_flake"
            else
                CMD=""
            fi
        fi
    }

    install_macos(){
        if ! [ "$HOME" = "/var/root" ]; then
            echo "home directory must be /var/root, try again with sudo -H" >&2
            EXIT=1
            CMD=""
        elif ! [ -f "/var/root/flake.nix" ]; then
            CMD="init_darwin_flake"
        else
            CMD="backup_darwin_flake_install"
        fi
    }

    # uninstall_nixos(){
    #     echo "err not implemented" >&2
    #     EXIT=1
    # }
    # install_nixos(){
    #     echo "err not implemented" >&2
    #     EXIT=1
    # }

    (
      CMD="install_nixos"
      EXIT=0

      if [ "$(uname)" = "Darwin" ] && [ -z "$UNINSTALL" ]; then
      CMD="install_macos"
      elif [ "$(uname)" = "Darwin" ]; then
      CMD="uninstall_macos"
      elif [ -z "$UNINSTALL" ]; then
      CMD="uninstall_nixos"
      fi

      if ! cd /var/root; then
          echo "cannot cd to /var/root, does it exist" >&2
          EXIT=1
          CMD=""
      fi

      while [ -n "$CMD" ]; do
          case "$CMD" in
              "nix_darwin_switch") nix_darwin_switch;;
              "backup_darwin_flake_uninstall") backup_darwin_flake_uninstall;;
              "backup_darwin_flake_install") backup_darwin_flake_install;;
              "restore_darwin_flake") restore_darwin_flake;;
              "init_darwin_flake") init_darwin_flake;;
              "install_macos") install_macos;;
              "nix_darwin_uninstall") nix_darwin_uninstall;;
              "uninstall_macos") uninstall_macos;;
              *) echo "unrecognized command" >&2; exit 1;;
          esac
      done

      exit "$EXIT"
    )
  '';
}
