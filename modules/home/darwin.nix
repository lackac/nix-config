{ config, inputs, ... }:
let
  inherit (config) vars;
  hmModules = inputs.self.modules.homeManager;
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

        users.${vars.username} =
          { ... }:
          {
            imports = [
              hmModules.shell
              hmModules.cli-tools
              hmModules.tools
            ];

            home = {
              username = vars.username;
              homeDirectory = "/Users/${vars.username}";
              stateVersion = "25.11";
            };
          };
      };
    };
}
