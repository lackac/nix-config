{ ... }:
{
  flake.modules.nixos.disko-nvme = {
    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            start = "1M";
            size = "128M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/rootfs" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };

  flake.modules.nixos.disko-nvme-xbootldr =
    let
      mountpoint = "/boot-payload";
    in
    {
      boot.loader.systemd-boot.xbootldrMountPoint = mountpoint;

      disko.devices.disk.main.content.partitions = {
        root.end = "-1G";
        XBOOTLDR = {
          # Create this after the root partition, whose size "100%" gives it priority 9001.
          priority = 9002;
          size = "1G";
          type = "EA00";
          content = {
            type = "filesystem";
            format = "vfat";
            extraArgs = [
              "-F"
              "32"
            ];
            inherit mountpoint;
            mountOptions = [
              "umask=0077"
              "nofail"
            ];
          };
        };
      };
    };
}
