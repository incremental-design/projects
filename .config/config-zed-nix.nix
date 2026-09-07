{pkgs ? import <nixpkgs> {}}: {
  zedSettings = {
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
          "ignore_system_version" = true;
          "path" = "${pkgs.nixd}/bin/nixd";
        };
      };
    };
  };
  zedDebug = {}; # there are no debuggers for nix
}
