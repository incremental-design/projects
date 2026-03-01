{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellApplication {
  name = "nix";
  meta = {
    description = "Use the existing nix version on the build system, if it is >=2.33.1 and <=3.0.0, else error. does not pull nix from nixpkgs, because nix relies on a system-specific daemon";
  };
  text = ''
    # THIS script is included in $PATH. we have to remove it, so that it doesn't invoke itself
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    PATH="''${PATH//$SCRIPT_DIR:/}"

    compare(){
        if (( $1 < $2 )); then
            echo "-1"
            return 0
        elif (( $1 > $2 )); then
            echo "1"
            return 0
        else
            echo "0"
            return 0
        fi
    }

    compare_semver(){
        IFS='.'

        read -ra left <<< "$1"
        read -ra right <<< "$2"

        local i
        local cmp
        for (( i=0; i<3; i++ )); do
            cmp=$(compare "''${left[$i]}" "''${right[$i]}")
            if (( cmp != 0)); then
                echo "$cmp"
                return 0
            fi
        done
        echo "0"
        return 0
    }

    if ! type nix > /dev/null 2>&1; then
        echo "nix not installed. Please install it from https://determinate.systems/nix/" >&2
    fi

    VERSION=$(nix --version)
    if ! [[ "$VERSION" =~ ^.*([0-9]+\.[0-9]+\.[0-9]+$) ]]; then
        echo "nix does not have a valid semver. Expected <MAJOR>.<MINOR>.<PATCH> >= 2.33.1 and < 3.0.0, received \"$VERSION\"" >&2
        exit 1
    fi
    VERSION="''${BASH_REMATCH[-1]}"

    if (( $(compare_semver "$VERSION" "2.33.1") < 0 || $(compare_semver "$VERSION" "3.0.0") > -1 )); then
        echo "expected nix version >= 2.33.1 and < 3.0.0, received \"$VERSION\"" >&2
        exit 1
    fi

    nix "$@"
  '';
}
#
# intercept calls to nix, and return the correct nix binary for nix >=2.33.1 <3.0.0
#
# unlike most tool-*<name>_v<version>.nix files, this file just validates the version of
# whatever nix is installed on the build system.

