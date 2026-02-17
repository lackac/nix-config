{
  config,
  inputs,
  lib,
  ...
}:
let
  targetSystem = "x86_64-linux";
in
{
  options.flake.colmena = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Colmena hive configuration merged from host modules.";
  };

  config.flake.colmena.meta = {
    nixpkgs = import inputs.nixpkgs {
      system = targetSystem;
    };
    specialArgs = {
      inherit inputs;
      inherit (config) vars;
    };
  };

  config.flake.colmenaHive = inputs.colmena.lib.makeHive config.flake.colmena;
}
