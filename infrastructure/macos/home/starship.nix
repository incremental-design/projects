{pkgs, ...}: let
  settings = {
    add_newline = true;
    format = ''($aws )($glcoud )($openstack )($azure )$line_break''${custom.hh_0}''${custom.hh}[:](dimmed fg:bg_green)''${custom.mm}''${custom.p}( $singularity)( $kubernetes)( $docker_context)( $guix_shell)( $nix_shell)( $conda)( $pixi)( $direnv)( $nats) [](fg:fg_green)[ ](fg:fg_indigo bg:fg_green)$shell($shlvl)( $jobs)[](fg:fg_green bg:bg_mint)''${custom.cwd_pre_0}''${custom.cwd_pre_0_sep}''${custom.cwd_pre_0_sep_post}''${custom.cwd_pre_1}''${custom.cwd_pre_1_sep}''${custom.cwd_pre_1_sep_post}''${custom.cwd_pre_2}''${custom.cwd_pre_2_sep}''${custom.cwd_pre_2_sep_post}''${custom.cwd_pre_3}''${custom.cwd_pre_3_sep}''${custom.cwd_pre_terminal}''${custom.cwd_pre_terminal_2}''${custom.cwd_post_0}''${custom.cwd_post_0_sep}''${custom.cwd_post_1}''${custom.cwd_post_1_sep}''${custom.cwd_post_2}''${custom.cwd_post_2_sep}''${custom.cwd_post_3}''${custom.cwd_post_3_sep}''${custom.cwd_post_terminal}( $git_branch $git_commit $git_state)$fill( $buf)( $bun)( $c)( $cpp)( $cmake)( $cobol)( $crystal)( $daml)( $dart)( $deno)( $dotnet)( $erlang)( $elixir)( $elm)( $fennel)( $fortran)( $gleam)( $gradle)( $golang)( $haskell)( $haxe)( $helm)( $java)( $julia)( $kotlin)( $lua)( $maven)( $meson)( $mojo)( $nodejs)( $nim)( $ocaml)( $odin)( $opa)( $perl)( $php)( $purescript)( $python)( $raku)( $quarto)( $red)( $rlang)( $ruby)( $rust)( $scala)( $solidity)( $spack)( $swift)( $terraform)( $typst)( $xmake)( $vagrant)( $vlang)( $zig)'';
    palette = "theme";
    palettes = {
      theme = {
        bg_ice_2 = "#7CAFFB";
        bg_ice = "#D2F1FF";
        bg_mint_2 = "#22A69A";
        bg_mint = "#84E2F3";
        fg_indigo = "#161C4D";
        fg_green = "#22A69A";
        bg_green = "#085F57";
        fg_red = "#E585A5";
        bg_red = "#5E0422";
        bg_purple = "#381F90";
        fg_purple = "#9E9AE9";
        bg_blue = "#1D4B9A";
        fg_blue = "#7CAFFB";
        bg_yellow_green = "#235607";
        fg_yellow_green = "#90EE8E";
        bg_yellow = "#514D43";
        fg_yellow = "#F9E975";
      };
    };
    # credentials
    aws = {
      symbol = " ";
      format = "[](fg:fg_yellow)[$symbol](dimmed fg:bg_yellow bg:fg_yellow)[ $region $duration](fg:bg_yellow bg:fg_yellow)[](fg:fg_yellow)";
    };
    gcloud = {
      symbol = "󱇶 ";
      format = "[](fg:fg_blue)[$symbol](dimmed fg:bg_blue bg:fg_blue)[ $region $account $domain](fg:bg_blue bg:fg_blue)[](fg:fg_blue)";
    };
    openstack = {
      symbol = " ";
      format = "[](fg:fg_red)[$symbol](dimmed fg:bg_red bg:fg_red)[ $cloud $project](fg:bg_red bg:fg_red)[](fg:fg_red)";
    };
    azure = {
      symbol = " ";
      format = "[](fg:fg_blue)[$symbol](dimmed fg:bg_blue bg:fg_blue)[$subscription](fg:bg_blue bg:fg_blue)[](fg:fg_blue)";
      disabled = false;
    };

    # environments
    shlvl = {
      threshold = 2;
      format = "[ $symbol](fg:fg_indigo bg:fg_green)[$shlvl ](fg:fg_indigo bg:fg_green)";
      symbol = "󰌨 ";
      disabled = false;
    };
    shell = {
      disabled = false;
      bash_indicator = "BASH";
      zsh_indicator = "ZSH";
      nu_indicator = "NU";
      format = "[$indicator](fg:fg_indigo bg:fg_green)";
    };
    jobs = {
      symbol = " ";
      format = "[ $symbol](fg:bg_green bg:fg_green)[$number](fg:fg_indigo bg:fg_green)";
    };
    singularity = {
      symbol = " ";
      format = "[](fg:fg_purple)[$symbol](dimmed fg:bg_purple bg:fg_purple)[$env](fg:bg_purple bg:fg_purple)[](fg:fg_purple)";
    };
    kubernetes = {
      symbol = "󱃾 ";
      format = "[](fg:fg_blue)[$symbol](dimmed fg:bg_blue bg:fg_blue)[$context $namespace](fg:bg_blue bg:fg_blue)[](fg:fg_blue)";
    };
    docker_context = {
      symbol = "󰡨 ";
      format = "[](fg:fg_blue)[$symbol](dimmed fg:bg_blue bg:fg_blue)[$context](fg:bg_blue bg:fg_blue)[](fg:fg_blue)";
    };
    container = {
      symbol = " ";
      format = "[](fg:fg_blue)[$symbol](dimmed fg:bg_blue bg:fg_blue)[$context](fg:bg_blue bg:fg_blue)[](fg:fg_blue)";
    };
    guix_shell = {
      symbol = " ";
      format = "[](fg:fg_yellow)[$symbol](fg:bg_yellow bg:fg_yellow)[](fg:fg_yellow)";
    };
    nix_shell = {
      symbol = "󱄅 ";
      format = "[](fg:fg_purple)[$symbol](dimmed fg:bg_blue bg:fg_purple)[$state $name](fg:bg_blue bg:fg_purple)[](fg:fg_purple)";
    };
    conda = {
      symbol = "󰌠 CONDA";
      format = "[](fg:fg_yellow_green)[$symbol](dimmed fg:bg_yellow_green bg:fg_yellow_green)[$environment](fg:bg_yellow_green bg:fg_yellow_green)[](fg:fg_yellow_green)";
    };
    pixi = {
      symbol = "󰌠 PIXI";
      format = "[](fg:fg_yellow_green)[$symbol](dimmed fg:bg_yellow_green bg:fg_yellow_green)[$version $environment](fg:bg_yellow_green bg:fg_yellow_green)[](fg:fg_yellow_green)";
    };
    nats = {
      symbol = " ";
      format = "[](fg:fg_yellow_green)[$symbol](dimmed fg:bg_blue bg:fg_yellow_green)[$name](fg:bg_blue bg:fg_yellow_green)[](fg:fg_yellow_green)";
    };
    direnv = {
      symbol = " ";
      format = "[](fg:fg_purple)[$symbol](dimmed fg:bg_blue bg:fg_purple)[$loaded $allowed](fg:bg_blue bg:fg_purple)[](fg:fg_purple)";
    };

    # languages
    buf = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    bun = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    c = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    cpp = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    cmake = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    cobol = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    crystal = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    daml = {
      symbol = " ";
      format = "(([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) ))";
    };
    dart = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    deno = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    dotnet = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)( $tfm)](dimmed fg:fg_green) )";
    };
    erlang = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    elixir = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    elm = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    fennel = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    fortran = {
      symbol = "󱈚 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    gleam = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    gradle = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    golang = {
      symbol = "󰟓 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    haskell = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    haxe = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    helm = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    java = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    julia = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    kotlin = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    lua = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    maven = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    meson = {
      symbol = "󰯙 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    mojo = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    nodejs = {
      symbol = "󰎙 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    nim = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    ocaml = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    odin = {
      symbol = "󰬖 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    opa = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    perl = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    php = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    purescript = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    python = {
      symbol = "󰌠 ";
      format = "([$symbol( $pyenv_prefix)](bold fg:bg_green)[($version( $virtualenv))](dimmed fg:fg_green) )";
    };
    raku = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version $vm-version)](dimmed fg:fg_green) )";
    };
    quarto = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    red = {
      symbol = "󱥒 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    rlang = {
      symbol = "󰟔 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    ruby = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    rust = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    scala = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    solidity = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    spack = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    swift = {
      symbol = "󰛥 ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    terraform = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    typst = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    xmake = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    vagrant = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    vlang = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    zig = {
      symbol = " ";
      format = "([$symbol](bold fg:bg_green)[($version)](dimmed fg:fg_green) )";
    };
    fill = {
      symbol = " ";
    };
    git_branch = {
      format = "[$symbol](dimmed fg:bg_green)[$branch](bold fg:fg_green)";
      symbol = "";
    };
    git_commit = {
      format = "[($hash)](bold fg:fg_green)[($tag)](bold fg:fg_green)";
      tag_disabled = false;
      tag_symbol = " ";
    };
    git_state = {
      format = "(fg:bg_green)[$state](dimmed fg:fg_green) [($progress_current/$progress_total)](dimmed fg:fg_green)";
    };
    custom = {
      hh_0 = {
        when = true;
        command = "echo $STARSHIP_HH_0";
        format = "[$output](dimmed fg:bg_green)";
      };
      hh = {
        when = true;
        command = "echo $STARSHIP_HH";
        format = "[$output](fg:fg_green)";
      };
      mm = {
        when = true;
        command = "echo $STARSHIP_MM";
        format = "[$output](fg:fg_green)";
      };
      ss = {
        when = true;
        command = "echo $STARSHIP_SS";
        format = "[$output](dimmed fg:bg_green)";
      };
      p = {
        when = true;
        command = "echo $STARSHIP_P";
        format = "[$output](dimmed fg:bg_green)";
      };
      tz = {
        when = true;
        command = "echo $STARSHIP_TZ";
        format = "[$output](dimmed fg:bg_green)";
      };
      cwd_pre_0 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_PRE_0\"";
        format = "[$output](fg:fg_indigo bg:bg_mint)";
      };
      cwd_pre_0_sep = {
        when = "test -n \"\${STARSHIP_CWD_PRE_0:-}\" && test -n \"\${STARSHIP_CWD_PRE_1:-}\"";
        command = "echo ";
        format = "[$output](bold fg:bg_mint_2 bg:bg_mint)";
      };
      cwd_pre_0_sep_post = {
        when = "test -n \"\${STARSHIP_CWD_PRE_0:-}\" && test -z \"\${STARSHIP_CWD_PRE_1:-}\" && test -n \"\${STARSHIP_CWD_POST_0:-}\"";
        command = "echo ";
        format = "[$output](fg:bg_mint bg:bg_ice)";
      };
      cwd_pre_1 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_PRE_1\"";
        format = "[$output](fg:fg_indigo bg:bg_mint)";
      };
      cwd_pre_1_sep = {
        when = "test -n \"\${STARSHIP_CWD_PRE_1:-}\" && test -n \"\${STARSHIP_CWD_PRE_2:-}\"";
        command = "echo ";
        format = "[$output](bold fg:bg_mint_2 bg:bg_mint)";
      };
      cwd_pre_1_sep_post = {
        when = "test -n \"\${STARSHIP_CWD_PRE_1:-}\" && test -z \"\${STARSHIP_CWD_PRE_2:-}\" && test -n \"\${STARSHIP_CWD_POST_0:-}\"";
        command = "echo ";
        format = "[$output](fg:bg_mint bg:bg_ice)";
      };
      cwd_pre_2 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_PRE_2\"";
        format = "[$output](fg:fg_indigo bg:bg_mint)";
      };
      cwd_pre_2_sep = {
        when = "test -n \"\${STARSHIP_CWD_PRE_2:-}\" && test -n \"\${STARSHIP_CWD_PRE_3:-}\"";
        command = "echo ";
        format = "[$output](bold fg:bg_mint_2 bg:bg_mint)";
      };
      cwd_pre_2_sep_post = {
        when = "test -n \"\${STARSHIP_CWD_PRE_2:-}\" && test -z \"\${STARSHIP_CWD_PRE_3:-}\" && test -n \"\${STARSHIP_CWD_POST_0:-}\"";
        command = "echo ";
        format = "[$output](fg:bg_mint bg:bg_ice)";
      };
      cwd_pre_3 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_PRE_3\"";
        format = "[$output](fg:fg_indigo bg:bg_mint)";
      };
      cwd_pre_3_sep = {
        when = "test -n \"\${STARSHIP_CWD_PRE_3:-}\" && test -n \"\${STARSHIP_CWD_POST_0:-}\"";
        command = "echo ";
        format = "[$output](fg:bg_mint bg:bg_ice)";
      };
      cwd_pre_terminal = {
        when = "test -z \"\${STARSHIP_CWD_POST_0:-}\"";
        command = "echo ";
        format = "[$output](fg:bg_mint)";
      };
      cwd_post_0 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_POST_0\"";
        format = "[$output](fg:fg_indigo bg:bg_ice)";
      };
      cwd_post_0_sep = {
        when = "test -n \"\${STARSHIP_CWD_POST_0:-}\" && test -n \"\${STARSHIP_CWD_POST_1:-}\"";
        command = "echo ";
        format = "[$output](bold fg:bg_ice_2 bg:bg_ice)";
      };
      cwd_post_1 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_POST_1\"";
        format = "[$output](fg:fg_indigo bg:bg_ice)";
      };
      cwd_post_1_sep = {
        when = "test -n \"\${STARSHIP_CWD_POST_1:-}\" && test -n \"\${STARSHIP_CWD_POST_2:-}\"";
        command = "echo ";
        format = "[$output](bold fg:bg_ice_2 bg:bg_ice)";
      };
      cwd_post_2 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_POST_2\"";
        format = "[$output](fg:fg_indigo bg:bg_ice)";
      };
      cwd_post_2_sep = {
        when = "test -n \"\${STARSHIP_CWD_POST_2:-}\" && test -n \"\${STARSHIP_CWD_POST_3:-}\"";
        command = "echo ";
        format = "[$output](bold fg:bg_ice_2 bg:bg_ice)";
      };
      cwd_post_3 = {
        when = true;
        command = "echo \"$STARSHIP_CWD_POST_3\"";
        format = "[$output](fg:fg_indigo bg:bg_ice)";
      };
      cwd_post_terminal = {
        when = "test -n \"\${STARSHIP_CWD_POST_3:-}\" || test -n \"\${STARSHIP_CWD_POST_2:-}\" || test -n \"\${STARSHIP_CWD_POST_1:-}\" || test -n \"\${STARSHIP_CWD_POST_0:-}\"";
        command = "echo ";
        format = "[$output](fg:bg_ice)";
      };
    };
  };
