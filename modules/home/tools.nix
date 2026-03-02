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
        direnv
        eza
        fzf
        git
        neovim
        tmux
        tealdeer
        yazi
        zoxide
      ];
    };
}
