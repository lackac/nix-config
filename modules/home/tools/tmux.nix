{ config, ... }:
let
  hmModules = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.tmux =
    { ... }:
    {
      imports = with hmModules; [
        tmux-core
        tmux-statusline
        tmux-sesh
        tmux-opencode-session
        tmux-session-rename
        tmux-autostart
      ];
    };
}