in {
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
  home.file.".config/starship/bash.toml".source = (pkgs.formats.toml {}).generate "bash.toml" settings;
  home.file.".config/starship/zsh.toml".source = (pkgs.formats.toml {}).generate "zsh.toml" (settings
    // {
      format = ''($aws )($glcoud )($openstack )($azure )$line_break''${custom.hh_0}''${custom.hh}[:](dimmed fg:bg_green)''${custom.mm}''${custom.p}( $singularity)( $kubernetes)( $docker_context)( $guix_shell)( $nix_shell)( $conda)( $pixi)( $direnv)( $nats) [](fg:fg_green)[ ](fg:fg_indigo bg:fg_green)$shell($shlvl)( $jobs)[](fg:fg_green bg:bg_mint)''${custom.cwd_pre_0}''${custom.cwd_pre_0_sep}''${custom.cwd_pre_0_sep_post}''${custom.cwd_pre_1}''${custom.cwd_pre_1_sep}''${custom.cwd_pre_1_sep_post}''${custom.cwd_pre_2}''${custom.cwd_pre_2_sep}''${custom.cwd_pre_2_sep_post}''${custom.cwd_pre_3}''${custom.cwd_pre_3_sep}''${custom.cwd_pre_terminal}''${custom.cwd_pre_terminal_2}''${custom.cwd_post_0}''${custom.cwd_post_0_sep}''${custom.cwd_post_1}''${custom.cwd_post_1_sep}''${custom.cwd_post_2}''${custom.cwd_post_2_sep}''${custom.cwd_post_3}''${custom.cwd_post_3_sep}''${custom.cwd_post_terminal}( $git_branch $git_commit $git_state)'';
      right_format = ''( $buf)( $bun)( $c)( $cpp)( $cmake)( $cobol)( $crystal)( $daml)( $dart)( $deno)( $dotnet)( $erlang)( $elixir)( $elm)( $fennel)( $fortran)( $gleam)( $gradle)( $golang)( $haskell)( $haxe)( $helm)( $java)( $julia)( $kotlin)( $lua)( $maven)( $meson)( $mojo)( $nodejs)( $nim)( $ocaml)( $odin)( $opa)( $perl)( $php)( $purescript)( $python)( $raku)( $quarto)( $red)( $rlang)( $ruby)( $rust)( $scala)( $solidity)( $spack)( $swift)( $terraform)( $typst)( $xmake)( $vagrant)( $vlang)( $zig)'';
    });
  home.file.".config/starship/nushell.toml".source = (pkgs.formats.toml {}).generate "zsh.toml" (settings
    // {
      format = ''($aws )($glcoud )($openstack )($azure )$line_break''${custom.hh_0}''${custom.hh}[:](dimmed fg:bg_green)''${custom.mm}''${custom.p}( $singularity)( $kubernetes)( $docker_context)( $guix_shell)( $nix_shell)( $conda)( $pixi)( $direnv)( $nats) [](fg:fg_green)[ ](fg:fg_indigo bg:fg_green)$shell($shlvl)( $jobs)[](fg:fg_green bg:bg_mint)''${custom.cwd_pre_0}''${custom.cwd_pre_0_sep}''${custom.cwd_pre_0_sep_post}''${custom.cwd_pre_1}''${custom.cwd_pre_1_sep}''${custom.cwd_pre_1_sep_post}''${custom.cwd_pre_2}''${custom.cwd_pre_2_sep}''${custom.cwd_pre_2_sep_post}''${custom.cwd_pre_3}''${custom.cwd_pre_3_sep}''${custom.cwd_pre_terminal}''${custom.cwd_pre_terminal_2}''${custom.cwd_post_0}''${custom.cwd_post_0_sep}''${custom.cwd_post_1}''${custom.cwd_post_1_sep}''${custom.cwd_post_2}''${custom.cwd_post_2_sep}''${custom.cwd_post_3}''${custom.cwd_post_3_sep}''${custom.cwd_post_terminal}( $git_branch $git_commit $git_state)'';
      right_format = ''( $buf)( $bun)( $c)( $cpp)( $cmake)( $cobol)( $crystal)( $daml)( $dart)( $deno)( $dotnet)( $erlang)( $elixir)( $elm)( $fennel)( $fortran)( $gleam)( $gradle)( $golang)( $haskell)( $haxe)( $helm)( $java)( $julia)( $kotlin)( $lua)( $maven)( $meson)( $mojo)( $nodejs)( $nim)( $ocaml)( $odin)( $opa)( $perl)( $php)( $purescript)( $python)( $raku)( $quarto)( $red)( $rlang)( $ruby)( $rust)( $scala)( $solidity)( $spack)( $swift)( $terraform)( $typst)( $xmake)( $vagrant)( $vlang)( $zig)'';
      custom = {
        hh_0 = {
          when = true;
          command = "$env.STARSHIP_HH_0";
          format = "[$output](dimmed fg:bg_green)";
        };
        hh = {
          when = true;
          command = "$env.STARSHIP_HH";
          format = "[$output](fg:fg_green)";
        };
        mm = {
          when = true;
          command = "$env.STARSHIP_MM";
          format = "[$output](fg:fg_green)";
        };
        ss = {
          when = true;
          command = "$env.STARSHIP_SS";
          format = "[$output](dimmed fg:bg_green)";
        };
        p = {
          when = true;
          command = "$env.STARSHIP_P";
          format = "[$output](dimmed fg:bg_green)";
        };
        tz = {
          when = true;
          command = "$env.STARSHIP_TZ";
          format = "[$output](dimmed fg:bg_green)";
        };
        cwd_pre_0 = {
          when = true;
          command = "$env.STARSHIP_CWD_PRE_0";
          format = "[$output](fg:fg_indigo bg:bg_mint)";
        };
        cwd_pre_0_sep = {
          when = "if ( $env.STARSHIP_CWD_PRE_0 != \"\" and $env.STARSHIP_CWD_PRE_1 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](bold fg:bg_mint_2 bg:bg_mint)";
        };
        cwd_pre_0_sep_post = {
          when = "if ( $env.STARSHIP_CWD_PRE_0 != \"\" and $env.STARSHIP_CWD_PRE_1 == \"\" and $env.STARSHIP_CWD_POST_0 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](fg:bg_mint bg:bg_ice)";
        };
        cwd_pre_1 = {
          when = true;
          command = "echo \"$env.STARSHIP_CWD_PRE_1\"";
          format = "[$output](fg:fg_indigo bg:bg_mint)";
        };
        cwd_pre_1_sep = {
          when = "if ( $env.STARSHIP_CWD_PRE_1 != \"\" and $env.STARSHIP_CWD_PRE_2 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](bold fg:bg_mint_2 bg:bg_mint)";
        };
        cwd_pre_1_sep_post = {
          when = "if ( $env.STARSHIP_CWD_PRE_1 != \"\" and $env.STARSHIP_CWD_PRE_2 == \"\" and $env.STARSHIP_CWD_POST_0 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](fg:bg_mint bg:bg_ice)";
        };
        cwd_pre_2 = {
          when = true;
          command = "echo \"$STARSHIP_CWD_PRE_2\"";
          format = "[$output](fg:fg_indigo bg:bg_mint)";
        };
        cwd_pre_2_sep = {
          when = "if ( $env.STARSHIP_CWD_PRE_2 != \"\" and $env.STARSHIP_CWD_PRE_3 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](bold fg:bg_mint_2 bg:bg_mint)";
        };
        cwd_pre_2_sep_post = {
          when = "if ( $env.STARSHIP_CWD_PRE_2 != \"\" and $env.STARSHIP_CWD_PRE_3 == \"\" and $env.STARSHIP_CWD_POST_0 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](fg:bg_mint bg:bg_ice)";
        };
        cwd_pre_3 = {
          when = true;
          command = "echo \"$STARSHIP_CWD_PRE_3\"";
          format = "[$output](fg:fg_indigo bg:bg_mint)";
        };
        cwd_pre_3_sep = {
          when = "if ( $env.STARSHIP_CWD_PRE_3 != \"\" and $env.STARSHIP_CWD_POST_0 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](fg:bg_mint bg:bg_ice)";
        };
        cwd_pre_terminal = {
          when = "if ( $env.STARSHIP_CWD_POST_0 == \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](fg:bg_mint)";
        };
        cwd_post_0 = {
          when = true;
          command = "echo \"$STARSHIP_CWD_POST_0\"";
          format = "[$output](fg:fg_indigo bg:bg_ice)";
        };
        cwd_post_0_sep = {
          when = "if ( $env.STARSHIP_CWD_POST_0 != \"\" and $env.STARSHIP_CWD_POST_1 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](bold fg:bg_ice_2 bg:bg_ice)";
        };
        cwd_post_1 = {
          when = true;
          command = "echo \"$STARSHIP_CWD_POST_1\"";
          format = "[$output](fg:fg_indigo bg:bg_ice)";
        };
        cwd_post_1_sep = {
          when = "if ( $env.STARSHIP_CWD_POST_1 != \"\" and $env.STARSHIP_CWD_POST_2 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](bold fg:bg_ice_2 bg:bg_ice)";
        };
        cwd_post_2 = {
          when = true;
          command = "echo \"$STARSHIP_CWD_POST_2\"";
          format = "[$output](fg:fg_indigo bg:bg_ice)";
        };
        cwd_post_2_sep = {
          when = "if ( $env.STARSHIP_CWD_POST_2 != \"\" and $env.STARSHIP_CWD_POST_3 != \"\" ) { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](bold fg:bg_ice_2 bg:bg_ice)";
        };
        cwd_post_3 = {
          when = true;
          command = "echo \"$STARSHIP_CWD_POST_3\"";
          format = "[$output](fg:fg_indigo bg:bg_ice)";
        };
        cwd_post_terminal = {
          when = "if ( $env.STARSHIP_CWD_POST_3 != \"\" or $env.STARSHIP_CWD_POST_2 != \"\" or $env.STARSHIP_CWD_POST_1 != \"\" or $env.STARSHIP_CWD_POST_0 != \"\") { exit 0 } else { exit 1 } ";
          command = "echo ";
          format = "[$output](fg:bg_ice)";
        };
      };
    });
}
