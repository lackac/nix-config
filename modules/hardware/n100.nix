{ inputs, ... }: {
  flake.modules.nixos.hardware-n100 = { ... }: {
    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-pc-ssd
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sdhci_pci"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    networking.useDHCP = true;
  };
}
