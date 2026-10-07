# nix-config

Personal dendritic Nix flake for macOS and NixOS hosts.

## Quick Start

- Run `just` to see available commands.
- Run `just check` to evaluate and validate the flake.
- Use `just darwin-check <host>` / `just darwin-switch <host>` for macOS hosts.
- Use `just deploy-dry <host>` / `just deploy <host>` for NixOS hosts.
- Use `just provision <host> <ip>` for first-time NixOS provisioning.

See `Justfile` for the full command surface.

## Project Templates

Use `kickstart` to create a Nix, Elixir, or Phoenix project with a pinned Nix shell
and colocated Jujutsu/Git repository. Opt into development tooling with `--agentic`:

```bash
kickstart nix my-project
kickstart elixir my_app --
kickstart phoenix my_app --agentic -- --no-ecto
```

Kickstart is maintained in its own [repository](https://git.lackac.hu/lackac/kickstart).
Its flake input follows this configuration's nixpkgs.

## Local Narration

Apple Silicon Macs include `kokoro-narrate` from CLI toolbox, a local,
Metal-accelerated English narration command. It defaults to Emma's British voice
and writes WAV files. See the
[usage guide](https://git.lackac.hu/lackac/cli-toolbox/src/branch/main/pkgs/kokoro-narrate/README.md)
for voice selection and dependency updates.

## Repo Map

- `modules/`: flake-parts modules (hosts, platform, packages, home, services).
- `secrets/`: encrypted secrets managed by sops-nix.
- `scripts/`: helper scripts used by modules or operational workflows.
- `docs/`: operational documentation (`docs/howto-provision-server.md`, `docs/bootstrap-darwin.md`, `docs/upgrade-runbook.md`).

## Hosts

- `lithium`: primary darwin host.
- `carbon`, `boron`, `oxygen`: NixOS hosts.
