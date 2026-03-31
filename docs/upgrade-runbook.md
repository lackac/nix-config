# Upgrade Runbook

This runbook describes the recurring upgrade flow for this repo.

It focuses on routine input updates and staged rollouts across existing hosts. It does not cover first-time provisioning or fresh Darwin bootstrap. For those, use `docs/howto-provision-server.md` and `docs/bootstrap-darwin.md`.

## 1) Scope and rollout policy

- Treat upgrades as staged promotions, not a fleet-wide event.
- Update inputs in small batches when possible.
- Promote only after each phase produces explicit evidence.
- Keep Darwin and NixOS on separate rollout tracks after the shared evaluation step.
- Treat `oxygen` as a separate maintenance lane with a slower cadence.

## 2) Host groups

### Darwin hosts

- `beryllium`
- `lithium`

### NixOS hosts

- Lower-risk general hosts: `neon`
- Stateful or service-heavy hosts: `carbon`, `boron`

### Separate lane

- `oxygen` is single-purpose and should not be part of the normal batch upgrade cadence.

## 3) Upgrade units

Prefer smaller upgrade units over a full lockfile refresh.

- Single-input update: `just upp <input>`
- Full lockfile refresh: `just up`

Useful examples:

- `just upp nixpkgs`
- `just upp home-manager`
- `just upp nix-darwin`
- `just upp colmena`

Use a full refresh only when you intentionally want a broader reconciliation pass.

## 4) Pre-upgrade checks

Before touching a host:

1. Review the lockfile diff and note which inputs changed.
2. Run the shared flake validation:

   ```sh
   just check
   ```

3. Confirm you still have the access needed for the rollout:
   - Darwin: local admin access and a recovery path if `darwin-rebuild` fails.
   - NixOS: SSH reachability and Colmena access.
   - Secrets: ability to decrypt any required sops files.
4. For service-heavy hosts, choose a maintenance window before deploy.

If `just check` fails, stop and fix the evaluation issue before any host-level rollout.

## 5) Promotion order

Use this order by default:

1. Shared evaluation
2. `beryllium`
3. `lithium`
4. `neon`
5. `carbon`
6. `boron`
7. `oxygen` later, as a separate maintenance task

Rationale:

- Darwin has weaker rollback than NixOS, so upgrade it early but in small, local steps.
- `beryllium` is the lighter Darwin canary.
- `neon` is the first NixOS canary and must pass before `carbon` or `boron` begin.
- `carbon` and `boron` carry more service state and should only move after earlier phases pass.
- `oxygen` follows its own cadence and should not block normal fleet updates.

Proceed to the next host only after the current host passes its validation checks.

## 6) Darwin track

Run Darwin upgrades one host at a time.

### Check

```sh
just darwin-check beryllium
just darwin-check lithium
```

### Apply

```sh
just darwin-switch beryllium
just darwin-switch lithium
```

### Validate

After each Darwin switch, confirm:

- the rebuild completed successfully
- shell tooling starts normally
- Homebrew-managed apps still launch as expected
- 1Password integration still works if you rely on it
- Tailscale is still connected if the host depends on it

Do not proceed to the next host until these checks pass.

Notes:

- `docs/bootstrap-darwin.md` covers bootstrap and interactive setup details; do not duplicate them here.
- Homebrew activation can perform live updates, so expect Darwin upgrades to be less deterministic than pure Nix evaluation.

## 7) NixOS track

Run NixOS upgrades one host at a time.

### Dry-run

```sh
just deploy-dry neon
just deploy-dry carbon
just deploy-dry boron
```

### Apply

```sh
just deploy neon
just deploy carbon
just deploy boron
```

### Validate

After each deploy, confirm:

```sh
ssh <user>@<host> 'hostnamectl --static; nixos-version'
ssh <user>@<host> 'readlink -f /run/current-system'
ssh <user>@<host> 'sudo ls -l /run/secrets || true'
```

If the host is expected to reboot as part of validation, also confirm it returns cleanly and the new generation persists.

Do not proceed to the next host until these checks pass.

For more provisioning and deployment details, use `docs/howto-provision-server.md`.

## 8) Stateful server precautions

Treat `carbon` and `boron` as stop-and-observe steps.

- Upgrade only one of them at a time.
- Do not continue to the next service-heavy host until the current one is healthy.
- Confirm the host's declared services are active after deploy.
- If a package or module upgrade implies a data migration, handle that change intentionally rather than bundling it into a routine cadence run.
- After `carbon`, pause and confirm the host is stable before starting `boron`.
- After `boron`, pause again and confirm the host is stable before closing the rollout.

If a deploy succeeds but a critical service is unhealthy, stop the rollout there.

## 9) Oxygen track

`oxygen` is intentionally separate.

- It is out of band and not part of normal release promotion.
- Do not include it in the normal upgrade batch.
- Upgrade it only when there is a specific reason: needed fixes, security work, or planned maintenance.
- Treat its rollout as a dedicated session with extra attention to Raspberry Pi, SD image, networking, and OctoPrint-specific behavior.

Suggested flow:

```sh
just check
just deploy-dry oxygen
just deploy oxygen
```

Afterward, verify the host's single-purpose workflow still works before considering the upgrade complete.

## 10) Stop conditions

Stop promotion immediately if any of these happen:

- `just check` fails
- a host build or dry-run fails
- secrets are missing after activation
- SSH or Tailscale access regresses
- a critical service is unhealthy after deploy
- a Darwin host loses a workflow you rely on daily

Do not keep promoting while hoping a later host will be fine.

## 11) Rollback and fallback

Keep rollback decisions local to the failing host.

- Consider rollback when a deploy fails, host validation fails, or a core service is degraded after switch.
- On NixOS, prefer generation-based rollback and boot-entry recovery if a deploy causes regressions.
- On Darwin, be more conservative up front because rollback is weaker and manual recovery is more likely.
- If Colmena is unavailable, use the direct fallback path documented in `docs/howto-provision-server.md`.

After any rollback, stop the wider rollout and understand the failure before retrying.

## 12) Post-upgrade notes

After the run:

- record which inputs changed
- record which hosts were upgraded
- note any hosts intentionally skipped
- capture any manual fixes or follow-up work

If the upgrade surfaces new migration work, track it in the issue tracker rather than relying on local notes alone.
