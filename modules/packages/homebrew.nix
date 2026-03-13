{ config, inputs, ... }:
{
  flake.modules.darwin.homebrew =
    { ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      nix-homebrew = {
        enable = true;
        autoMigrate = true;
        user = config.vars.username;
        mutableTaps = false;
        enableBashIntegration = false;
        enableFishIntegration = false;
        enableZshIntegration = false;
        taps = {
          "homebrew/homebrew-core" = inputs.homebrew-core;
          "homebrew/homebrew-cask" = inputs.homebrew-cask;
        };
      };

      homebrew = {
        enable = true;

        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "none";
        };

        brews = [
          "mas"
        ];

        casks = [
          "brave-browser"
          "chatgpt"
          "claude"
          "dash"
          "google-chrome"
          "google-drive"
          "hammerspoon"
          "jordanbaird-ice"
          "obsidian"
          "session-manager-plugin"
          "shortcat"
          "tableplus"
        ];

        masApps = {
          "1Password for Safari" = 1569813296;
          "Perplexity" = 6714467650;
          "The Unarchiver" = 425424353;
        };
      };
    };
}
