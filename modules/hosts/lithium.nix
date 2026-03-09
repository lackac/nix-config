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
  ];

  lithiumInline = {
    networking.hostName = "lithium";
    networking.computerName = "lithium";
    system.stateVersion = 6;
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
