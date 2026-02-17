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

deploy-boron:
  colmena apply --on boron --build-on-target

deploy-all:
  colmena apply

build-carbon:
  nix build .#nixosConfigurations.carbon.config.system.build.toplevel

build-boron:
  nix build .#nixosConfigurations.boron.config.system.build.toplevel

provision host ip:
  nix run nixpkgs#nixos-anywhere -- --flake .#{{host}} root@{{ip}}
