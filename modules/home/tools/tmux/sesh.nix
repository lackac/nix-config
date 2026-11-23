{ ... }:
{
  flake.modules.homeManager.tmux-sesh =
    { lib, pkgs, ... }:
    {
      programs.sesh = {
        enable = true;
        enableAlias = true;
        enableTmuxIntegration = false;

        settings = {
          default_session = {
            preview_command = "tree -L 1 -C --dirsfirst -a {}";
            startup_command = "tmux rename-window ' 󰻹 󰚩'; tmux new-window -n '󰞷'; tmux select-window -t ' 󰻹 󰚩'; tmux-session-rename || true; clear; exec env START_OPENCODE=1 ${lib.getExe pkgs.zsh} -il";
          };

          session = [
            {
              name = "main";
              path = "~";
              startup_command = "tmux rename-window '󰞷'; clear; exec $SHELL -i";
            }
          ];
        };
      };
    };
}
