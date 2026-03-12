{ config, inputs, ... }:
let
  targetSystem = "aarch64-darwin";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  lithiumAspects = with config.flake.modules.darwin; [
    common
    desktop
    disable-hotkeys
    fonts
    games
    hammerspoon
    homebrew
    home
    keyboard-layout
    onePassword
    tailscale
  ];

  lithiumInline = {
    networking.hostName = "lithium";
    networking.computerName = "lithium";
    system.stateVersion = 6;

    homebrew = {
      casks = [
        "autodesk-fusion"
        "dash"
        "discord"
        "iina"
        "mattermost"
        "microsoft-teams"
        "monologue"
        "plex"
        "prusaslicer"
        "slack"
        "tableplus"
        "utm"
        "viscosity"
      ];

      masApps = {
        "Affinity Designer" = 824171161;
        "Affinity Photo" = 824183456;
      };
    };
  };

  lithiumModules = lithiumAspects ++ [ lithiumInline ];
in
{
  flake.darwinConfigurations.lithium = inputs.nix-darwin.lib.darwinSystem {
    system = targetSystem;
    modules = lithiumModules;

    specialArgs = sharedSpecialArgs;
  };
}
