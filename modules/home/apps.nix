{ inputs, ... }:
let
  hmModules = inputs.self.modules.homeManager;
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
