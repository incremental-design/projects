{pkgs ? import <nixpkgs> {}, ...}: let
  lintCommit = import ./lintCommit.nix {inherit pkgs;};
  commitMsg = "${lintCommit}/bin/lintCommit";
  prePush = "${(import ./recurse.nix {
    inherit pkgs;
    steps = ["lint" "lintSemVer" "build" "runTest"];
    ignoreUnchanged = true;
    cleanup = true;
  })}/bin/recurse";

  # Create the installer script
  installGitHooks = pkgs.writeShellApplication {
    name = "installGitHooks";
    meta = {
      description = "Install commit-msg and pre-push hooks in this project. Automatically run when this shell is opened";
    };

    # No need for runtime inputs here as we're just creating a symlink
    text = ''
      # Check if .git/hooks exists
      if [ ! -d .git/hooks ]; then
        echo "❌ .git/hooks directory not found. Are you in a git repository?" >&2
        exit 1
      fi

      # Create symlink to the hook script

      ln -sf ${commitMsg} .git/hooks/commit-msg
      ln -sf ${prePush} .git/hooks/pre-push

      echo "✅ Git commit-msg and pre-push hook installed successfully" >&2
    '';
  };
in
  installGitHooks
