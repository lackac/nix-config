{ config, inputs, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.darwin.homebrew =
    { ... }:
    {
      imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

      nix-homebrew = {
        enable = true;
        autoMigrate = true;
        user = vars.username;
        mutableTaps = false;
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
          "1password"
          "1password-cli"
          "brave-browser"
          "crossover"
          "curseforge"
          "discord"
          "google-chrome"
          "google-drive"
          "hammerspoon"
          "jordanbaird-ice"
          "kitty"
          "mattermost"
          "microsoft-teams"
          "obsidian"
          "prusaslicer"
          "session-manager-plugin"
          "shortcat"
          "slack"
          "utm"
          "viscosity"
        ];

        masApps = {
          "Perplexity" = 6714467650;
          "The Unarchiver" = 425424353;
        };
      };
    };
}
