{ ... }:
{
  flake.modules.homeManager.tmux-sesh =
    { ... }:
    {
      programs.sesh = {
        enable = true;
        enableAlias = true;
        tmuxKey = ";";

        settings = {
          default_session = {
            preview_command = "tree -L 1 -C --dirsfirst -a {}";
            startup_command = "tmux rename-window ' 󰻹 󰚩'; tmux new-window -n '󰞷'; tmux select-window -t ' 󰻹 󰚩'; tmux-session-rename || true; clear; opencode-session";
          };

          session = [
            {
              name = "main";
              path = "~";
              startup_command = "tmux rename-window '󰞷'; tmux new-window -n '' 'btop'; tmux select-window -t '󰞷'; clear";
            }
          ];
        };
      };
    };
}
