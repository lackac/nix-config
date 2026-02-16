default:
  @just --list

fmt:
  nix fmt

check:
  nix flake check

up:
  nix flake update

upp input:
  nix flake update {{input}}

deploy-carbon:
  colmena apply --on carbon

deploy-all:
  colmena apply

build-carbon:
  nix build .#nixosConfigurations.carbon.config.system.build.toplevel

provision host ip:
  nix run nixpkgs#nixos-anywhere -- --flake .#{{host}} root@{{ip}}
