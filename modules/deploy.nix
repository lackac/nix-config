{ config, inputs, ... }: {
  flake.colmena = {
    meta = {
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };
      specialArgs = {
        inherit inputs;
        inherit (config) vars;
      };
    };

    carbon = {
      deployment = {
        targetHost = "carbon"; # Tailscale hostname
        targetUser = "root";
        allowLocalDeployment = false;
      };

      imports =
        (with inputs.self.modules.nixos; [
          common
          server
          secrets
          hardware-n100
          disko-nvme
          tailscale
          postgres
          mattermost
          caddy
        ]);

      networking.hostName = "carbon";
      system.stateVersion = "25.11";
      sops.defaultSopsFile = ./secrets/carbon.yaml;
    };
  };
}
