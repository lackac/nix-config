{ config, inputs, ... }:
let
  targetSystem = "aarch64-darwin";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  lithiumAspects = with inputs.self.modules.darwin; [
    common
    desktop
    disable-hotkeys
    fonts
    homebrew
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
