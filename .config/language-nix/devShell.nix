{pkgs ? import <nixpkgs> {}}: let
  devShellConfig = {
    packages = [
      # make nix package manager available in the dev env
      pkgs.nix
      # receives a newline-separated list of files to lint
      (pkgs.writeShellApplication
        {
          name = "project-lint";
          meta = {
            description = "lint all .nix files";
          };
          runtimeInputs = with pkgs; [
            alejandra
            gnugrep
            findutils
          ];
          text = ''
            # Filter arguments to only .nix files and pass to alejandra
            printf '%s\0' "$@" | grep -z '\.nix$' | xargs -0 -r alejandra -c
          '';
        })
      (pkgs.writeShellApplication
        {
          name = "project-build";
          meta = {
            description = "build the default package in the project's flake.nix";
          };
          runtimeInputs = with pkgs; [
            coreutils
            fd
            nix
          ];
          text = ''
            # Run nix build and capture output
            if [ ! -f "flake.nix" ]; then
              echo "no flake.nix in ''${PWD}. Nothing to build" >&2
              exit 0
            fi
            if ! nix build; then
              echo "error" >&2
              exit 1
            fi

            # nix build will always output result* symlinks e.g. result/, result-dev/, result-docs/ ...
            # print absolute path to each, split paths by null bytes
            fd --max-depth 1 --type l "result*" -0 --absolute-path
          '';
        })
      # run all checks in the current project's flake
      (pkgs.writeShellApplication
        {
          name = "project-test";
          meta = {
            description = "run all checks in a project's flake.nix";
          };
          runtimeInputs = with pkgs; [
            nix
          ];
          text = ''
            if [ ! -f "flake.nix" ]; then
              echo "no flake.nix ''${PWD}, nothing to flake check" >&2
              exit 0
            fi

            echo "🧪 Running nix flake check..." >&2
            nix flake check
          '';
        })
    ];
    shellHook = '''';
  };
in
  devShellConfig
