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
        changeDirWidgetCommand = "fd --type d";
        changeDirWidgetOptions = [ "--preview 'tree -C {} | head -200'" ];
        fileWidgetCommand = "fd --type f";
        fileWidgetOptions = [
          "--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
        ];
        historyWidgetOptions = [
          "--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
        ];

        tmux = {
          enableShellIntegration = true;
          shellIntegrationOptions = [ "-p80%,60%" ];
        };
      };
    };
}
