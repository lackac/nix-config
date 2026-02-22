# MinIO to Garage Migration

**Goal:** Replace MinIO with Garage v2 as the S3-compatible object storage on boron, fronted by Caddy for TLS, and remove the now-unnecessary OpenTofu infrastructure.

**Architecture:** Garage v2 (single-node, LMDB, replication factor 1) serves plain HTTP on localhost:3900. Caddy reverse-proxies `s3.lackac.hu` to it with ACME TLS via DNSimple (same pattern as `mm.lackac.hu` on carbon). Mattermost on carbon connects over Tailscale to `s3.lackac.hu:443`. Key and bucket provisioning is manual (CLI), with credentials stored in sops. The OpenTofu stack (only used for MinIO IAM) is removed entirely.

**Tech Stack:** Garage v2 (2.2.0), Caddy (ACME/DNSimple), sops-nix, rclone (data migration)

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Garage version | v2 (`pkgs.garage_2`, 2.2.0) | Actively developed; v1 is maintenance-only. Fresh deploy has no migration burden. |
| DB engine | LMDB | Recommended for production. Embedded, no dependencies. |
| Replication factor | 1 | Single-node deployment. |
| TLS termination | Caddy with ACME/DNSimple | Same pattern as carbon. `s3.lackac.hu` hostname. |
| Key management | Manual CLI, keys stored in sops | Simple for one bucket. `garage key create` + store in sops. |
| Migration strategy | Direct cutover | Stop MinIO, rclone data, start Garage. No parallel running. |
| OpenTofu | Remove entirely | Only managed MinIO IAM. No other stacks exist. |

---

## Task 1: DNS record for `s3.lackac.hu`

Before any deployment, ensure a DNS record exists.

**Step 1: Create DNS record in DNSimple**

Add an A record for `s3.lackac.hu` pointing to boron's stable Tailscale IP (e.g., `100.x.y.z`).

Since Caddy uses DNS-01 ACME challenge (not HTTP-01), the record does not need to resolve publicly for cert issuance. But Mattermost on carbon needs to resolve `s3.lackac.hu` to reach boron. Both hosts are on Tailscale, so a DNS A record pointing to boron's Tailscale IP is the simplest approach.

---

## Task 2: Create `modules/services/garage.nix`

**Files:**
- Create: `modules/services/garage.nix`

**Step 1: Write the Garage flake-parts module**

```nix
{ ... }:
{
  flake.modules.nixos.garage =
    { config, pkgs, ... }:
    {
      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        logLevel = "info";

        environmentFile = config.sops.templates."garage/env".path;

        settings = {
          replication_factor = 1;
          db_engine = "lmdb";
          metadata_dir = "/var/lib/garage/meta";
          data_dir = "/var/lib/garage/data";
          metadata_auto_snapshot_interval = "6h";

          rpc_bind_addr = "[::]:3901";
          rpc_public_addr = "127.0.0.1:3901";

          s3_api = {
            api_bind_addr = "[::]:3900";
            s3_region = "garage";
            root_domain = ".s3.garage.localhost";
          };

          admin = {
            api_bind_addr = "127.0.0.1:3903";
          };
        };
      };

      sops.secrets."garage/rpcSecret" = {
        sopsFile = ../../secrets/boron.yaml;
        owner = "garage";
        group = "garage";
      };

      sops.secrets."garage/adminToken" = {
        sopsFile = ../../secrets/boron.yaml;
        owner = "garage";
        group = "garage";
      };

      sops.templates."garage/env" = {
        owner = "garage";
        group = "garage";
        mode = "0400";
        content = ''
          GARAGE_RPC_SECRET=${config.sops.placeholder."garage/rpcSecret"}
          GARAGE_ADMIN_TOKEN=${config.sops.placeholder."garage/adminToken"}
        '';
      };

      # Caddy reverse proxy for S3 API
      services.caddy.extraConfig = ''
        s3.lackac.hu {
          reverse_proxy localhost:3900
        }
      '';
    };
}
```

**Step 2: Verify the module evaluates**

Run: `just check`
Expected: No evaluation errors (deploy will fail without secrets, but check should pass)

**Step 3: Commit**

