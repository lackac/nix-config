{ ... }:
{
  flake.modules.darwin.games =
    { ... }:
    {
      homebrew.casks = [
        "curseforge"
        "minecraft"
        "steam"
      ];

      # Factorio has no cask — install manually from factorio.com
    };
}
