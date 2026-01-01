{pkgs ? import <nixpkgs> {}}: {
  zedSettings = {
    "auto_install_extensions" = {
      "Nix" = true;
    };
    "languages" = {
      "Nix" = {
        "language_servers" = [
          "nixd"
          "!nil"
        ];
        "formatter" = {
          "external" = {
            "command" = "${pkgs.alejandra}/bin/alejandra";
            "arguments" = [
              "--quiet"
              "--"
            ];
          };
        };
      };
    };
    "lsp" = {
      "nixd" = {
        # see: https://zed.dev/docs/configuring-languages
        "binary" = {
          "ignore_system_version" = false;
          "path" = "${pkgs.nixd}/bin/nixd";
        };
      };
    };
  };
  zedDebug = {}; # there are no debuggers for nix
}
