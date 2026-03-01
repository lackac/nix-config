# nix-config

Personal dendritic Nix flake for macOS and NixOS hosts.

## Quick Start

- Run `just` to see available commands.
- Run `just check` to evaluate and validate the flake.
- Use `just darwin-check <host>` / `just darwin-switch <host>` for macOS hosts.
- Use `just deploy-dry <host>` / `just deploy <host>` for NixOS hosts.
- Use `just provision <host> <ip>` for first-time NixOS provisioning.

See `Justfile` for the full command surface.

## Repo Map

- `modules/`: flake-parts modules (hosts, platform, packages, home, services).
- `secrets/`: encrypted secrets managed by sops-nix.
- `scripts/`: helper scripts used by modules or operational workflows.
- `docs/`: operational documentation (`docs/howto-provision-server.md`).

## Hosts

- `lithium`: primary darwin host.
- `carbon`, `boron`, `neon`, `oxygen`: NixOS hosts.
