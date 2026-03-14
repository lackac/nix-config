{ inputs, ... }:
{
  flake.modules.homeManager.cli-toolbox =
    { pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      cli-toolbox = inputs.cli-toolbox.packages.${system};
    in
    {
      home.packages = with cli-toolbox; [
        acsm2epub
        boox2readwise
        nerd-fonts
        xpwgen
      ];
    };
}
