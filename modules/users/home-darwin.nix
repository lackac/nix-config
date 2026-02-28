{ config, inputs, ... }:
let
  inherit (config) vars;
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
            imports = builtins.attrValues (inputs.self.modules.homeManager or { });

            home = {
              username = vars.username;
              homeDirectory = "/Users/${vars.username}";
              stateVersion = "25.11";
            };
          };
      };
    };
}
