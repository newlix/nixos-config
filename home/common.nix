{ config, pkgs, lib, inputs, ... }:

{
  programs.home-manager.enable = true;

  # ── Pointer Cursor (Linux only) ───────────────────────────────────────────
  home.pointerCursor = lib.mkIf pkgs.stdenv.isLinux {
    enable  = true;
    package = pkgs.adwaita-icon-theme;
    name    = "Adwaita";
    size    = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # ── Git ────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      ".DS_Store" "._*" ".Spotlight-V100" ".Trashes"
      "*.swp" "*.swo" "*~"
      ".vscode" ".idea"
    ];
    settings = {
      user = {
        name  = "newlix";
        email = "newlix134@gmail.com";
      };
      init.defaultBranch = "main";
      credential."https://github.com".helper    = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
    };
  };

  # ── Bash ───────────────────────────────────────────────────────────────────
  programs.bash = {
    enable = true;
    historySize     = 100000;
    historyFileSize = 200000;
    historyControl  = [ "ignoreboth" "erasedups" ];

    sessionVariables = {
      EDITOR   = "vi";
      VISUAL   = if pkgs.stdenv.isDarwin then "subl -w" else "vi";
      MANPAGER = "less -X";
      LANG     = "en_US.UTF-8";
      LC_ALL   = "en_US.UTF-8";
      ANDROID_HOME = "$HOME/Android/Sdk";
      ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
      HISTTIMEFORMAT = "%F %T  ";
    };

    shellAliases = {
      grep = "grep --color=auto";
      yt-dlp-audio = "yt-dlp -f 'bestaudio' -x --audio-format mp3 --cookies-from-browser chrome";
      yt-dlp-video = "yt-dlp -S ext:mp4:m4a --cookies-from-browser chrome";
      cl = "claude";
      cl-claude = "claude-anthropic";
      gemini = "npx @google/gemini-cli -y";
      omp = "bunx @oh-my-pi/pi-coding-agent";
      cat = "bat --paging=never";
      ls = "eza";
      ll = "eza -la";
      tree = "eza --tree";
    } // (if pkgs.stdenv.isDarwin then {} else {
      zed = "zeditor";
      what-file = "lsof -p $(pgrep -d, -f amberol) 2>/dev/null | grep -iE '\\.(mp3|flac|wav|m4a|ogg|opus)$' | awk '{print $NF}' | head -n 1";
    });

    initExtra = ''

      # ── Claude Code: quick-switch between DeepSeek & Anthropic ─────────────
      # cl             → DeepSeek V4 Pro  (needs DEEPSEEK_API_KEY)
      # cl-claude      → Anthropic Sonnet  (needs ANTHROPIC_API_KEY)
      __claude_anthropic() {
        unset ANTHROPIC_BASE_URL
        export ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_API_KEY"
        export ANTHROPIC_MODEL="claude-sonnet-4-20250514"
        unset ANTHROPIC_DEFAULT_OPUS_MODEL ANTHROPIC_DEFAULT_SONNET_MODEL ANTHROPIC_DEFAULT_HAIKU_MODEL
        export CLAUDE_CODE_SUBAGENT_MODEL="claude-sonnet-4-20250514"
        echo "Claude Code → Anthropic (claude-sonnet-4)"
      }
      __claude_deepseek() {
        export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
        export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
        export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
        export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
        echo "Claude Code → DeepSeek V4 Pro"
      }
      # Default: DeepSeek
      __claude_deepseek
      alias claude='__claude_deepseek; \claude'
      alias claude-anthropic='__claude_anthropic; \claude'
      source ~/dotfiles/profile.local 2>/dev/null || true

      shopt -s checkwinsize globstar histappend
      bind 'set completion-ignore-case on'
      bind 'set show-all-if-ambiguous on'
      bind 'TAB:menu-complete'

      # zoxide (smart cd)
      eval "$(zoxide init bash)"

      # Git branch in prompt
      parse_git_branch() {
        git branch 2>/dev/null | sed -n 's/^\* \(.*\)/ (\1)/p'
      }
      PS1='\[\e[1;34m\]\w\[\e[1;33m\]$(parse_git_branch) \[\e[1;31m\]>\[\e[1;33m\]>\[\e[1;32m\]>\[\e[0m\] '

      # nrs (nix rebuild switch): Generic rebuild script
      nrs() {
        local flake="/etc/nixos"
        [ ! -d "$flake" ] && flake="$HOME/nixos-config"
        [ ! -d "$flake" ] && { echo "No nixos config found" >&2; return 1; }

        local host=$(hostname)
        # Handle cases where hostname might not match flake output (e.g. macOS)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            host="mac"
        elif [[ "$host" != "lab" ]]; then
            echo "Unknown host: $host. Add a flake output for it." >&2
            return 1
        fi

        git -C "$flake" pull || return 1
        if [ "$1" = "-u" ]; then
          nix flake update --flake "$flake" || return 1
        fi

        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
          sudo nixos-rebuild switch --flake "$flake#$host" && {
            # Graceful restart of UI components
            systemctl --user restart waybar.service
          }
        else
          sudo darwin-rebuild switch --flake "$flake#$host"
        fi
      }

      # PATH extras
      export PATH="$HOME/core/sh:$HOME/bin:$HOME/go/bin:$PATH"

      # macOS-only
      if [[ "$(uname)" == "Darwin" ]]; then
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        export DOCKER_HOST="ssh://newlix@lab"
      fi
      if [[ -d "/Applications/Sublime Text.app" ]]; then
        export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"
      fi
    '';
  };

  # ── fzf ───────────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  # ── direnv ─────────────────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # ── Go ─────────────────────────────────────────────────────────────────────
  programs.go = {
    enable = true;
    env.GOPATH = "${config.home.homeDirectory}/go";
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

  # ── omp (Oh My Pi coding agent) ───────────────────────────────────────────
  home.file.".omp/agent/config.yml".source = ./omp/config.yml;

}