```
feat(garage): wire Garage v2 service with Caddy TLS and sops secrets
```

---

## Task 3: Move DNSimple token to `secrets/common.yaml`

The `caddy.nix` module reads `dnsimple/token` from `sops.defaultSopsFile` (carbon.yaml on carbon, unset on boron). Since both hosts now need it, move it to `secrets/common.yaml` and set the `sopsFile` explicitly.

**Files:**
- Modify: `modules/services/caddy.nix`
- Modify: `secrets/common.yaml` (add `dnsimple/token`)
- Modify: `secrets/carbon.yaml` (remove `dnsimple/token`)

**Step 1: Update `caddy.nix` to use `common.yaml` explicitly**

In `modules/services/caddy.nix`, change:

```nix
sops.secrets."dnsimple/token" = { };
```

to:

```nix
sops.secrets."dnsimple/token" = {
  sopsFile = ../../secrets/common.yaml;
};
```

**Step 2: Rotate the sops secret**

```bash
# Decrypt carbon.yaml, copy the dnsimple/token value
sops secrets/carbon.yaml
# (note the dnsimple.token value)

# Add it to common.yaml
sops secrets/common.yaml
# (add dnsimple: { token: "<value>" })

# Remove from carbon.yaml
sops secrets/carbon.yaml
# (delete the dnsimple section)
```

**Step 3: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 4: Commit**

```
refactor(caddy): move dnsimple token to common secrets for multi-host use
```

---

## Task 4: Update boron host to use Garage and Caddy

**Files:**
- Modify: `modules/hosts/boron.nix`

**Step 1: Swap aspects**

In `modules/hosts/boron.nix`, change the `boronAspects` list. Remove `minio`, add `garage` and `caddy`:

```nix
boronAspects = with inputs.self.modules.nixos; [
  # Platform bases
  common
  server
  secrets

  # Hardware
  hardware-n100
  disko-nvme

  # Features
  docker
  mc
  garage
  caddy
  tailscale
];
```

**Step 2: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 3: Commit**

```
feat(boron): enable garage and caddy aspects, drop minio
```

---

## Task 5: Update Mattermost S3 configuration

**Files:**
- Modify: `modules/services/mattermost.nix`

**Step 1: Update the module**

Change sops secret names from `minio/*` to `garage/*` and update S3 endpoint settings:

```nix
{ ... }:
{
  flake.modules.nixos.mattermost =
    { config, pkgs, ... }:
    {
      sops.secrets."garage/mattermostAccessKey" = {
        sopsFile = ../../secrets/carbon.yaml;
        owner = "mattermost";
        group = "mattermost";
      };

      sops.secrets."garage/mattermostSecretKey" = {
        sopsFile = ../../secrets/carbon.yaml;
        owner = "mattermost";
        group = "mattermost";
      };

      sops.templates."mattermost/env" = {
        owner = "mattermost";
        group = "mattermost";
        mode = "0400";
        content = ''
          MM_FILESETTINGS_AMAZONS3ACCESSKEYID=${config.sops.placeholder."garage/mattermostAccessKey"}
          MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY=${config.sops.placeholder."garage/mattermostSecretKey"}
        '';
      };

      services.mattermost = {
        enable = true;
        package = pkgs.mattermostLatest;
        siteUrl = "https://mm.lackac.hu";
        port = 8065;
        host = "127.0.0.1";
        mutableConfig = false;
        environmentFile = config.sops.templates."mattermost/env".path;

        settings = {
          ServiceSettings = {
            SessionLengthWebInHours = 744;
            SessionLengthMobileInHours = 744;
            SessionLengthSSOInHours = 744;

            EnableSVGs = true;
            EnableLatex = true;
            EnableInlineLatex = true;

            EnableBotAccountCreation = true;
            EnablePostUsernameOverride = true;
            EnablePostIconOverride = true;
            EnableUserAccessTokens = true;
          };

          LogSettings = {
            ConsoleLevel = "INFO";
          };

          ImageProxySettings = {
            Enable = true;
            ImageProxyType = "local";
          };

          FileSettings = {
            DriverName = "amazons3";
            AmazonS3Bucket = "mattermost";
            AmazonS3Region = "garage";
            AmazonS3Endpoint = "s3.lackac.hu";
            AmazonS3SSL = true;
          };

          EmailSettings = {
            SendEmailNotifications = false;
            EnablePreviewModeBanner = false;
          };
        };
      };
    };
}
```

