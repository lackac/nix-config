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
          "autodesk-fusion"
          "brave-browser"
          "chatgpt"
          "claude"
          "crossover"
          "dash"
          "discord"
          "google-chrome"
          "google-drive"
          "hammerspoon"
          "iina"
          "jordanbaird-ice"
          "mattermost"
          "microsoft-teams"
          "monologue"
          "obsidian"
          "plex"
          "prusaslicer"
          "session-manager-plugin"
          "shortcat"
          "slack"
          "tableplus"
          "utm"
          "viscosity"
        ];

        masApps = {
          "1Password for Safari" = 1569813296;
          "Affinity Designer" = 824171161;
          "Affinity Photo" = 824183456;
          "Perplexity" = 6714467650;
          "The Unarchiver" = 425424353;
        };
      };
    };
}
