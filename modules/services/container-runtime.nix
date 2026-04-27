{ config, lib, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.nixos.container-runtime =
    { ... }:
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };

      virtualisation.oci-containers.backend = "podman";

      users.users.${vars.username}.extraGroups = lib.mkAfter [ "podman" ];
    };
}
