{...}: {
  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = ''
      export STARSHIP_CONFIG="$HOME/.config/starship/bash.toml";

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
}
