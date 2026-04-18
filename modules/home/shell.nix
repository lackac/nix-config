{ ... }:
{
  flake.modules.homeManager.shell =
    { config, pkgs, ... }:
    let
      localBin = "${config.home.homeDirectory}/.local/bin";
      homebrewFallbackPath = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/local/sbin";
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      home.shellAliases = {
        nix = "noglob nix";
        nvf = "nix run ~/Code/lackac/nvf-config";
        dr = "direnv reload";
        tat = "tmux attach";
        psg = "ps aux | grep";
        mwget = "wget -v -c -x -r -l 0 -L -np";

        oc = "opencode";
        ocs = "opencode-session";

        cal = "gcal -s1 -H '\\e[44;37m:\\e[0m:\\e[42;37m:\\e[0m'";
        cal-hu = "cal -qHU";
        cal-en = "cal -qGB_EN";
        cal-gb = "cal-en";
        cal-uk = "cal-en";

        b = "bundle";
        bi = "b install";
        bu = "b update";
        be = "b exec";
        binit = "b install --path vendor && b package --all && echo 'vendor/ruby' >> .gitignore";
      };

      home.sessionVariables = {
        LESS = "-F -g -i -M -R -S -w -X";
        PAGER = "less";
        JQ_COLORS = "2;35:0;31:0;32:0;33:0;36:0;34:0;34:1;34";
      };

      programs.bash = {
        enable = true;
        enableCompletion = true;
        bashrcExtra = ''
          export PATH="$PATH:${localBin}${if isDarwin then ":${homebrewFallbackPath}" else ""}"
        '';
      };

      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autocd = true;
        dirHashes = {
          Code = "$HOME/Code";
          Notes = "$HOME/Documents/Notes";
          Sandbox = "$HOME/Code/sandbox";
        };
        dotDir = "${config.xdg.configHome}/zsh";
        historySubstringSearch.enable = false;
        syntaxHighlighting.enable = true;

        initContent = ''
          ${
            if isDarwin then
              ''
                # XDG runtime directory
                export XDG_RUNTIME_DIR="$HOME/Library/Caches/TemporaryItems/runtime"
                mkdir -p -m 700 "$XDG_RUNTIME_DIR"
              ''
            else
              ""
          }

          autoload -Uz select-word-style
          select-word-style bash

          export PATH="$PATH:${localBin}${if isDarwin then ":${homebrewFallbackPath}" else ""}"
        '';
      };

      editorconfig = {
        enable = true;
        settings = {
          "*" = {
            end_of_line = "lf";
            indent_style = "space";
            indent_size = 2;
            trim_trailing_whitespace = true;
            insert_final_newline = true;
          };
        };
      };

      programs.readline = {
        enable = true;
        variables = {
          meta-flag = true;
          input-meta = true;
          output-meta = true;
          convert-meta = false;
          completion-ignore-case = true;
        };
        bindings = {
          "\\e[3~" = "delete-char";
          "TAB" = "menu-complete";
          "\\e[Z" = "\"\\M--1\\t\"";
        };
      };

      xdg = {
        enable = true;
        cacheHome =
          if isDarwin then
            "${config.home.homeDirectory}/Library/Caches"
          else
            "${config.home.homeDirectory}/.cache";
      };
    };
}
