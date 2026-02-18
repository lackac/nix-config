{ config, inputs, ... }:
let
  targetSystem = "aarch64-linux";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  neonAspects = with inputs.self.modules.nixos; [
    common
    server

    disko-vm-vda
  ];

  neonInline = {
    networking.hostName = "neon";
    system.stateVersion = "25.11";
  };

  neonModules = neonAspects ++ [ neonInline ];
in
{
  flake.nixosConfigurations.neon = inputs.nixpkgs.lib.nixosSystem {
    system = targetSystem;
    modules = neonModules;
    specialArgs = sharedSpecialArgs;
  };

  flake.colmena.neon = {
    imports = neonModules;

    deployment = {
      targetHost = "192.168.64.6";
      targetUser = "lackac";
      allowLocalDeployment = false;
    };
  };

  colmenaNodeSystems.neon = targetSystem;
}
