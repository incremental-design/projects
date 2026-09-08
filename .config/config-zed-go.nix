{pkgs ? import <nixpkgs> {}}: {
  zedSettings = {
    "auto_install_extensions" = {
      "Go" = true;
    };
    "languages" = {
      "Go" = {
        "enable_language_server" = true;
        "formatter" = {
          "external" = {
            "command" = "${pkgs.golangci-lint}/bin/golangci-lint";
            "arguments" = [
              "run"
              "--fix"
            ];
          };
        };
        "semantic_tokens" = "combined";
      };
    };
    "lsp" = {
      "gopls" = {
        "binary" = {
          "ignore_system_version" = true;
          "path" = "${pkgs.gopls}/bin/gopls";
        };
        "initialization_options" = {
          "codelenses" = {
            "test" = true;
            "generate" = true;
            "regenerate_cgo" = true;
            "tidy" = true;
            "upgrade_dependency" = true;
            "vendor" = true;
          };
        };
      };
    };
  };
  zedDebug = {}; # there are no debuggers for nix
}
