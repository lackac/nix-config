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
        opencode
        tmux
        tealdeer
        yazi
        zoxide
      ];
    };
}
