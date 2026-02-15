# Dendritic Nix Configuration Framework

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> **Worktree:** Execute in `/Users/lackac/Code/lackac/nix-config--dendritic` (branch `dendritic`, from inception commit).

**Goal:** Build a unified, dendritic Nix flake managing all hosts (MacBook, Mac Mini, N100 mini PCs) with flake-parts, minimal home-manager, sops-nix secrets, and Colmena deployment.

**Architecture:** A single flake repo where every `.nix` file is a flake-parts module, auto-imported via `import-tree`. Modules define aspects using `flake.modules.<class>.<aspect>` (the idiomatic dendritic pattern with `deferredModule` merge semantics). Hosts compose aspects explicitly. NixOS hosts deploy via Colmena over Tailscale. Darwin hosts build locally. Home-manager is used sparingly for user environment; complex tools are wrapped packages (nvf-config pattern).

**Tech Stack:** NixOS, nix-darwin, flake-parts (`flake.modules`), import-tree, home-manager (minimal), sops-nix, disko, Colmena, Tailscale, Determinate Nix, nix-homebrew, stylix.

---

## Host Inventory

| Hostname | Machine | Arch | OS | Role |
|----------|---------|------|----|------|
| lithium | MacBook | aarch64-darwin | macOS | Daily driver workstation |
| beryllium | Mac Mini M1 8G | aarch64-darwin | macOS | Secondary workstation / proving ground |
| carbon | AWOW N100 mini PC | x86_64-linux | NixOS | Homelab server (Mattermost, Postgres, Daimon, Gitea) |

A second N100 may be added later (hostname TBD).

## Phased Approach

**Phase 1 (this plan):** Scaffold the repo, build carbon (NixOS server) with base system + Tailscale + Mattermost + Postgres. Proves the dendritic pattern end-to-end.

**Phase 2 (future):** Port beryllium (Mac Mini) from current nix-config. Bring over darwin system config, homebrew, user environment, theming.

**Phase 3 (future):** Create lithium (MacBook) config, likely near-identical to beryllium. Back up MacBook, provision from scratch.

**Phase 4 (future):** Add Daimon, Gitea, backup automation, Syncthing, additional services.

---

## Design Decisions

### Dendritic Pattern
Every `.nix` file under `modules/` is a flake-parts module, auto-imported by `import-tree`. Files represent features/aspects, not host boundaries. Directory names are organizational hints only.

### `flake.modules.<class>.<aspect>` Pattern
Modules use flake-parts' `flake.modules` option (from `flake-parts.flakeModules.modules`), which stores NixOS/darwin/home-manager modules as `deferredModule` types. Benefits:
- **Auto-merge:** Multiple files can contribute to the same aspect and they merge.
- **Clean host composition:** `with inputs.self.modules.nixos; [ common server tailscale ... ]`
- **Cross-cutting:** One file can define `flake.modules.nixos.ssh` and `flake.modules.darwin.ssh` and `flake.modules.homeManager.ssh` for the same feature.

### Home-Manager Strategy
Minimal. Used for "set and forget" dotfile placement (shell, git, tmux, starship, terminals) and `home.packages`. No heavy HM module usage. Complex tools get wrapped as packages (nvf-config pattern). Migrate tools to wrappers incrementally.

### Variables as flake-parts Options
Username, SSH keys, email defined once in `modules/vars.nix` as flake-parts options. Accessible via `config.vars.*` in all flake-parts modules. Passed to NixOS/darwin evaluations via `specialArgs`.

### No specialArgs (mostly)
The dendritic pattern avoids `specialArgs` because flake-parts modules share `config` naturally. For NixOS evaluations (which are separate `lib.evalModules` calls), we pass only `inputs` and `vars` via `specialArgs`. Let-bindings and flake-parts options handle all other value sharing.

### Secrets
sops-nix with age encryption. Per-host `.yaml` files in `secrets/`. Age keys derived from host SSH keys.

### Deployment
Colmena for NixOS hosts over Tailscale. nixos-anywhere for initial provisioning. Darwin hosts build locally.

### External to Nix
Hammerspoon config stays outside nix.

---

## Task 1: Initialize flake with dendritic wiring

