{ ... }:
{
  flake.modules.homeManager.fzf =
    { ... }:
    {
      programs.fzf = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        defaultCommand = "fd --type f";

        changeDirWidget = {
          command = "fd --type d";
          options = [ "--preview 'tree -C {} | head -200'" ];
        };

        fileWidget = {
          command = "fd --type f";
          options = [
            "--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
          ];
        };

        historyWidget = {
          command = "";
          options = [
            "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
          ];
        };

        tmux = {
          enableShellIntegration = true;
          shellIntegrationOptions = [ "-p80%,60%" ];
        };
      };
    };
}
