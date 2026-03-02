{ inputs, ... }:
let
  hmModules = inputs.self.modules.homeManager;
in
{
  flake.modules.homeManager.tmux =
    { ... }:
    {
      imports = with hmModules; [
        tmux-core
        tmux-statusline
        tmux-sesh
        tmux-autostart
      ];
    };
}