**Files:**
- Create: `flake.nix`
- Create: `.gitignore`
- Create: `.envrc`
- Create: `modules/_placeholder.nix`

**Step 1:** Create `flake.nix`. Note the import of `flake-parts.flakeModules.modules` which enables the `flake.modules.<class>.<aspect>` option:

```nix
{
  description = "Dendritic Nix configuration for all hosts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

    nvf-config = {
      url = "github:lackac/nvf-config";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ];
    };
}
```

**Step 2:** Create `.gitignore`:

```
result
result-*
.direnv/
```

**Step 3:** Create `.envrc`:

```bash
use flake
watch_file devshell.nix
if [ -f .envrc.local ]; then
  source .envrc.local
fi
```

**Step 4:** Create `modules/_placeholder.nix` (import-tree needs at least one file; remove when real modules exist):

```nix
# Placeholder - remove when real modules exist
{ }
```

**Step 5:** Run `nix flake check` to verify the flake evaluates.

**Step 6:** Commit:

```bash
git add -A
git commit -m "feat: initialize dendritic flake with flake-parts + import-tree"
```

---

## Task 2: Development shell and formatter

**Files:**
- Create: `modules/devshell.nix`
- Create: `modules/formatter.nix`
- Delete: `modules/_placeholder.nix`

**Step 1:** Create `modules/devshell.nix`:

```nix
{ inputs, ... }: {
  perSystem = { pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Nix tools
        nil
        nixfmt-rfc-style

        # Secrets
        age
        sops
        ssh-to-age

        # Deployment
        inputs.colmena.packages.${system}.colmena
        nixos-anywhere
        nixos-rebuild

        # Utilities
        just
        pwgen
      ];
    };
  };
}
```

**Step 2:** Create `modules/formatter.nix`:

```nix
{ ... }: {
  perSystem = { pkgs, ... }: {
    formatter = pkgs.nixfmt-rfc-style;
  };
}
```

**Step 3:** Remove `modules/_placeholder.nix`.

**Step 4:** Run `nix flake check` and `nix develop -c echo "devshell works"`.

**Step 5:** Commit:

```bash
git add -A
git commit -m "feat: add development shell and formatter"
```

---

## Task 3: Common platform base and variables

**Files:**
- Create: `modules/platform/common.nix`
- Create: `modules/vars.nix`

**Step 1:** Create `modules/vars.nix` defining shared variables as flake-parts options:

```nix
{ lib, ... }: {
  options.vars = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "lackac";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Laszlo Bacsi";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "lackac@lackac.hu";
    };
    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINb0PBMOy7MjJoOJSmlQ2FG4deJJd8Gn8IaE+kDJbMYB lackac@lithium"
      ];
      description = "SSH public keys authorized across all hosts";
    };
  };
}
```

Note: Verify SSH key from current nix-config `vars/default.nix` and add additional keys as needed.

**Step 2:** Create `modules/platform/common.nix` using `flake.modules.nixos.common`:

```nix
{ config, ... }:
let
  inherit (config) vars;
in
{
  # NixOS common base
  flake.modules.nixos.common = { pkgs, ... }: {
    nix.settings = {
      trusted-users = [ "@wheel" vars.username ];
      experimental-features = [ "nix-command" "flakes" ];
    };

    environment.systemPackages = with pkgs; [
      git neovim curl wget htop btop fastfetch
      jq ripgrep fd tree rsync just
    ];

    environment.variables.EDITOR = "nvim";

    users.users.${vars.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
```

Note how `vars` is accessed directly from flake-parts `config` via let-binding. No `specialArgs` needed for sharing values between flake-parts modules.

**Step 3:** Run `nix flake check`.

**Step 4:** Commit:

```bash
git add -A
git commit -m "feat: add common platform base and shared variables"
```

---

## Task 4: NixOS server base module

**Files:**
- Create: `modules/platform/nixos-server.nix`

**Step 1:** Create `modules/platform/nixos-server.nix`:

