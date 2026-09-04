{
  pkgs,
  config,
  lib,
  ...
}: {
  programs.nushell = let
    system = pkgs.system;
    pinnedPkgs =
      # nushell plugin and nu diverged after v0.110.0 and have not reconverged in nixpkgs yet
      import (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/2b7b8f66a80a608eacbb2a0be75a867eb67c41a1.tar.gz";
        sha256 = "sha256-2hBzLOt/Bust4S94PIB0l5ybhhpUgkcbjfR6xPoIu+o=";
      }) {inherit system;};
  in {
    enable = true;
    home.file."${config.programs.nushell.configDir}/autoload/cd_interactive.nu" = ''
      $env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship" "nushell.toml")

      def cd_interactive --env --wrapped [...rest: string ] {
        if $nu.is-interactive {
          # this works because ./shells.nix/homeManager.zoxide.enableNushellIntegration calls cd under the hood
          __zoxide_z ...$rest
        } else if ( ( $rest | length ) == 0 ) {
          cd ~
        } else {
          cd $rest.0
        }
      }

      alias cd = cd_interactive
    '';
    settings = {
      hooks = {
        pre_prompt = lib.hm.nushell.mkNushellInline ''
          [
            {
              mut pre = if ((which git | length) == 1) {
                  try {
                  git rev-parse --show-toplevel e> /dev/null;
                  } catch {
                  ""
                  }
              }

              if ($pre == "") {
                  $pre = $env.PWD
              }

              mut post = ""

              echo $pre
              echo $post

              if ($env.PWD | str starts-with $pre) {
                  $post = $env.PWD | str substring ($pre | str length)..
              } else {
                  $pre = $env.PWD
              }

              if ($pre | str starts-with /) {
                  $pre = $pre | str substring (1)..
              }
              if ($post | str starts-with /) {
                  $post = $post | str substring (1)..
              }

              let pre_seg = $pre | split row /
              let post_seg = $post | split row /

              $env.STARSHIP_CWD_PRE_0 = try {
                  $pre_seg.0
              } catch {""}
              $env.STARSHIP_CWD_PRE_1 = try {
                  $pre_seg.1
              } catch {""}
              $env.STARSHIP_CWD_PRE_2 = try {
                  if (($pre_seg | length) > 4) {
                  "󰇘"
                  } else {
                  $pre_seg.2
                  }
              } catch {""}
              $env.STARSHIP_CWD_PRE_3 = try {
                  if (($pre_seg | length) > 4) {
                  $pre_seg | get (($pre_seg | length) - 1)
                  } else {
                  $pre_seg.3
                  }
              } catch {""}

              $env.STARSHIP_CWD_POST_0 = try {
                  $post_seg.0
              } catch {""}

              $env.STARSHIP_CWD_POST_1 = try {
                  if (($post_seg | length) > 4) {
                      "󰇘"
                  } else {
                      $post_seg.1
                  }
              } catch {""}

              $env.STARSHIP_CWD_POST_2 = try {
                  if (($post_seg | length) > 4) {
                      $post_seg | get (($post_seg | length) - 2)
                  } else {
                      $post_seg.2
                  }
              } catch {""}

              $env.STARSHIP_CWD_POST_3 = try {
                  if (($post_seg | length) > 4) {
                      $post_seg | get (($post_seg | length) - 1)
                  } else {
                      $post_seg.3
                  }
              } catch {""}

              let now = date now | format date "%I/%M/%S/%p/%Z" | split row /

              $env.STARSHIP_HH = if ($now.0 | str starts-with "0") { $now.0 | str substring 1.. } else { $now.0 }
              $env.STARSHIP_HH_0 = if ( ($now.0 | into int) < 10 ) { "0" } else { "" }
              $env.STARSHIP_MM = $now.1
              $env.STARSHIP_SS = $now.2
              $env.STARSHIP_P = $now.3
              $env.STARSHIP_TZ = $now.4
            }
          ]
        '';
      };
    };
    package = let
      # need to pull nushell from earlier nixpkgs to ensure compatibility with plugins as of nix 26.05, but this will
      nushell = pinnedPkgs.nushell;
    in
      nushell;
    plugins = with pinnedPkgs; [
      # nushell-plugin-bson # does not exist at pinned pkgs
      nushell-plugin-formats
      nushell-plugin-gstat
      nushell-plugin-hcl
      nushell-plugin-highlight
      nushell-plugin-polars
      nushell-plugin-query
      nushell-plugin-semver
      nushell-plugin-skim
    ];
  };
}
