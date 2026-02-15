# Agent Guidelines for Nix Configuration (Dendritic)

## Overview

This is a dendritic Nix flake managing all personal hosts (macOS and NixOS).
Every `.nix` file under `modules/` is a flake-parts module, auto-imported via
`import-tree`. See `docs/plans/` for implementation plans.

## Architecture

- **Pattern:** Dendritic (flake-parts + import-tree). Every file is a
  flake-parts module.
- **Hosts:** carbon (NixOS/x86_64, N100 server), beryllium (darwin/aarch64, Mac
  Mini), lithium (darwin/aarch64, MacBook)
- **Home-manager:** Minimal - dotfile placement and `home.packages` only. Prefer
  wrapping for complex tools.
- **Secrets:** sops-nix with age encryption. Keys in `.sops.yaml`, secrets in
  `secrets/`.
- **Deployment:** Colmena for NixOS, local build for darwin.
- **Nix:** Determinate Nix across all hosts.

## Build/Test Commands

- `just` - List all available commands
- `just fmt` - Format all Nix files
- `just check` - Run `nix flake check`
- `just build-carbon` - Build carbon NixOS config locally
- `just deploy-carbon` - Deploy to carbon via Colmena
- `just deploy-all` - Deploy to all NixOS hosts
- `just provision <host> <ip>` - Initial provisioning via nixos-anywhere
- `nix flake check` - Validate flake configuration

## Code Style

- Use 2-space indentation
- Function parameters: `{ param1, param2, ... }:` with ellipsis
- File structure: every file is a flake-parts module (same type everywhere)
- Use `inherit` for passing through parameters, `let...in` for local bindings
- Attribute sets: one attribute per line
- String interpolation: `${variable}`, prefer double quotes
- Naming: kebab-case for file and attribute names, camelCase for functions
- Nix files define features, not hosts or module types. A file may contribute
  NixOS, darwin, and home-manager modules.

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