```nix
{ inputs, ... }: {
  flake.modules.nixos.server = { ... }: {
    imports = [
      inputs.srvos.nixosModules.server
      inputs.disko.nixosModules.disko
      inputs.sops-nix.nixosModules.sops
      inputs.determinate.nixosModules.default
    ];

    networking.firewall.enable = true;

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
```

**Step 2:** Run `nix flake check`.

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add NixOS server base module"
```

---

## Task 5: Hardware and disk config for carbon (N100)

**Files:**
- Create: `modules/hardware/n100.nix`
- Create: `modules/hardware/disko-nvme.nix`

**Step 1:** Create `modules/hardware/n100.nix`:

```nix
{ inputs, ... }: {
  flake.modules.nixos.hardware-n100 = { ... }: {
    imports = [
      inputs.nixos-hardware.nixosModules.common-cpu-intel
      inputs.nixos-hardware.nixosModules.common-pc-ssd
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" "sdhci_pci"
    ];
    boot.initrd.kernelModules = [ ];
    boot.kernelModules = [ "kvm-intel" ];
    boot.extraModulePackages = [ ];

    networking.useDHCP = true;
  };
}
```

**Step 2:** Create `modules/hardware/disko-nvme.nix`:

```nix
{ ... }: {
  flake.modules.nixos.disko-nvme = {
    disko.devices.disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            start = "1M";
            size = "128M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "/rootfs" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
```

**Step 3:** Run `nix flake check`.

**Step 4:** Commit:

```bash
git add -A
git commit -m "feat: add N100 hardware and disko config"
```

---

## Task 6: Secrets structure

**Files:**
- Create: `modules/secrets.nix`
- Create: `.sops.yaml`

**Step 1:** Create `.sops.yaml` at repo root (placeholder keys, replace during provisioning):

```yaml
keys:
  - &carbon age1PLACEHOLDER_CARBON_KEY

creation_rules:
  - path_regex: secrets/common\.yaml$
    key_groups:
      - age:
          - *carbon
  - path_regex: secrets/carbon\.yaml$
    key_groups:
      - age:
          - *carbon
```

**Step 2:** Create `modules/secrets.nix`:

```nix
{ ... }: {
  flake.modules.nixos.secrets = {
    sops = {
      defaultSopsFile = null; # Each host sets its own
      age.keyFile = "/var/lib/sops-nix/key.txt";
    };
  };
}
```

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add sops-nix secrets structure"
```

---

## Task 7: Tailscale module

**Files:**
- Create: `modules/networking/tailscale.nix`

**Step 1:** Create `modules/networking/tailscale.nix`:

```nix
{ ... }: {
  flake.modules.nixos.tailscale = { config, ... }: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets."tailscale/authKey".path;
    };

    sops.secrets."tailscale/authKey" = { };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
```

**Step 2:** Run `nix flake check`.

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add Tailscale module for NixOS servers"
```

---

## Task 8: Postgres module

**Files:**
- Create: `modules/services/postgres.nix`

**Step 1:** Create `modules/services/postgres.nix`:

```nix
{ ... }: {
  flake.modules.nixos.postgres = { pkgs, ... }: {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      dataDir = "/var/lib/postgresql/16";
    };
  };
}
```

**Step 2:** Run `nix flake check`.

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add Postgres module"
```

---

## Task 9: Mattermost module

**Files:**
- Create: `modules/services/mattermost.nix`

**Step 1:** Create `modules/services/mattermost.nix`:

```nix
{ ... }: {
  flake.modules.nixos.mattermost = { config, ... }: {
    services.mattermost = {
      enable = true;
      siteUrl = "http://${config.networking.hostName}:8065";
      listenAddress = "0.0.0.0:8065";
      localDatabaseCreate = true;
      mutableConfig = false;

      extraConfig = {
        ServiceSettings.ListenAddress = ":8065";
        FileSettings.Directory = "/var/lib/mattermost/files";
      };
    };

    networking.firewall.interfaces."tailscale0" = {
      allowedTCPPorts = [ 8065 ];
    };
  };
}
```

Note: Verify `services.mattermost` NixOS module options during implementation.

**Step 2:** Run `nix flake check`.

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add Mattermost module"
```

---

## Task 10: Carbon host declaration

**Files:**
- Create: `modules/hosts/carbon.nix`

**Step 1:** Create `modules/hosts/carbon.nix` composing aspects:

```nix
{ config, inputs, ... }: {
  flake.nixosConfigurations.carbon =
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        (with inputs.self.modules.nixos; [
          # Platform bases
          common
          server
          secrets

          # Hardware
          hardware-n100
          disko-nvme

          # Features
          tailscale
          postgres
          mattermost
        ])
        ++ [
          # Host-specific inline config
          {
            networking.hostName = "carbon";
            system.stateVersion = "25.11";
            sops.defaultSopsFile = ../../secrets/carbon.yaml;
          }
        ];

      specialArgs = {
        inherit inputs;
        inherit (config) vars;
      };
    };
}
```

Note the clean `with inputs.self.modules.nixos; [ ... ]` composition. The `specialArgs` bridge is needed only here because `nixosSystem` creates a separate module evaluation.

**Step 2:** Run `nix flake check`. First full NixOS evaluation. Fix any issues.

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add carbon host declaration (N100 Mattermost server)"
```

