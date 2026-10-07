{ inputs, ... }:
{
  flake.modules.homeManager.cli-toolbox =
    { lib, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      cli-toolbox = inputs.cli-toolbox.packages.${system};
    in
    {
      home.packages =
        with cli-toolbox;
        [
          acsm2epub
          boox2readwise
          nerd-fonts
          xpwgen
        ]
        ++ lib.optionals (system == "aarch64-darwin") [ kokoro-narrate ];
    };
}
