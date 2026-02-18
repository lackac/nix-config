# How To Provision and Deploy a NixOS Host

This guide is host-agnostic. It covers first provisioning, `sops-nix` bootstrap, and day-2 remote deployments from this repo.

## 1) Prerequisites

- You can reach the target host over SSH as `root` (or have local console fallback).
- The host config in this repo matches the hardware and disk layout.
- You can decrypt required secrets locally.
- `vars.sshAuthorizedKeys` contains at least one key you control.

Quick secret checks:

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops -d secrets/common.yaml >/dev/null
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt" sops -d secrets/<host>.yaml >/dev/null
```

## 2) Prepare the host age key (critical)

Generate a dedicated age key for the new host:

```bash
mkdir -p "$HOME/.config/sops/age"
age-keygen -o "$HOME/.config/sops/age/<host>-key.txt"
age-keygen -y "$HOME/.config/sops/age/<host>-key.txt"
```

Add the public key to `.sops.yaml` recipients for files the host must decrypt (typically `secrets/common.yaml` and `secrets/<host>.yaml`), then update recipients:

```bash
sops updatekeys secrets/common.yaml
sops updatekeys secrets/<host>.yaml
```

Verify decryption with the same key you will install on the host:

```bash
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/<host>-key.txt" sops -d secrets/common.yaml >/dev/null
SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/<host>-key.txt" sops -d secrets/<host>.yaml >/dev/null
```

## 3) Provision with nixos-anywhere

From repo root:

```bash
just provision <host> <ip>
```

Equivalent command:

```bash
nix run nixpkgs#nixos-anywhere -- --flake .#<host> root@<ip>
```

Note: provisioning is destructive to the target disk.

For installer-style images where SSH starts as `nixos` + password (for example a UTM VM), use `--target-host` and `--env-password`:

```bash
SSHPASS='<installer-password>' nix run nixpkgs#nixos-anywhere -- \
  --env-password \
  --target-host nixos@<ip> \
  --flake .#<host>
```

## 4) First login checks

```bash
ssh <user>@<ip>
hostnamectl --static
nixos-version
```

If SSH fails after install, recover via console, fix `vars.sshAuthorizedKeys`, then reinstall or switch declaratively.

## 5) Bootstrap sops key on the host (critical)

Install the exact same key from step 2:

```bash
ssh <user>@<ip> 'sudo install -d -m 0700 /var/lib/sops-nix'
scp ~/.config/sops/age/<host>-key.txt <user>@<ip>:/tmp/age-key.txt
ssh <user>@<ip> 'sudo install -m 0400 /tmp/age-key.txt /var/lib/sops-nix/key.txt && rm -f /tmp/age-key.txt'
```

Verify:

```bash
ssh <user>@<ip> 'sudo ls -l /var/lib/sops-nix/key.txt'
```

## 6) Day-2 remote deployment flow (preferred)

This repo uses Colmena with build-on-target by default.

Dry-run first:

```bash
just deploy-dry <host>
```

Apply:

```bash
just deploy <host>
```

Optional (build only on target):

```bash
just build <host>
```

## 7) Post-deploy validation

```bash
ssh <user>@<ip> 'hostnamectl --static; nixos-version'
ssh <user>@<ip> 'readlink -f /run/current-system'
ssh <user>@<ip> 'sudo ls -l /run/secrets || true'
ssh <user>@<ip> 'findmnt -T /; findmnt -T /home; findmnt -T /nix; findmnt -T /boot'
```

Example service check (if the host includes Tailscale):

```bash
ssh <user>@<ip> 'systemctl is-active tailscaled && tailscale status --self'
```

## 8) Reboot persistence check

```bash
ssh <user>@<ip> 'sudo reboot'
```

After the host returns:

```bash
ssh <user>@<ip> 'hostnamectl --static'
ssh <user>@<ip> 'readlink -f /run/current-system'
ssh <user>@<ip> 'findmnt -T /boot'
```

## 9) Fallback path (if Colmena is unavailable)

Apply directly on the host with a local checkout:

```bash
sudo nixos-rebuild switch --flake <repo-path-or-url>#<host>
```

## 10) Fast triage

- SSH lockout: fix `vars.sshAuthorizedKeys`, then redeploy or reinstall.
- Secrets missing: verify `/var/lib/sops-nix/key.txt` and decryption recipients in `.sops.yaml`.
- Boot update failures: check `/boot` free space and mounted ESP.
- Host mismatch prompt: confirm the expected `networking.hostName` before switching.

## 11) On-demand UTM ARM builder workflow

Use `neon` as an on-demand `aarch64-linux` builder host. Keep the VM powered off by default, then start it only for ARM image builds.

1. Start the UTM VM manually (for example, VM name `neon`) and wait for networking.
2. Probe remote builder readiness, then build the oxygen SD image:

```bash
just check-builder
just build-sd-image-oxygen
# If DHCP changes the VM IP:
just check-builder builder=<new-ip>
just build-sd-image-oxygen builder=<new-ip>
```

3. Flash the resulting image from `result/sd-image/*.img.zst`.
4. Shut down the builder VM manually when done.

macOS daemon SSH requirement:

- `nix build --builders ...` uses the local Nix daemon, not your interactive shell user.
- Ensure the macOS root user can authenticate to the VM over SSH with keys.
- Ensure the builder host key is trusted for the daemon context as well.
- If this is missing, builds can fail with `Permission denied (publickey)` even when regular user SSH works.

When provisioning `neon` via installer ISO in UTM, detach the installer ISO before the first reboot after `nixos-anywhere`. If the ISO remains first in boot order, the VM returns to the installer environment and your deployed SSH keys/user are not used.
