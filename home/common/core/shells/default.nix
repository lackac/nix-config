{
  pkgs,
  config,
  ...
}: let
  shellAliases = {
    psg = "ps aux | grep";
    mwget = "wget -v -c -x -r -l 0 -L -np";

    cal = "${if pkgs.stdenv.isDarwin then "gcal" else "cal"} -s1 -H '\e[44;37m:\e[0m:\e[42;37m:\e[0m'";
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

  sessionVariables = {
    # Set the default Less options.
    # Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
    # Remove -X and -F (exit if the content fits on one screen) to enable it.
    LESS = "-F -g -i -M -R -S -w -X -z-4";
    PAGER = "less";
  };

  localBin = "${config.home.homeDirectory}/.local/bin";
in {
  home.shellAliases = shellAliases;
  home.sessionVariables = sessionVariables;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:${localBin}"
    '';
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    inherit shellAliases;

    autocd = true;
    dirHashes = {
      Code = "$HOME/Code";
      Notes = "$HOME/Documents/Notes";
      Sandbox = "$HOME/Code/sandbox";
    };
    dotDir = ".config/zsh";
    historySubstringSearch.enable = true;
    syntaxHighlighting.enable = true;
  };
}
