{ config, pkgs, lib, inputs, ... }:

{
  programs.home-manager.enable = true;

  # ── Git ────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user = {
        name  = "newlix";
        email = "newlix134@gmail.com";
      };
      init.defaultBranch = "main";
      credential."https://github.com".helper    = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
      filter.lfs = {
        process  = "git-lfs filter-process";
        required = true;
        clean    = "git-lfs clean -- %f";
        smudge   = "git-lfs smudge -- %f";
      };
    };
  };

  # ── Bash ───────────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    historySize     = 100000;
    historyFileSize = 200000;
    historyControl  = [ "ignoreboth" "erasedups" ];

    sessionVariables = {
      EDITOR   = if pkgs.stdenv.isDarwin then "subl -w" else "vi";
      MANPAGER = "less -X";
      GOPATH   = "$HOME/go";
      LANG     = "en_US.UTF-8";
      LC_ALL   = "en_US.UTF-8";
      HISTTIMEFORMAT = "%F %T  ";
    };

    shellAliases = {
      grep = "grep --color=auto";
      df   = "df -h";

      yt-dlp-audio = "yt-dlp -f 'bestaudio' -x --audio-format opus";
      yt-dlp-video = "yt-dlp -S ext:mp4:m4a";
      cl = "claude --dangerously-skip-permissions";
    } // (if pkgs.stdenv.isDarwin then {
      ls = "ls -G";
      ll = "ls -lahG";
    } else {
      ls = "ls --color=auto";
      ll = "ls -lah --color=auto";
    });

    initExtra = ''
      shopt -s checkwinsize globstar histappend
      bind 'set completion-ignore-case on'
      bind 'set show-all-if-ambiguous on'
      bind 'TAB:menu-complete'

      # Git branch in prompt
      parse_git_branch() {
        git branch 2>/dev/null | sed -n 's/^\* \(.*\)/ (\1)/p'
      }
      red='\[\e[1;31m\]'
      green='\[\e[1;32m\]'
      yellow='\[\e[1;33m\]'
      blue='\[\e[1;34m\]'
      reset='\[\e[0m\]'
      PS1="$blue\w$yellow\$(parse_git_branch) $red>$yellow>$green>$reset "

      # fzf keybindings (Ctrl+R history, Ctrl+T files)
      eval "$(fzf --bash)"

      # nrs: rebuild NixOS or nix-darwin depending on OS
      nrs() {
        if [ -d /etc/nixos ]; then
          sudo nixos-rebuild switch --flake /etc/nixos
        elif [ -d "$HOME/nixos-config" ]; then
          sudo darwin-rebuild switch --flake "$HOME/nixos-config"
        else
          echo "No nixos config found"
        fi
      }

      # PATH extras
      export PATH="$HOME/core/sh:$HOME/bin:$GOPATH/bin:$PATH"

      # macOS: Sublime Text CLI
      if [[ -d "/Applications/Sublime Text.app" ]]; then
        export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
      fi

      # tmux session switcher
      tm() {
        local session
        session=$(tmux ls -F "#{session_name}" | fzf --exit-0) \
          && tmux attach -t "$session" \
          || tmux new-session
      }
    '';
  };

  # ── direnv ─────────────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── tmux ───────────────────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 0;
    keyMode = "vi";
    mouse = true;
  };

  # ── User packages ──────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    gh
    claude-code
    git-lfs
    fzf

    # Go
    gopls
    golangci-lint

    # Python
    uv

    # Node.js
    nodejs

    # Backup
    restic
    rclone

    yt-dlp
    jq
    btop
    ncdu
  ];
}
