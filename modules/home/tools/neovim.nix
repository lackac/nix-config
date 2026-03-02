{ inputs, ... }:
{
  flake.modules.homeManager.neovim =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.nvf-config.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
