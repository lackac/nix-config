{ inputs, ... }:
{
  flake.modules.nixos.hardware-rpi4 =
    { lib, ... }:
    {
      imports = [
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ];

      boot.loader.grub.enable = false;
      boot.loader.generic-extlinux-compatible.enable = lib.mkDefault true;

      hardware.enableRedistributableFirmware = true;

      networking.useDHCP = lib.mkDefault true;
    };
}
