{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
##########################################################################
#
#  Install all apps and packages here.
#
#  NOTE: Your can find all available options in:
#    https://daiderd.com/nix-darwin/manual/index.html
#
#  NOTE：To remove the uninstalled APPs icon from Launchpad:
#    1. `sudo nix store gc --debug` & `sudo nix-collect-garbage --delete-old`
#    2. click on the uninstalled APP's icon in Launchpad, it will show a question mark
#    3. if the app starts normally:
#        1. right click on the running app's icon in Dock, select "Options" -> "Show in Finder" and delete it
#    4. hold down the Option key, a `x` button will appear on the icon, click it to remove the icon
#
##########################################################################
{
  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;
  environment.shells = [
    pkgs.zsh
  ];

  # The apps installed by homebrew are not managed by nix, and not reproducible!
  # But on macOS, homebrew has a much larger selection of apps than nixpkgs, especially for GUI apps!
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
    };

    # `brew install`
    brews = [
      "m-cli" #  Swiss Army Knife for macOS
    ];

    # `brew install --cask`
    casks = [
      "brave-browser"

      # productivity
      "dash"
      "google-drive"
      "hammerspoon"
      "jordanbaird-ice" # open source Bartender alternative menu bar manager for macOS
      "shortcat"

      # work related
      "microsoft-teams"
      "session-manager-plugin"
      "slack"
      "tableplus"
      "zoom"

      # gaming
      "curseforge"
      "minecraft"

      # media
      "vlc"

      # misc
      "prusaslicer"
    ];

    # Applications to install from Mac App Store using mas.
    # For details, see https://github.com/mas-cli/mas
    masApps = {
      "Perplexity" = 6714467650;
      "The Unarchiver" = 425424353;
    };
  };
}
