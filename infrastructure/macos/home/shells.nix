{...}: {
  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      prompt_env_pre(){
        local pre=
        local post=
        if command -v git >/dev/null; then
          pre=$(git rev-parse --show-toplevel 2>/dev/null) || pre=""
        fi
        [ -z "$pre" ] && pre="$HOME"

        if [[ "$PWD" != "$pre"* ]]; then
          pre="$PWD"
          post=""
        else
          post="''${PWD#$pre}"
        fi

        IFS="/"
        read -r -a pre_seg <<< "$pre"
        read -r -a post_seg <<< "$post"

        STARSHIP_CWD_PRE_0="''${pre_seg[1]}"
        STARSHIP_CWD_PRE_1="''${pre_seg[2]}"
        STARSHIP_CWD_PRE_2="''${pre_seg[3]}"
        STARSHIP_CWD_PRE_3="''${pre_seg[4]}"

        if (( "''${#pre_seg[@]}" > 4 )); then
          STARSHIP_CWD_PRE_2="󰇘"
          STARSHIP_CWD_PRE_3="''${pre_seg[(( ''${#pre_seg[@]} - 1 ))]}"
        fi

        if ! command -v uname >/dev/null; then
          echo "uname command missing" &>2 && return 1
        fi

        if [ -z "$STARSHIP_CWD_PRE_0" ]; then
          if [ $(uname) = "Darwin" ]; then
            STARSHIP_CWD_PRE_0=""
          else
            STARSHIP_CWD_PRE_0=""
          fi
        fi

        STARSHIP_CWD_POST_0="''${post_seg[1]}"
        STARSHIP_CWD_POST_1="''${post_seg[2]}"

        if (( ''${#post_seg[@]} > 4 )); then
          STARSHIP_CWD_POST_1="󰇘"
        fi

        STARSHIP_CWD_POST_2="''${post_seg[(( ''${#post_seg[@]} > 4 ? ''${#post_seg[@]} - 2 : 3 ))]}"
        STARSHIP_CWD_POST_3="''${post_seg[(( ''${#post_seg[@]} > 4 ? ''${#post_seg[@]} - 1 : 4 ))]}"

        if ! command -v date >/dev/null; then
          echo "date command missing" &>2 && return 1
        fi

        read -r STARSHIP_HH STARSHIP_MM STARSHIP_SS STARSHIP_P STARSHIP_TZ <<< "$(date +'%I/%M/%S/%p/%Z')"

        STARSHIP_HH="''${STARSHIP_HH#0}"

        STARSHIP_HH_0=

        if (( "$STARSHIP_HH" < 10 )); then
          STARSHIP_HH_0="0"
        fi

        export STARSHIP_CWD_PRE_0 STARSHIP_CWD_PRE_1 STARSHIP_CWD_PRE_2 STARSHIP_CWD_PRE_3 STARSHIP_CWD_POST_0 STARSHIP_CWD_POST_1 STARSHIP_CWD_POST_2 STARSHIP_CWD_POST_3 STARSHIP_HH_0 STARSHIP_HH STARSHIP_MM STARSHIP_SS STARSHIP_P STARSHIP_TZ
      }

      PROMPT_COMMAND="prompt_env_pre; $PROMPT_COMMAND"

      if [[ $- == *i* ]]; then
        cat() {
          # use builtin cat if no arg
          (( $# == 0 )) && command cat && return
        bat "$@"
        }

        cd() {
          command cd "$@" 2>/dev/null || z "$@"
        }
      fi
    '';
  };
  programs.zed-editor = {
    enable = true;
    package = null;
    userSettings = {
      buffer_font_family = "Lilex Nerd Font Propo";
      terminal.font_family = "Lilex Nerd Font Propo";
    };
  };
  programs.zsh = {
    # many settings from here: https://github.com/incremental-design/dev-boxes/blob/1479e9244d0b26014a16474266d0df3c20fb9e96/MacOS/flake.nix#L207
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#161C4D,bg=#D2F1FF";
    };
    history = {
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    historySubstringSearch = {
      enable = true;
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
      ];
    };
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.3.0";
          sha256 = "sha256-8atbysoOyCBW2OYKmdc91x9V/Mk3eyg3hvzvhJpQ32w=";
        };
      }
    ];
    initContent = let
      starship_env_vars = lib.mkOrder 800 ''
        prompt_env_pre(){

          local pre=
          local post=
          if command -v git >/dev/null; then
            pre=$(git rev-parse --show-toplevel 2>/dev/null) || pre=""
          fi
          [ -z "$pre" ] && pre="$HOME";

          if [[ "$PWD" != "$pre"* ]]; then
            pre="$PWD"
            post=""
          else
            post="''${PWD#$pre}"
          fi

          pre="''${pre#/}"
          post="''${post#/}"
          pre=("''${(@s:/:)pre}")
          post=("''${(@s:/:)post}")

          STARSHIP_CWD_PRE_0="$pre[1]"
          STARSHIP_CWD_PRE_1="$pre[2]"
          STARSHIP_CWD_PRE_2="$pre[3]"
          STARSHIP_CWD_PRE_3="$pre[4]"

          if (( "''${#pre[@]}" > 4 )); then
            STARSHIP_CWD_PRE_2="󰇘"
            STARSHIP_CWD_PRE_3="$pre[-1]"
          fi

          if ! command -v uname >/dev/null; then
            echo "uname command missing" &>2 && return 1
          fi

          if [ -z "$STARSHIP_CWD_PRE_0" ]; then
            if [ $(uname) = "Darwin" ]; then
              STARSHIP_CWD_PRE_0=""
            else
              STARSHIP_CWD_PRE_0=""
            fi
          fi

          STARSHIP_CWD_POST_0="$post[1]"
          STARSHIP_CWD_POST_1="$post[2]"

          if (( ''${#post[@]} > 4 )); then
            STARSHIP_CWD_POST_1="󰇘"
          fi

          STARSHIP_CWD_POST_2="$post[(( ''${#post[@]} > 4 ? -2 : 3 ))]"
          STARSHIP_CWD_POST_3="$post[(( ''${#post[@]} > 4 ? -1 : 4 ))]"

          local now=(''${(s:/:)$(print -P '%D{%I/%M/%S/%p/%Z}')})

          STARSHIP_HH_0=

          if (( ''${now[1]} < 10 )); then
            STARSHIP_HH_0="0"
          fi

          STARSHIP_HH="''${now[1]#0}"
          STARSHIP_MM="''${now[2]}"
          STARSHIP_SS="''${now[3]}"
          STARSHIP_P="''${now[4]}"
          STARSHIP_TZ="''${now[5]}"

          export STARSHIP_CWD_PRE_0 STARSHIP_CWD_PRE_1 STARSHIP_CWD_PRE_2 STARSHIP_CWD_PRE_3 STARSHIP_CWD_POST_0 STARSHIP_CWD_POST_1 STARSHIP_CWD_POST_2 STARSHIP_CWD_POST_3 STARSHIP_HH_0 STARSHIP_HH STARSHIP_MM STARSHIP_SS STARSHIP_P STARSHIP_TZ
        }

        add-zsh-hook precmd prompt_env_pre
      '';
      bat = lib.mkOrder 1498 ''
        if [[ -o interactive ]]; then
          cat() {
            # use builtin cat if no arg
            (( $# == 0 )) && builtin cat && return
            bat "$@"
          }
        fi
      '';
      zoxide = lib.mkOrder 1499 ''
        if [[ -o interactive ]]; then
          cd() {
            builtin cd "$@" 2>/dev/null || z "$@"
          }
        fi
      '';
      history = lib.mkOrder 1500 ''
        MCFLY_RESULTS_SORT="LAST_RUN"
        # match case insensitive
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

        # see: https://github.com/Aloxaf/fzf-tab/tree/master?tab=readme-ov-file#configure
        # disable sort when completing `git checkout`
        zstyle ':completion:*:git-checkout:*' sort false
        # set descriptions format to enable group support
        # NOTE: don't use escape sequences here, fzf-tab will ignore them
        zstyle ':completion:*:descriptions' format '[%d]'
        # set list-colors to enable filename colorizing
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        # force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
        zstyle ':completion:*' menu no
        # preview directory's content with eza when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        # switch group using `<` and `>`
        zstyle ':fzf-tab:*' switch-group '<' '>'
      '';
    in
      lib.mkMerge [
        starship_env_vars
        bat
        zoxide
        history
      ];
  };
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.mcfly = {
    enable = true;
    fzf.enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    git = true;
    icons = "always";
  };
  programs.bat = {
    enable = true;
    config = {
      theme = "ansi";
    };
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings = {
      add_newline = true;
      format = ''($aws )($glcoud )($openstack )($azure )$line_break''${custom.hh_0}''${custom.hh}[:](dimmed fg:bg_green)''${custom.mm}''${custom.p}( $singularity)( $kubernetes)( $docker_context)( $guix_shell)( $nix_shell)( $conda)( $pixi)( $direnv)( $nats) [](fg:fg_green)[ ](fg:fg_indigo bg:fg_green)$shell($shlvl)( $jobs)[](fg:fg_green bg:bg_mint)''${custom.cwd_pre_0}''${custom.cwd_pre_0_sep}''${custom.cwd_pre_0_sep_post}''${custom.cwd_pre_1}''${custom.cwd_pre_1_sep}''${custom.cwd_pre_1_sep_post}''${custom.cwd_pre_2}''${custom.cwd_pre_2_sep}''${custom.cwd_pre_2_sep_post}''${custom.cwd_pre_3}''${custom.cwd_pre_3_sep}''${custom.cwd_pre_terminal}''${custom.cwd_pre_terminal_2}''${custom.cwd_post_0}''${custom.cwd_post_0_sep}''${custom.cwd_post_1}''${custom.cwd_post_1_sep}''${custom.cwd_post_2}''${custom.cwd_post_2_sep}''${custom.cwd_post_3}''${custom.cwd_post_3_sep}''${custom.cwd_post_terminal}( $git_branch$git_commit$git_state)$fill( $buf)( $bun)( $c)( $cpp)( $cmake)( $cobol)( $crystal)( $daml)( $dart)( $deno)( $dotnet)( $erlang)( $elixir)( $elm)( $fennel)( $fortran)( $gleam)( $gradle)( $golang)( $haskell)( $haxe)( $helm)( $java)( $julia)( $kotlin)( $lua)( $maven)( $meson)( $mojo)( $nodejs)( $nim)( $ocaml)( $odin)( $opa)( $perl)( $php)( $purescript)( $python)( $raku)( $quarto)( $red)( $rlang)( $ruby)( $rust)( $scala)( $solidity)( $spack)( $swift)( $terraform)( $typst)( $xmake)( $vagrant)( $vlang)( $zig)'';
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
  };
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
