# Agent Guidelines for Nix Configuration (Dendritic)

## Overview

This is a dendritic Nix flake managing all personal hosts (macOS and NixOS).
Every `.nix` file under `modules/` is a flake-parts module, auto-imported via
`import-tree`. Plans live as drafts in `.opencode/plans/` (gitignored) during
brainstorming and execution. Long-lived operational guidance belongs in
`README.md` and focused docs under `docs/`.

## Architecture

- **Pattern:** Dendritic (flake-parts + import-tree). Every file is a
  flake-parts module.
- **Import-tree reminder:** New `.nix` files under `modules/` must be tracked by
  git before flake evaluation can see them. Untracked files are not part of the
  git-backed flake source snapshot.
- **Hosts:** carbon (NixOS/x86_64, N100 server), boron (NixOS/x86_64, N100
  server), beryllium (darwin/aarch64, Mac Mini), lithium (darwin/aarch64,
  MacBook)
- **Home-manager:** Primary user-level shell and tool configuration via
  `programs.*` and `home.packages`.
- **Secrets:** sops-nix with age encryption. Keys in `.sops.yaml`, secrets in
  `secrets/`.
- **Deployment:** Colmena for NixOS (build-on-target by default), local build
  for darwin.
- **Nix:** Determinate Nix across all hosts.

## Build/Test Commands

- `just` - List all available commands
- `just fmt` - Format all Nix files
- `just check` - Run `nix flake check`
- `just build <host>` - Build host profile via Colmena on target
- `just deploy-dry <host>` - Dry-run deploy via Colmena on target
- `just deploy <host>` - Apply deploy via Colmena on target
- `just deploy-all` - Deploy all NixOS hosts via Colmena on target
- `just provision <host> <ip>` - Initial provisioning via nixos-anywhere

## Code Style

- Use 2-space indentation
- Function parameters: `{ param1, param2, ... }:` with ellipsis
- File structure: every file is a flake-parts module (same type everywhere)
- Use `inherit` for passing through parameters, `let...in` for local bindings
- Attribute sets: one attribute per line
- String interpolation: `${variable}`, prefer double quotes
- Naming: kebab-case for file and attribute names, camelCase for functions
- Prefer dashed aspect names for flake modules (for example
  `flake.modules.homeManager.cli-toolbox`) and use the same dashed name when
  importing them from `config.flake.modules.*`.
- Nix files define features, not hosts or module types. A file may contribute
  NixOS, darwin, and home-manager modules.
- For shell helper scripts longer than ~15 lines, keep script content in a
  separate `.sh` file and reference it from Nix (for example with
  `builtins.readFile`).
- When an aspect needs tracked support files (for example ignore files,
  templates, or helper assets), keep them adjacent to the aspect instead of in
  a generic top-level `files/` directory unless the asset is truly shared. A
  single nearby file is fine; if an aspect grows multiple support files, prefer
  a dedicated adjacent directory and keep the filenames specific enough to
  distinguish them.

## Commit Message Style

- Follow Conventional Commits.
- Prefer natural, intent-first summaries over mechanical verbs.
- Avoid defaulting to "add", "remove", or "update" when a more specific verb
  explains the change better (for example: "enable", "align", "wire", "route",
  "consolidate", "harden").
- Describe why the change matters, not just what file changed.
- Keep subject lines concise and readable out loud.

## Module Pattern

Every file follows this pattern, using `flake.modules.<class>.<aspect>` (the
idiomatic dendritic pattern with `deferredModule` merge semantics):

```nix
# A flake-parts module defining the "tailscale" aspect
{ ... }: {
  # NixOS module for this aspect
  flake.modules.nixos.tailscale = { config, ... }: {
    services.tailscale.enable = true;
  };

  # Darwin module for the same aspect
  flake.modules.darwin.tailscale = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.tailscale ];
  };

  # Home-manager module for the same aspect
  flake.modules.homeManager.tailscale = { ... }: {
    # user-level tailscale config
  };

  # Or perSystem for packages/devshells
  perSystem = { pkgs, ... }: { };
}
```

Host declarations compose aspects explicitly:

```nix
{ config, inputs, ... }: {
  flake.nixosConfigurations.carbon =
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = with inputs.self.modules.nixos; [
        common server tailscale postgres mattermost
      ];
      specialArgs = {
        inherit inputs;
        inherit (config) vars;
      };
    };
}
```

Multiple files can contribute to the same aspect and they auto-merge via
`deferredModule`. Avoid `specialArgs` for sharing values between flake-parts
modules; use `config.vars.*` or let-bindings instead. `specialArgs` is only
needed at the NixOS/darwin evaluation boundary to pass `inputs` and `vars`.

## Key Inputs

| Input          | Purpose                         |
| -------------- | ------------------------------- |
| flake-parts    | Top-level module system         |
| import-tree    | Auto-import all .nix files      |
| nix-darwin     | macOS system management         |
| home-manager   | User environment (minimal)      |
| sops-nix       | Secrets management              |
| disko          | Declarative disk partitioning   |
| colmena        | Multi-host NixOS deployment     |
| srvos          | Server-oriented NixOS defaults  |
| nixos-hardware | Hardware quirks                 |
| determinate    | Determinate Nix integration     |
| nvf-config     | Wrapped Neovim (external flake) |

## Shared Variables

Defined in `modules/vars.nix` as flake-parts options:

- `config.vars.username` - "lackac"
- `config.vars.fullName` - "Laszlo Bacsi"
- `config.vars.email` - "lackac@lackac.hu"
- `config.vars.sshAuthorizedKeys` - SSH public keys

Passed to NixOS/darwin evaluations via `specialArgs`.

## Project Tracking

**Forgejo is the source of truth for this repo.**

- Use `fj` / `forgejo-cli` for issues, PRs, milestones, labels, and wiki work in
  this repository.
- Do not use `gh` for tracker operations here unless the user explicitly asks
  for GitHub.
- Treat GitHub as a mirror/secondary remote; treat Forgejo as authoritative.

Primary backlog tracking for this repo lives in the Forgejo issue tracker, not in
local plan files.

- Use Forgejo issues as the source of truth for follow-up work, migration gaps,
  and deferred decisions.
- Use milestones to group work by migration phase:
  - `Beryllium smoke test`
  - `Lithium rebuild`
  - `Post-migration cleanup`
- Use labels consistently:
  - `area/*` for subsystem (`area/darwin`, `area/bootstrap`, `area/apps`,
    `area/networking`, `area/docs`)
  - `type/*` for work kind (`type/feature`, `type/task`, `type/research`)
  - `host/*` for host-specific work (`host/beryllium`, `host/lithium`)
- When new work is discovered during implementation or migration, create or
  update an issue instead of relying on ad-hoc local notes.
- Keep public repo docs concise; put fast-changing operational notes either in
  Forgejo wiki pages or issues, depending on whether they are durable reference or
  active backlog.
