{ inputs, ... }:
{
  flake.modules.homeManager.kickstart =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.kickstart.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
