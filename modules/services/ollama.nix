{ config, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.darwin.ollama = {
    home-manager.users.${vars.username}.imports = [
      config.flake.modules.homeManager.ollama
    ];
  };

  flake.modules.homeManager.ollama =
    { ... }:
    {
      services.ollama.enable = true;
    };
}
