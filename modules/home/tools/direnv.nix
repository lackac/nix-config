{ ... }:
{
  flake.modules.homeManager.direnv =
    { ... }:
    {
      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        silent = true;
        nix-direnv.enable = true;
      };
    };
}
