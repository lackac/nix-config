{ config, inputs, ... }:
let
  targetSystem = "x86_64-linux";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  boronAspects = with inputs.self.modules.nixos; [
    # Platform bases
    common
    server
    secrets

    # Hardware
    hardware-n100
    disko-nvme

    # Features
    docker
    mc
  ];

  boronInline = {
    networking.hostName = "boron";
    system.stateVersion = "25.11";
  };

  boronModules = boronAspects ++ [ boronInline ];
in
{
  flake.nixosConfigurations.boron = inputs.nixpkgs.lib.nixosSystem {
    system = targetSystem;
    modules = boronModules;

    specialArgs = sharedSpecialArgs;
  };

  flake.colmena.boron = {
    imports = boronModules;

    deployment = {
      targetHost = "10.7.0.201";
      targetUser = "lackac";
      allowLocalDeployment = false;
    };
  };
}
