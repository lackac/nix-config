{ ... }:
{
  flake.modules.darwin.games =
    { ... }:
    {
      homebrew.casks = [
        "crossover"
        "curseforge"
        "minecraft"
        "steam"
      ];

      # Factorio has no cask — install manually from factorio.com
    };
}
