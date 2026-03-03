{ ... }:
{
  flake.modules.homeManager.tmux-session-rename =
    { pkgs, ... }:
    let
      tmux-session-rename = pkgs.writeShellApplication {
        name = "tmux-session-rename";
        runtimeInputs = [ pkgs.tmux ];
        text = builtins.readFile ./session-rename.sh;
      };
    in
    {
      home.packages = [ tmux-session-rename ];
    };
}
