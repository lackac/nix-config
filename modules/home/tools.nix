{ inputs, ... }:
let
  hmModules = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager.tools =
    { ... }:
    {
      imports = with hmModules; [
        starship
        atuin
        bat
        eza
        fzf
        git
        tealdeer
        yazi
        zoxide
      ];
    };
}
