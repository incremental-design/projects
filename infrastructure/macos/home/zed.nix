{
  config,
  pkgs,
  lib,
  ...
}: let
  nuPkg = if config.programs.nushell.package != null then config.programs.nushell.package else pkgs.nushell;
in {
  programs.zed-editor = {
    enable = true;
    package = null; # don't install the zed editor for user, just patch config file
    userSettings = {
      buffer_font_family = "Lilex Nerd Font Propo";
      terminal.font_family = "Lilex Nerd Font Propo";
      terminal.shell.with_arguments = {
        program = lib.getExe nuPkg;
        args = ["--login"];
      };
    };
  };
}
