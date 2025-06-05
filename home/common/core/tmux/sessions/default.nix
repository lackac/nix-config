{mylib, ...}:
{
  imports = mylib.scanPaths ./.;

  programs.sesh = {
    enable = true;
    enableAlias = true;
    tmuxKey = ";";

    settings = {
      default_session = {
        startup_command = "tmux rename-window ''; tmux send-keys 'nvim' Enter";
        preview_command = "tree -L 1 -C --dirsfirst -a {}";
      };

      window = [
        {
          name = "";
          startup_script = "nvim";
        }
        {
          name = "󰊢";
          startup_script = "lazygit";
        }
      ];
    };
  };
}
