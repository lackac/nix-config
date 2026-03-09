{ flake-parts-lib, lib, ... }:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  inherit (lib)
    literalExpression
    mkOption
    types
    ;
in
{
  options = {
    flake = mkSubmoduleOptions {
      darwinConfigurations = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = { };
        description = ''
          Instantiated nix-darwin configurations. Used by `darwin-rebuild`.

          `darwinConfigurations` is for specific machines. If you want to expose
          reusable configurations, add them to `flake.modules.darwin` as modules,
          then reference them from these host definitions.
        '';
        example = literalExpression ''
          {
            my-mac = inputs.nix-darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = [ ./darwin-configuration.nix ];
            };
          }
        '';
      };
    };
  };
}
