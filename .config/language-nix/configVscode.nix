{pkgs ? import <nixpkgs> {}}: {
  vscodeSettings = {
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
    "nix.serverSettings" = {
      "nixd" = {
        "formatting" = {
          "command" = [
            "${pkgs.alejandra}/bin/alejandra"
          ];
        };
      };
    };
  };
  vscodeExtensions = {
    "recommendations" = [
      "jnoortheen.nix-ide"
    ];
  };
  vscodeLaunch = {};
  vscodeTasks = {};
}