---

## Task 11: Colmena deployment config

**Files:**
- Create: `modules/deploy.nix`

**Step 1:** Create `modules/deploy.nix`. Colmena can share modules with nixosConfigurations:

```nix
{ config, inputs, ... }: {
  flake.colmena = {
    meta = {
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
      };
      specialArgs = {
        inherit inputs;
        inherit (config) vars;
      };
    };

    carbon = {
      deployment = {
        targetHost = "carbon"; # Tailscale hostname
        targetUser = "root";
        allowLocalDeployment = false;
      };

      imports =
        (with inputs.self.modules.nixos; [
          common server secrets hardware-n100 disko-nvme
          tailscale postgres mattermost
        ]);

      networking.hostName = "carbon";
      system.stateVersion = "25.11";
      sops.defaultSopsFile = ./secrets/carbon.yaml;
    };
  };
}
```

Note: Module list is duplicated from the host declaration. Consider extracting a shared list to a let-binding in a future refactor. The exact Colmena + flake-parts wiring may need adjustment during implementation.

**Step 2:** Run `nix flake check` and `colmena eval` (from devshell).

**Step 3:** Commit:

```bash
git add -A
git commit -m "feat: add Colmena deployment configuration"
```

---

## Task 12: Justfile

**Files:**
- Create: `Justfile`

**Step 1:** Create `Justfile`:

```just
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
  nixos-anywhere --flake .#{{host}} root@{{ip}}
```

**Step 2:** Commit:

```bash
git add -A
git commit -m "feat: add Justfile with common commands"
```

---

## Task 13: Validate and test

**Step 1:** `nix flake check` passes.

**Step 2:** `nix build .#nixosConfigurations.carbon.config.system.build.toplevel` succeeds.

**Step 3:** Provision target with `nixos-anywhere --flake .#carbon root@<ip>`.

**Step 4:** Generate age key from host SSH key, update `.sops.yaml`, create secrets, redeploy.

**Step 5:** Verify Mattermost at `http://carbon:8065` over Tailscale.

**Step 6:** Commit any fixes.

---

## Open Details

1. **Age keys:** Generate during provisioning, update `.sops.yaml`.
2. **Tailscale auth key:** Create reusable key in admin console, encrypt with sops.
3. **Colmena wiring:** May need adjustment. Consider extracting shared module lists.
4. **Mattermost options:** Verify NixOS module options during implementation.
5. **Determinate + srvos conflicts:** Test nix daemon settings.
6. **`flake-parts.flakeModules.modules`:** Verify this is the correct import path for enabling `flake.modules` option. Check flake-parts docs.
7. **NAS mount:** Deferred to Phase 4.

## Future Phases

- Port beryllium darwin config (homebrew, system defaults, user env)
- Add `flake.modules.darwin.*` aspects for darwin hosts
- Add `flake.modules.homeManager.*` aspects for user environment
- Add nix-homebrew integration
- Add stylix theming
- Wrap terminals as packages (wrapper-manager)
- Backup automation
- Gitea, Daimon, Syncthing services
- lithium MacBook config
- Consider dendrix/flake-aspects when module count grows
