{pkgs, ...}: "${
(
  import (
    fetchGit {
      url = "https://github.com/NixOS/nixpkgs.git";
      rev = "03335609f036c76f18df379369f92b57973fea73";
    }
  ) {
    system = pkgs.stdenv.hostPlatform.system;
  }
).go_1_27
}"
#
# return go version 1.27.1
