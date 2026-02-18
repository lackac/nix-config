{
  config,
  inputs,
  lib,
  ...
}:
let
  targetSystem = "x86_64-linux";

  nodeNixpkgs = lib.mapAttrs (
    _: system:
    import inputs.nixpkgs {
      inherit system;
    }
  ) config.colmenaNodeSystems;

  sharedSshOptions = [
    "-o"
    "ControlMaster=no"
    "-o"
    "ControlPath=none"
  ];

  effectiveColmena = lib.mapAttrs (
    name: node:
    if name == "meta" then
      node
    else
      node
      // {
        deployment = (node.deployment or { }) // {
          sshOptions = (node.deployment.sshOptions or [ ]) ++ sharedSshOptions;
        };
      }
  ) config.flake.colmena;
in
{
  options.flake.colmena = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Colmena hive configuration merged from host modules.";
  };

  options.colmenaNodeSystems = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = { };
    description = "Node to nixpkgs system mapping used to build Colmena nodeNixpkgs.";
  };

  config.flake.colmena.meta = {
    nixpkgs = import inputs.nixpkgs {
      system = targetSystem;
    };
    nodeNixpkgs = nodeNixpkgs;
    specialArgs = {
      inherit inputs;
      inherit (config) vars;
    };
  };

  config.flake.colmenaHive = inputs.colmena.lib.makeHive effectiveColmena;
}
