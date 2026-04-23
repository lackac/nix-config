{ config, ... }:
let
  hmModules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.tools =
    { ... }:
    {
      imports = with hmModules; [
        starship
        atuin
        bat
        cli-toolbox
        direnv
        eza
        fzf
        git
        neovim
        opencode
        ssh
        tmux
        tealdeer
        units
        yazi
        zoxide
      ];
    };
}
