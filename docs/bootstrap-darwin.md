# Bootstrap a new Mac (lithium / darwin)

Step-by-step guide to reproduce the full environment on a fresh macOS installation.

______________________________________________________________________

## 1. Install Determinate Nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

Restart your shell to pick up the Nix environment.

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

______________________________________________________________________

## 7. Syncthing

Syncthing is enabled declaratively, but devices and folders are intentionally
UI-managed for now:

- configure devices/folders in Syncthing Web UI (`http://127.0.0.1:8384`)
- topology changes (devices/folders) are not overwritten by nix

Optional migration step to keep the same device ID from an old machine:

To keep the same Syncthing device ID as your previous machine (avoiding
re-pairing all devices), copy the identity files before Syncthing starts:

```sh
mkdir -p ~/Library/Application\ Support/Syncthing
# Copy from old machine (or from backup):
scp oldmachine:~/Library/Application\ Support/Syncthing/cert.pem \
    ~/Library/Application\ Support/Syncthing/cert.pem
scp oldmachine:~/Library/Application\ Support/Syncthing/key.pem \
    ~/Library/Application\ Support/Syncthing/key.pem
```

If you don't have the old cert/key, Syncthing will generate a new identity.
You'll then need to accept the new device on your other devices.

______________________________________________________________________

## 8. Clone companion repos

These repos are not managed by nix-darwin but are needed for a full
environment:

```sh
# Hammerspoon config
git clone git@github.com:lackac/hs-config.git ~/.hammerspoon
git clone git@github.com:lackac/hs-config-private.git ~/.hammerspoon/private

# Neovim config (nvf-based)
git clone git@github.com:lackac/nvf-config.git ~/Code/lackac/nvf-config

# OpenCode config (if applicable)
git clone git@github.com:lackac/opencode-config.git ~/Code/lackac/opencode-config
```

______________________________________________________________________

## 9. Per-project language runtimes

Global `ruby` and `python3` are installed via `environment.systemPackages` for ad-hoc use.
For project-specific versions or additional runtimes (Node, Go, Elixir, etc.),
use nix dev shells via direnv.

______________________________________________________________________

## 10. SSH: work-specific host config

Work-specific SSH hosts (VPN endpoints, AWS SSM targets, etc.) are not
managed by nix. Add them to `~/.ssh/config.local` — this file is included
automatically by the nix-managed SSH config.

______________________________________________________________________

## 11. Git: machine-local overrides

Create `~/.config/git/local` for machine-specific git settings (work email,
private remotes, etc.):

```ini
[user]
  email = work@example.com
```

______________________________________________________________________

## 12. Brave profile scaffold (if using hs-config URL/window rules)

To set up Brave profiles for `hs-config` URL/window rules, use the helper in
`hs-config`.

```sh
~/Code/lackac/hs-config/scripts/seed-brave-profiles.sh --help
```

Keep all Brave profile/sync details in `hs-config` + `hs-config-private`.

______________________________________________________________________

## 13. Manual app setup reminders

After the first successful `darwin-switch`, you will likely still want to
finish interactive setup for a few apps:

- 1Password — sign in to the relevant accounts and confirm SSH agent settings
- Tailscale — sign in and join the tailnet
- Google Drive — sign in and choose which Drive content to sync locally
- Brave / Chrome — sign in and restore profiles or sync state as needed
- Obsidian — open your vault(s) and confirm plugins/themes/settings
- Hammerspoon — grant macOS permissions and confirm the config loads
- Syncthing — open the Web UI and re-add/approve devices and folders if needed
