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
    {
      config,
      lib,
      ...
    }:
    let
      ollamaStateDir = "${config.xdg.stateHome}/ollama";
    in
    {
      services.ollama = {
        enable = true;
        host = "127.0.0.1";
        environmentVariables = {
          OLLAMA_MODELS = "${ollamaStateDir}/models";
          HOME = "${ollamaStateDir}/home";
        };
      };

      launchd.agents.ollama.config = {
        StandardOutPath = "${ollamaStateDir}/stdout.log";
        StandardErrorPath = "${ollamaStateDir}/stderr.log";
      };

      home.activation.ollama-state = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "${ollamaStateDir}/models" "${ollamaStateDir}/home"
      '';
    };
}
