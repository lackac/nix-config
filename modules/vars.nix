{ lib, ... }:
{
  options.vars = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "lackac";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Laszlo Bacsi";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "lackac@lackac.hu";
    };
    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdW8eys/HTknDK+eMcAjeiITC+T7uDGbpaUNydsj7PZ lackac@lithium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHaQrG9nHmEMUPjd+Z3WMno7qV/QH0wA5K6hPeqDbOwx root@lithium"
      ];
      description = "SSH public keys authorized across all hosts";
    };
    syncthing = lib.mkOption {
      type = lib.types.submodule {
        options.deviceIds = lib.mkOption {
          type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
          default = {
            lithium = "2L6H23G-BR2UAGL-D4UAEGE-4C2RYN5-BIOVRPW-CSJNUY3-OPKCRS6-43CICAO";
            beryllium = "KZ3VUZ7-YXF26WY-RGF5JK6-UYDSK56-RXERZRJ-7TARP2Z-ROKIHEP-2PGWSAQ";
          };
          description = ''
            Stable Syncthing device IDs by host name. Keep a host at null until
            its real device ID is known and should be managed here.
          '';
        };
      };
      default = { };
      description = "Shared Syncthing facts reused across hosts.";
    };
  };
}
