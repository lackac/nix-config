{ config, inputs, ... }: {
  flake.nixosConfigurations.carbon =
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        (with inputs.self.modules.nixos; [
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
        ])
        ++ [
          # Host-specific inline config
          {
            networking.hostName = "carbon";
            system.stateVersion = "25.11";
            sops.defaultSopsFile = ../../secrets/carbon.yaml;
          }
        ];

      specialArgs = {
        inherit inputs;
        inherit (config) vars;
      };
    };
}