Key changes:
- `AmazonS3Region`: `"us-east-1"` → `"garage"`
- `AmazonS3Endpoint`: `"boron.at-larch.ts.net:9000"` → `"s3.lackac.hu"`
- Sops secret names: `minio/mattermost*` → `garage/mattermost*`

**Step 2: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 3: Commit**

```
feat(mattermost): point S3 settings at Garage via s3.lackac.hu
```

---

## Task 6: Add Garage secrets to sops

**Files:**
- Modify: `secrets/boron.yaml`

**Step 1: Generate and store Garage secrets**

```bash
# Generate RPC secret (32-byte hex)
openssl rand -hex 32

# Generate admin token (any strong random string)
openssl rand -base64 32

# Add to boron.yaml
sops secrets/boron.yaml
# Add:
#   garage:
#     rpcSecret: <generated hex>
#     adminToken: <generated token>
```

**Step 2: Commit**

```
chore(secrets): seed garage rpc secret and admin token
```

---

## Task 7: Delete MinIO module and OpenTofu infrastructure

**Files:**
- Delete: `modules/services/minio.nix`
- Delete: `infra/` (entire directory — only contains `minio/`)
- Delete: `secrets/tofu.yaml`
- Delete: `scripts/tofu-env.sh`
- Modify: `Justfile` (remove tofu recipes)
- Modify: `.sops.yaml` (remove `secrets/tofu.yaml` rule)

**Step 1: Remove files**

```bash
rm modules/services/minio.nix
rm -r infra
rm secrets/tofu.yaml
rm scripts/tofu-env.sh
rmdir scripts 2>/dev/null || true
```

**Step 2: Remove tofu recipes from Justfile**

Remove these lines (31-38) from `Justfile`:

```just
tofu-init stack:
  ./scripts/tofu-env.sh {{stack}} -- tofu -chdir=infra/{{stack}} init -reconfigure

tofu-plan stack:
  ./scripts/tofu-env.sh {{stack}} -- tofu -chdir=infra/{{stack}} plan

tofu-apply stack:
  ./scripts/tofu-env.sh {{stack}} -- tofu -chdir=infra/{{stack}} apply
```

**Step 3: Remove tofu.yaml sops rule from `.sops.yaml`**

Remove the `secrets/tofu\.yaml$` creation rule (lines 23-26):

```yaml
  - path_regex: secrets/tofu\.yaml$
    key_groups:
      - age:
        - *admin
```

**Step 4: Remove MinIO secrets from `secrets/boron.yaml`**

```bash
sops secrets/boron.yaml
# Remove the entire minio section:
#   minio:
#     rootUser: ...
#     rootPassword: ...
```

**Step 5: Verify**

Run: `just check`
Expected: No evaluation errors

```bash
# Double-check no lingering references
grep -r minio modules/ Justfile .sops.yaml 2>/dev/null
```

Expected: No output

**Step 6: Commit**

```
refactor: remove minio, opentofu, and related infrastructure

MinIO is replaced by Garage. OpenTofu was only used for MinIO IAM
management and is no longer needed.
```

---

## Task 8: Deploy and provision Garage

This task is performed live on the hosts. Order matters.

**Step 1: Deploy boron (Garage + Caddy)**

```bash
just deploy boron
```

Expected: Garage service starts, Caddy obtains TLS cert for `s3.lackac.hu`.

Verify:
```bash
ssh boron
systemctl status garage
systemctl status caddy
curl -k https://s3.lackac.hu  # should get an S3 error response (no auth), confirming TLS works
```

**Step 2: Configure Garage cluster layout**

SSH into boron:

```bash
ssh boron

# Check node ID
garage status

# Assign layout (replace <node-id> with actual ID from status output)
garage layout assign -z dc1 -c 1G <node-id>
garage layout apply --version 1
```

**Step 3: Create the Mattermost bucket and key**

