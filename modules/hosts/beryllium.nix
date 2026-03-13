{ config, inputs, ... }:
let
  targetSystem = "aarch64-darwin";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  berylliumAspects = with config.flake.modules.darwin; [
    common
    desktop
    disable-hotkeys
    fonts
    hammerspoon
    homebrew
    home
    keyboard-layout
    onePassword
    tailscale
  ];

  berylliumInline = {
    networking.hostName = "beryllium";
    networking.computerName = "beryllium";
    system.stateVersion = 6;

    homebrew = {
      casks = [
        "viscosity"
      ];
    };
  };

  berylliumModules = berylliumAspects ++ [ berylliumInline ];
in
{
  flake.darwinConfigurations.beryllium = inputs.nix-darwin.lib.darwinSystem {
    system = targetSystem;
    modules = berylliumModules;

    specialArgs = sharedSpecialArgs;
  };
}
