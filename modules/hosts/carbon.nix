{ config, inputs, ... }:
let
  targetSystem = "x86_64-linux";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  carbonAspects = with inputs.self.modules.nixos; [
    # Platform bases
    common
    server
    secrets

    # Hardware
    hardware-n100
    disko-nvme

    # Features
    tailscale
    postgres
    mattermost
    caddy
  ];

  carbonInline = {
    networking.hostName = "carbon";
    system.stateVersion = "25.11";
    sops.defaultSopsFile = ../../secrets/carbon.yaml;
  };

  carbonModules = carbonAspects ++ [ carbonInline ];

  colmenaConfig = {
    meta = {
      nixpkgs = import inputs.nixpkgs {
        system = targetSystem;
      };
      specialArgs = sharedSpecialArgs;
    };

    carbon = {
      imports = carbonModules;

      deployment = {
        targetHost = "carbon"; # Tailscale hostname
        targetUser = "root";
        allowLocalDeployment = false;
      };
    };
  };
in
{
  flake.nixosConfigurations.carbon = inputs.nixpkgs.lib.nixosSystem {
    system = targetSystem;
    modules = carbonModules;

    specialArgs = sharedSpecialArgs;
  };

  flake.colmena = colmenaConfig;
  flake.colmenaHive = inputs.colmena.lib.makeHive colmenaConfig;
}
