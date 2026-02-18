{ config, inputs, ... }:
let
  targetSystem = "aarch64-linux";

  sharedSpecialArgs = {
    inherit inputs;
    inherit (config) vars;
  };

  oxygenAspects = with inputs.self.modules.nixos; [
    common
    server
    secrets

    hardware-rpi4
    (inputs.nixpkgs + "/nixos/modules/installer/sd-card/sd-image-aarch64.nix")

    tailscale
    octoprint
    octoprint-proxy
  ];

  oxygenInline =
    { lib, ... }:
    {
      networking.hostName = "oxygen";
      system.stateVersion = "25.11";
      sops.defaultSopsFile = ../../secrets/oxygen.yaml;
      hardware.enableAllHardware = lib.mkForce false;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };
        "/boot/firmware" = {
          device = "/dev/disk/by-label/FIRMWARE";
          fsType = "vfat";
          options = [
            "nofail"
            "noauto"
          ];
        };
      };
    };

  oxygenModules = oxygenAspects ++ [ oxygenInline ];
in
{
  flake.nixosConfigurations.oxygen = inputs.nixpkgs.lib.nixosSystem {
    system = targetSystem;
    modules = oxygenModules;
    specialArgs = sharedSpecialArgs;
  };

  flake.colmena.oxygen = {
    imports = oxygenModules;

    deployment = {
      targetHost = "oxygen";
      targetUser = "lackac";
      allowLocalDeployment = false;
    };
  };

  colmenaNodeSystems.oxygen = targetSystem;
}
