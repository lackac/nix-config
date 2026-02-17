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
        extraGroups = [ "docker" ];
        openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
      };
    };
}
