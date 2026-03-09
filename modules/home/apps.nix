{ config, ... }:
let
  hmModules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.apps =
    { ... }:
    {
      imports = with hmModules; [
        kitty
      ];
    };
}
