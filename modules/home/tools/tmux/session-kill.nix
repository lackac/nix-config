{ ... }:
{
  flake.modules.homeManager.tmux-session-kill =
    { pkgs, ... }:
    let
      tmux-session-kill = pkgs.writeShellApplication {
        name = "tmux-session-kill";
        runtimeInputs = [ pkgs.tmux ];
        text = builtins.readFile ./session-kill.sh;
      };
    in
    {
      home.packages = [ tmux-session-kill ];
    };
}
