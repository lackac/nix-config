{ config, inputs, ... }:
let
  targetSystem = "aarch64-linux";

  sharedSpecialArgs = inputs // {
    inherit inputs;
    inherit (config) vars;
  };

  oxygenAspects = with inputs.self.modules.nixos; [
    common
    server
    secrets

    tailscale
    octoprint
    octoprint-proxy
  ];

  oxygenInline =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = with inputs.nixos-raspberrypi.nixosModules; [
        sd-image
        nixpkgs-rpi
        raspberry-pi-4.base
        raspberry-pi-4.display-vc4
      ];

      networking.hostName = "oxygen";
      system.stateVersion = "25.11";
      sops.defaultSopsFile = ../../secrets/oxygen.yaml;
      hardware.enableAllHardware = lib.mkForce false;

      networking.wireless = {
        enable = true;
        secretsFile = config.sops.templates."wireless/secrets".path;
        networks."Hovirag".pskRaw = "ext:psk_home";
      };

      networking.useDHCP = lib.mkDefault true;
      networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

      networking.networkmanager.enable = lib.mkForce false;

      boot.loader.raspberry-pi = {
        bootloader = "kernel";
        firmwarePath = "/boot";
        configurationLimit = 2;
      };

      sops.secrets."wifi/psk" = { };
      sops.templates."wireless/secrets" = {
        content = ''
          psk_home=${config.sops.placeholder."wifi/psk"}
        '';
        owner = "root";
        group = "root";
        mode = "0400";
      };

      systemd.services.wpa_supplicant = {
        after = [
          "run-secrets.d.mount"
        ];
        requires = [
          "run-secrets.d.mount"
        ];
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-label/FIRMWARE";
          fsType = "vfat";
          options = [
            "nofail"
          ];
        };
      };
    };

  oxygenModules = oxygenAspects ++ [ oxygenInline ];
in
{
  flake.nixosConfigurations.oxygen = inputs.nixos-raspberrypi.lib.nixosSystem {
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
