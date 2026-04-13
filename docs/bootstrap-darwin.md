# Bootstrap a new Mac (lithium / darwin)

Step-by-step guide to reproduce the full environment on a fresh macOS installation.

______________________________________________________________________

## 1. Install Determinate Nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

Restart your shell to pick up the Nix environment.

On a fresh machine, add your login user to Determinate Nix's trusted users
before the first flake evaluation. Edit `/etc/nix/nix.custom.conf` and add:

```ini
extra-trusted-users = lackac
```

Then restart the Determinate Nix daemon so it picks up the new setting:

```sh
sudo launchctl kickstart -k system/systems.determinate.nix-daemon
```

______________________________________________________________________

## 2. Clone this repo

```sh
git clone git@github.com:lackac/nix-config.git ~/Code/lackac/nix-config
cd ~/Code/lackac/nix-config
```

______________________________________________________________________

## 3. Install Xcode Command Line Tools

Homebrew cask activation still expects Apple developer tools to be present on a
fresh macOS system.

```sh
xcode-select --install
```

Wait for the installation to finish before the first `darwin-switch`.

______________________________________________________________________

## 4. App Store login (required for MAS apps)

Homebrew's `mas` cannot install App Store apps without an active App Store
session.

1. Open the App Store and sign in with your Apple ID.

If you skip this, `darwin-switch` may fail during Homebrew Bundle when
`masApps` are applied.

______________________________________________________________________

## 5. Bootstrap the sops age key (optional, before switch)

Only needed if this host consumes sops secrets during activation.

For `lithium` today, this step can be skipped on first switch.

If needed, place the key at:

```sh
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops/age
# write/copy key to ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Trusted channels for obtaining the key:

- 1Password CLI (`op read ...`)
- 1Password desktop/mobile app (manual copy)
- iCloud Keychain-backed secure storage (if you keep a copy there)
- offline encrypted backup (USB/disk)

If you ever need to generate/rotate a key, do it on an already trusted existing
device first, store it in your secret manager, then bootstrap new machines from
that stored key.

______________________________________________________________________

## 6. Run the first darwin-switch

```sh
nix run nix-darwin -- switch --flake .#lithium
```

This installs nix-darwin, home-manager, Homebrew (via nix-homebrew), and all
declared packages (including 1Password and 1Password CLI via the `onePassword`
aspect).

Before continuing, finish the two interactive setups that later bootstrap steps
depend on:

- 1Password — sign in to the relevant accounts and confirm any SSH integration you intend to use on this host
- Tailscale — sign in and join the tailnet

______________________________________________________________________

## 7. Optional: configure NextDNS on lithium

`lithium` installs the NextDNS CLI, but its runtime configuration is still
machine-local. If you want this host to use NextDNS, do the one-time setup
after the first successful `darwin-switch`:

```sh
sudo nextdns install \
  -config <your-config-id> \
  -report-client-info \
  -auto-activate
```

To use split DNS, add any forwarders you need for your Tailscale domain or
home network names, then restart the service:

```sh
sudo nextdns config set -forwarder "<your-tailnet-domain>=100.100.100.100"
sudo nextdns config set -forwarder "<your-home-domain>=<your-router-dns-ip>"
sudo nextdns restart
```

______________________________________________________________________

## 8. Syncthing

Syncthing is enabled declaratively on Darwin hosts, including `beryllium`.

Target shape:

- stable device IDs live in `vars.syncthing.deviceIds`
- shared Syncthing policy is managed in nix
- `~/Code` and `~/Life` are the first shared folders modeled in nix between
  `lithium` and `beryllium`
- `~/Code/.stignore` is managed declaratively, so ignore policy survives a new
  machine bootstrap
- devices and folders not modeled in nix remain outside this shape until they
  are intentionally brought in

Connectivity policy:

- prefer Tailscale-only connectivity between devices
- do not rely on public relays when direct Tailscale connectivity is enough
- add the NAS to Tailscale first, then fold it into the Syncthing topology

______________________________________________________________________

## 9. Clone companion repos

These repos are not managed by nix-darwin but are needed for a full
environment:

```sh
# Hammerspoon config
git clone git@github.com:lackac/hs-config.git ~/.hammerspoon
git clone git@github.com:lackac/hs-config-private.git ~/.hammerspoon/private

# Neovim config (nvf-based)
git clone git@github.com:lackac/nvf-config.git ~/Code/lackac/nvf-config

# OpenCode config (if applicable)
git clone git@github.com:lackac/oc-config.git ~/Code/lackac/oc-config
```

______________________________________________________________________

## 10. Per-project language runtimes

Global `ruby` and `python3` are installed via `environment.systemPackages` for ad-hoc use.
For project-specific versions or additional runtimes (Node, Go, Elixir, etc.),
use nix dev shells via direnv.

______________________________________________________________________

## 11. SSH: work-specific host config

Work-specific SSH hosts (VPN endpoints, AWS SSM targets, etc.) are not
managed by nix. Add them to `~/.ssh/config.local` — this file is included
automatically by the nix-managed SSH config.

______________________________________________________________________

## 12. Git: machine-local overrides

Create `~/.config/git/local` for machine-specific git settings (work email,
private remotes, etc.):

```ini
[user]
  email = work@example.com
```

______________________________________________________________________

## 13. Brave profile scaffold (if using hs-config URL/window rules)

To set up Brave profiles for `hs-config` URL/window rules, use the helper in
`hs-config`.

```sh
~/Code/lackac/hs-config/scripts/seed-brave-profiles.sh
```

______________________________________________________________________

## 14. Manual app setup reminders

After the first successful `darwin-switch`, you will likely still want to
finish interactive setup for the GUI apps you actually plan to use on this
host. Review the apps present on the machine and decide which ones need
sign-in, config restore, or data migration.
