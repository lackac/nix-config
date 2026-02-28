{ ... }:
{
  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        doggo
        duf
        gdu
        ncdu
        fd
        jq
        just
        ripgrep
        sad
        yq-go

        btop

        gcal
        gnupg
        gnumake

        nix-output-monitor
        nix-init
        nix-melt
        nix-tree

        croc
      ];
    };
}
