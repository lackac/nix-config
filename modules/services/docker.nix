{ config, lib, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.nixos.docker =
    { pkgs, ... }:
    {
      virtualisation.docker.enable = true;

      environment.systemPackages = [ pkgs.docker-compose ];

      users.users.${vars.username}.extraGroups = lib.mkAfter [ "docker" ];
    };
}
