{pkgs ? import <nixpkgs> {}, ...}: let
  lintCommit = import ./lintCommit.nix {inherit pkgs;};
  commitMsg = "${lintCommit}/bin/lintCommit";
  prePush = "${(import ./recurse.nix {
    inherit pkgs;
    steps = ["project-lint" "project-lint-semver" "project-build" "project-test"];
    ignoreUnchanged = true;
    cleanup = true;
  })}/bin/recurse";

  # Create the installer script
  project-install-git-hooks = pkgs.writeShellApplication {
    name = "project-install-git-hooks";
    meta = {
      description = "Install commit-msg and pre-push hooks in this project. Automatically run when this shell is opened";
    };

    runtimeInputs = [pkgs.coreutils];
    text = ''
      # Check if .git/hooks exists
      if [ ! -d .git/hooks ]; then
        echo "❌ .git/hooks directory not found. Are you in a git repository?" >&2
        exit 1
      fi

      # Function to install a git hook with intelligent linking
      install_hook() {

        local source="$1"
        local dest="$2"
        local hook_name="$3"

        if [ ! -e "$dest" ]; then
          ln -sf "$source" "$dest"
          echo "✅ linked $hook_name hook" >&2
        else
          CURRENT_DIR=$(readlink -f "$dest")
          if [ "$CURRENT_DIR" = "$source" ]; then
            echo "✅ $hook_name hook already linked" >&2
          elif [ "$(dirname "$CURRENT_DIR")" = "$(dirname "$source")" ]; then
            unlink "$dest"
            ln -sf "$source" "$dest"
            echo "✅ $hook_name hook updated" >&2
          else
            ln -sf "$source" "$dest"
            echo "✅ $hook_name hook replaced" >&2
          fi
        fi

      }

      # Install hooks using the function
      install_hook "${commitMsg}" ".git/hooks/commit-msg" "commit-msg"
      install_hook "${prePush}" ".git/hooks/pre-push" "pre-push"
    '';
  };
in
  project-install-git-hooks
