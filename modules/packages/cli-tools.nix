{ ... }:
{
  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        btop
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

        gnupg
        gnumake

        bc
        gcal
        ipcalc
        units
        watch

        nix-output-monitor
        nix-init
        nix-melt
        nix-tree

        imagemagick
        pngpaste

        awscli2
        croc
        hunspell
      ];
    };
}
