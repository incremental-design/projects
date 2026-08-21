{...}: {
  programs.zed-editor = {
    enable = true;
    package = null; # don't install the zed editor for user, just patch config file
    userSettings = {
      buffer_font_family = "Lilex Nerd Font Propo";
      terminal.font_family = "Lilex Nerd Font Propo";
    };
  };
}
