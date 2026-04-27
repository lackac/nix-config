{ config, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.nixos.mc =
    { ... }:
    {
      users.users.mc = {
        isNormalUser = true;
        extraGroups = [ "podman" ];
        openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
      };
    };
}