```bash
# Create API key
garage key create mattermost-key

# Note the Key ID (GK...) and Secret Key from the output

# Create bucket
garage bucket create mattermost

# Grant permissions
garage bucket allow --read --write --owner mattermost --key mattermost-key
```

**Step 4: Store the new key credentials in sops**

Back on the local machine:

```bash
sops secrets/carbon.yaml
# Rename existing minio keys and set new values:
#   garage:
#     mattermostAccessKey: <Key ID from step 3>
#     mattermostSecretKey: <Secret Key from step 3>
# Remove the old minio section if still present
```

Commit:
```
chore(secrets): store garage mattermost key credentials
```

---

## Task 9: Migrate data from MinIO to Garage

**Step 1: Stop Mattermost (prevent writes during migration)**

On carbon:
```bash
ssh carbon
sudo systemctl stop mattermost
```

**Step 2: Sync data using rclone**

On a machine with access to both services (or on boron). Note: MinIO may already be stopped from the deploy. If so, either temporarily start it (`sudo systemctl start minio`) or rclone directly from the filesystem on boron (`/var/lib/minio/data/mattermost/` → garage remote).

```bash
# Configure rclone remotes
rclone config
# Create "minio" remote:
#   type: s3
#   provider: Minio
#   endpoint: https://boron.at-larch.ts.net:9000
#   access_key_id: <minio root user>
#   secret_access_key: <minio root password>
#
# Create "garage" remote:
#   type: s3
#   provider: Other
#   endpoint: https://s3.lackac.hu
#   access_key_id: <garage key id>
#   secret_access_key: <garage secret key>
#   region: garage

# Dry run first
rclone sync minio:mattermost garage:mattermost --dry-run --progress

# Actual sync
rclone sync minio:mattermost garage:mattermost --progress --checksum
```

Alternative if MinIO is already stopped — rclone from local filesystem:
```bash
# On boron, sync directly from MinIO's data directory
rclone sync /var/lib/minio/data/mattermost/ garage:mattermost --progress --checksum
```

**Step 3: Verify data integrity**

```bash
rclone size garage:mattermost
# Compare with expected count

rclone check /var/lib/minio/data/mattermost/ garage:mattermost
# Or if using remote: rclone check minio:mattermost garage:mattermost
```

**Step 4: Deploy carbon (updated Mattermost config)**

```bash
just deploy carbon
```

This restarts Mattermost with the new Garage endpoint and credentials.

**Step 5: Verify Mattermost**

- Open `https://mm.lackac.hu`
- Check that existing file attachments load correctly
- Upload a new file and verify it works
- Check Mattermost logs: `journalctl -u mattermost -f` on carbon

---

## Task 10: Cleanup

**Step 1: Remove old MinIO data (once satisfied)**

On boron, after confirming everything works:
```bash
sudo rm -rf /var/lib/minio
```

**Step 2: Optionally remove the old MinIO Tailscale tags**

The `minio.nix` module advertised `--advertise-tags=tag:homelab,tag:minio` on Tailscale. With the module removed, these tags are no longer set. Verify with `tailscale status` on boron.

---

## Summary of changes

| Action | File | What |
|--------|------|------|
| Create | `modules/services/garage.nix` | Garage v2 service + Caddy vhost + sops secrets |
| Modify | `modules/services/caddy.nix` | Explicit `sopsFile` for dnsimple token |
| Modify | `modules/hosts/boron.nix` | Swap `minio` → `garage` + `caddy` |
| Modify | `modules/services/mattermost.nix` | Update endpoint, region, secret names |
| Modify | `secrets/common.yaml` | Add `dnsimple/token` |
| Modify | `secrets/carbon.yaml` | Rename minio→garage keys, remove dnsimple token |
| Modify | `secrets/boron.yaml` | Add garage secrets, remove minio secrets |
| Modify | `Justfile` | Remove tofu recipes |
| Modify | `.sops.yaml` | Remove tofu.yaml rule |
| Delete | `modules/services/minio.nix` | MinIO module |
| Delete | `infra/` | Entire OpenTofu stack |
| Delete | `secrets/tofu.yaml` | OpenTofu backend creds |
| Delete | `scripts/tofu-env.sh` | OpenTofu env helper |
