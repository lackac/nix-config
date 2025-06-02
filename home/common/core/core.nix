{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # the modern command line
    delta # A viewer for git and diff output
    doggo # DNS client for humans
    duf # Disk Usage/Free Utility - a better 'df' alternative
    du-dust # A more intuitive version of `du` in rust
    gdu # disk usage analyzer(replacement of `du`)
    ncdu # analyzer your disk usage Interactively, via TUI(replacement of `du`)
    fd # better and faster `find`
    fzf
    jq
    just # a command runner like make, but simpler
    lazygit # git terminal UI
    ripgrep
    sad # search and replace, just like sed, but with diff preview
    yq-go # same as jq, but for YAML

    # Misc
    gcal
    gnupg
    gnumake

    # nix related
    #
    # it provides the command `nom` works just like `nix
    # with more details log output
    nix-output-monitor
    nix-init # generate nix derivation from url
    # https://github.com/nix-community/nix-melt
    nix-melt # TUI flake.lock viewer
    # https://github.com/utdemir/nix-tree
    nix-tree # TUI to visualize the dependency graph of a nix derivation

    # productivity
    caddy # A webserver with automatic HTTPS via Let's Encrypt(replacement of nginx)
    croc # File transfer between computers securely and easily
  ];

  # shell aliases for the programs listed below
  home.shellAliases = {
    l="eza -l";
    lk="eza -l --sort=size";
    lm="eza -l --sort=modified";
    lc="eza -l --sort=changed";
    lu="eza -l --sort=accessed";
  };

  # custom configuration for the programs listed below
  home.sessionVariables = {
    BAT_STYLE = "plain";
    # colors for jq which work in both light and dark themes
    JQ_COLORS = "2;35:0;31:0;32:0;33:0;36:0;34:0;34:1;34";
  };

  programs = {
    # Atuin replaces your existing shell history with a SQLite database,
    # and records additional context for your commands.
    # Additionally, it provides optional and fully encrypted
    # synchronisation of your history between machines, via an Atuin server.
    atuin = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      flags = [
        "--disable-up-arrow"
      ];
      settings = {
        dialect = "uk";
        inline_height = 25;
        common_subcommands = [
          "apt"
          "cargo"
          "composer"
          "dnf"
          "docker"
          "git"
          "go"
          "ip"
          "jj"
          "kubectl"
          "nix"
          "nmcli"
          "npm"
          "pecl"
          "pnpm"
          "podman"
          "port"
          "systemctl"
          "tmux"
          "yarn"

          "aws"
          "100s"
          "cplus"
          "t"
        ];
      };
    };

    # a cat(1) clone with syntax highlighting and Git integration.
    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "Solarized (light)";
      };
    };

    # A modern replacement for ‘ls’
    # useful in bash/zsh prompt, not in nushell.
    eza = {
      enable = true;
      git = true;
      icons = "auto";
      enableZshIntegration = true;
    };

    # A command-line fuzzy finder
    fzf = {
      enable = true;
      defaultCommand = "fd --type f";

      changeDirWidgetCommand = "fd --type d";
      changeDirWidgetOptions = [ "--preview 'tree -C {} | head -200'" ];
      fileWidgetCommand = "fd --type f";
      fileWidgetOptions = [ "--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'" ];
      historyWidgetOptions = [ "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'" ];

      tmux = {
        enableShellIntegration = true;
        shellIntegrationOptions = [ "-p80%,60%" ];
      };
    };

    # very fast version of tldr in Rust
    tealdeer = {
      enable = true;
      enableAutoUpdates = true;
      settings = {
        display = {
          compact = false;
          use_pager = true;
        };
        updates = {
          auto_update = false;
          auto_update_interval_hours = 720;
        };
      };
    };

    # zoxide is a smarter cd command, inspired by z and autojump.
    # It remembers which directories you use most frequently,
    # so you can "jump" to them in just a few keystrokes.
    # zoxide works on all major shells.
    #
    #   z foo              # cd into highest ranked directory matching foo
    #   z foo bar          # cd into highest ranked directory matching foo and bar
    #   z foo /            # cd into a subdirectory starting with foo
    #
    #   z ~/foo            # z also works like a regular cd command
    #   z foo/             # cd into relative path
    #   z ..               # cd one level up
    #   z -                # cd into previous directory
    #
    #   zi foo             # cd with interactive selection (using fzf)
    #
    #   z foo<SPACE><TAB>  # show interactive completions (zoxide v0.8.0+, bash 4.4+/fish/zsh only)
    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      options = [
        "--cmd cd"
      ];
    };
  };
}
