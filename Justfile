# just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Common commands(suitable for all machines)
#
############################################################################

# List all the just commands
default:
  @just --list

# Update all the flake inputs
[group('nix')]
up:
  nix flake update

# Update specific input
# Usage: just upp nixpkgs
[group('nix')]
upp input:
  nix flake update {{input}}

# List all generations of the system profile
[group('nix')]
history:
  nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
[group('nix')]
repl:
  nix repl -f flake:nixpkgs

# remove all generations older than 7 days
# on darwin, you may need to switch to root user to run this command
[group('nix')]
clean:
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d

# Garbage collect all unused nix store entries
[group('nix')]
gc:
  # garbage collect all unused nix store entries(system-wide)
  sudo nix-collect-garbage --delete-older-than 7d
  # garbage collect all unused nix store entries(for the user - home-manager)
  # https://github.com/NixOS/nix/issues/8508
  nix-collect-garbage --delete-older-than 7d

[group('nix')]
fmt:
  # format the nix files in this repo
  nix fmt

# Show all the auto gc roots in the nix store
[group('nix')]
gcroot:
  ls -al /nix/var/nix/gcroots/auto/

# Verify all the store entries
# Nix Store can contain corrupted entries if the nix store object has been modified unexpectedly.
# This command will verify all the store entries, and we need to fix the corrupted entries
# manually via `sudo nix store delete <store-path-1> <store-path-2> ...`
[group('nix')]
verify-store:
  nix store verify --all

# Repair Nix Store Objects
[group('nix')]
repair-store *paths:
  nix store repair {{paths}}

############################################################################
#
#  Darwin related commands
#
############################################################################

[macos]
[group('desktop')]
darwin-rollback:
  ./result/sw/bin/darwin-rebuild --rollback

[macos]
[group('desktop')]
be:
  nix build '.#darwinConfigurations.beryllium.system'
  sudo -E ./result/sw/bin/darwin-rebuild switch --flake '.#beryllium'

[macos]
[group('desktop')]
be-debug:
  nix build '.#darwinConfigurations.beryllium.system' --show-trace --verbose
  sudo -E ./result/sw/bin/darwin-rebuild switch --flake '.#beryllium' --show-trace --verbose

# Reset launchpad to force it to reindex Applications
[macos]
[group('desktop')]
reset-launchpad:
  defaults write com.apple.dock ResetLaunchPad -bool true
  killall Dock
