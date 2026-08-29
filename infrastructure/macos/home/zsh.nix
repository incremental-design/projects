{
  pkgs,
  lib,
  ...
}: {
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
        export STARSHIP_CONFIG="$HOME/.config/starship/zsh.toml";
        ZLE_RPROMPT_INDENT=0;

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
}
