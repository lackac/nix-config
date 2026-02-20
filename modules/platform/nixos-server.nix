{ inputs, ... }:
{
  flake.modules.nixos.server =
    { ... }:
    {
      imports = [
        inputs.srvos.nixosModules.server
        inputs.disko.nixosModules.disko
        inputs.sops-nix.nixosModules.sops
        inputs.determinate.nixosModules.default
      ];

      networking.firewall.enable = true;

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
}
