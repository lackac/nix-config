{ ... }:
{
  flake.modules.homeManager.tmux-session-rename =
    { pkgs, ... }:
    let
      terminal-session-name = pkgs.writeShellApplication {
        name = "terminal-session-name";
        text = builtins.readFile ./terminal-session-name.sh;
      };
      tmux-session-rename = pkgs.writeShellApplication {
        name = "tmux-session-rename";
        runtimeInputs = [
          pkgs.tmux
          terminal-session-name
        ];
        text = builtins.readFile ./session-rename.sh;
      };
    in
    {
      home.packages = [
        terminal-session-name
        tmux-session-rename
      ];
    };
}
