{ ... }:
{
  flake.modules.homeManager.tmux-opencode-session =
    { pkgs, ... }:
    let
      opencode-session = pkgs.writeShellApplication {
        name = "opencode-session";
        runtimeInputs = with pkgs; [
          git
          lsof
          tmux
        ];
        text = builtins.readFile ./opencode-session.sh;
      };
    in
    {
      home.packages = [ opencode-session ];
    };
}
