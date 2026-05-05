{ config, inputs, ... }:
let
  inherit (config) vars;
  hmModules = config.flake.modules.homeManager;
in
{
  flake.modules.darwin.home =
    { ... }:
    {
      imports = [ inputs.home-manager.darwinModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;

        extraSpecialArgs = {
          inherit inputs;
          inherit (config) vars;
        };

        sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

        users.${vars.username} =
          { config, ... }:
          {
            imports = [
              hmModules.shell
              hmModules.cli-tools
              hmModules.apps
              hmModules.darwin-desktop
              hmModules.hammerspoon
              hmModules.syncthing
              hmModules.tools
            ];

            home = {
              username = vars.username;
              homeDirectory = "/Users/${vars.username}";
              stateVersion = "25.11";
            };

            sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          };
      };
    };
}
