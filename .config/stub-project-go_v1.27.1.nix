{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellApplication {
  name = "stubProject";
  runtimeInputs = [
    pkgs.coreutils
    pkgs.git
    (import ./tool.nix {inherit pkgs;})
  ];
  text = ''
    PROJECT_DIR="$1"

    if [ -z "$PROJECT_DIR" ]; then
        echo "PROJECT_DIR not passed in as first argument" >&2
        exit 1
    fi

    PROJECT=''${PROJECT_DIR##*/}             # Extract basename using parameter expansion
    PROJECT=''${PROJECT//[^a-zA-Z0-9-]/_}    # Replace invalid chars with underscore

    (cd "$PROJECT_DIR" && tool "go" "1.27.1" mod init "$PROJECT" && go mod tidy)

    tool "go" "1.27.1" work use "$PROJECT_DIR"

    # stage all project files
    git -C "$PROJECT_DIR" add -f .
  '';
}
