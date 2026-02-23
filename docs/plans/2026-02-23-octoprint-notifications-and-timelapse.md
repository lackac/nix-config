# OctoPrint Notifications, Timelapse Upload, and Webcam Flip

**Goal:** Send OctoPrint print events and snapshots to Mattermost, upload timelapses to Garage S3 with permanent links, and pin webcam flip settings declaratively.

**Architecture:** A single shell script (`octoprint-notify`) handles all OctoPrint event notifications. For print events (start, done, fail), it captures a snapshot from go2rtc, uploads it to the Garage `octoprint` bucket, and POSTs a Mattermost incoming webhook with an inline image link. For timelapse completion, it additionally uploads the video file. All media is served via Garage's website endpoint through a Caddy vhost on boron (`octoprint.s3.lackac.hu`), providing permanent URLs. Secrets (S3 credentials, Mattermost webhook URL) are managed via sops-nix.

**Tech Stack:** OctoPrint event system, awscli (S3-compatible), Garage website endpoint, Mattermost incoming webhooks, sops-nix, Caddy

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Notification delivery | Shell script + Mattermost incoming webhook | No plugin packaging needed; full control over message format; secrets from sops |
| Timelapse upload | awscli to Garage S3 | Standard tooling, `--endpoint-url` for Garage compatibility |
| Snapshot handling | Capture from go2rtc, upload to Garage, inline permanent URL in Mattermost message | Permanent links; no dependency on Mattermost image proxy reaching oxygen |
| Public file access | Garage website endpoint + Caddy vhost | Permanent URLs, no ACL management (Garage lacks bucket policies) |
| Webhook URL secret | sops secret on oxygen, read from file at runtime | Fully declarative, secret stays out of Nix store |
| Webcam flip | Pinned in Nix `extraConfig` | Survives state wipes, declarative |

---

## Task 1: Pin webcam flip in OctoPrint config

**Files:**
- Modify: `modules/services/octoprint.nix:158-162`

**Step 1: Add flip settings to classicwebcam plugin config**

In `modules/services/octoprint.nix`, within `extraConfig.plugins.classicwebcam`, add `flipH` and `flipV`:

```nix
classicwebcam = {
  _config_version = 1;
  flipH = true;
  flipV = true;
  stream = "/webcam/api/stream.mjpeg?src=printer";
  snapshot = "/webcam/api/frame.jpeg?src=printer";
};
```

**Step 2: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 3: Commit**

```
feat(octoprint): pin webcam flip settings declaratively

Ensures flipH and flipV survive state wipes instead of relying
on UI-persisted config.yaml values.
```

---

## Task 2: Enable Garage website endpoint

**Files:**
- Modify: `modules/services/garage.nix`

**Step 1: Add s3_web section to Garage settings**

In `modules/services/garage.nix`, add the `s3_web` block inside `services.garage.settings`:

```nix
s3_web = {
  bind_addr = "[::]:3902";
  root_domain = ".web.garage.localhost";
};
```

**Step 2: Add Caddy vhost for octoprint media**

In the same file, extend the `services.caddy.extraConfig` to include a vhost for the website endpoint:

```nix
services.caddy.extraConfig = ''
  s3.lackac.hu {
    reverse_proxy localhost:3900
  }
  octoprint.s3.lackac.hu {
    reverse_proxy localhost:3902
  }
'';
```

**Step 3: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 4: Commit**

```
feat(garage): expose website endpoint for public bucket access

Adds s3_web listener on port 3902 and a Caddy vhost at
octoprint.s3.lackac.hu for serving uploaded snapshots and
timelapses with permanent URLs.
```

---

## Task 3: Wire sops secrets for OctoPrint S3 and Mattermost

**Files:**
- Modify: `modules/services/octoprint.nix`

The Garage credentials (`garage/octoprintAccessKey`, `garage/octoprintSecretKey`) already exist in `secrets/oxygen.yaml`. The Mattermost webhook URL needs to be added manually before deployment (see Task 7).

**Step 1: Declare sops secrets**

Add the following sops secret declarations inside the `flake.modules.nixos.octoprint` module:

```nix
sops.secrets."garage/octoprintAccessKey" = {
  owner = "octoprint";
  group = "octoprint";
};

sops.secrets."garage/octoprintSecretKey" = {
  owner = "octoprint";
  group = "octoprint";
};

sops.secrets."mattermost/webhookUrl" = {
  owner = "octoprint";
  group = "octoprint";
};
```

These use `sops.defaultSopsFile` which is set to `secrets/oxygen.yaml` in the oxygen host config.

**Step 2: Create sops template for AWS credentials file**

Add a sops template that generates an AWS credentials file for awscli:

```nix
sops.templates."octoprint/aws-credentials" = {
  owner = "octoprint";
  group = "octoprint";
  mode = "0400";
  content = ''
    [default]
    aws_access_key_id=${config.sops.placeholder."garage/octoprintAccessKey"}
    aws_secret_access_key=${config.sops.placeholder."garage/octoprintSecretKey"}
  '';
};
```

**Step 3: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 4: Commit**

```
feat(octoprint): wire sops secrets for Garage S3 and Mattermost webhook
```

---

## Task 4: Create the notification and upload script

**Files:**
- Modify: `modules/services/octoprint.nix`

**Step 1: Write the octoprint-notify script**

Add a `writeShellApplication` definition inside the `let` block of the octoprint module:

```nix
octoprint-notify = pkgs.writeShellApplication {
  name = "octoprint-notify";
  runtimeInputs = with pkgs; [ awscli2 curl jq ];
  text = ''
    # Configuration
    WEBHOOK_URL_FILE="/run/secrets/mattermost/webhookUrl"
    AWS_SHARED_CREDENTIALS_FILE="${config.sops.templates."octoprint/aws-credentials".path}"
    export AWS_SHARED_CREDENTIALS_FILE
    S3_ENDPOINT="https://s3.lackac.hu"
    S3_BUCKET="octoprint"
    PUBLIC_BASE_URL="https://octoprint.s3.lackac.hu"
    SNAPSHOT_URL="http://127.0.0.1:1984/api/frame.jpeg?src=printer"
    BOT_USERNAME="PrusaMK3S"
    BOT_ICON_EMOJI="3dprinter"

    WEBHOOK_URL="$(cat "$WEBHOOK_URL_FILE")"
    TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

    post_to_mattermost() {
      local text="$1"
      local payload
      payload=$(jq -n \
        --arg text "$text" \
        --arg username "$BOT_USERNAME" \
        --arg icon_emoji "$BOT_ICON_EMOJI" \
        '{text: $text, username: $username, icon_emoji: $icon_emoji}')
      curl -s -o /dev/null -X POST -H 'Content-Type: application/json' \
        -d "$payload" "$WEBHOOK_URL"
    }

    upload_snapshot() {
      local key="snapshots/$TIMESTAMP-$1.jpg"
      local tmpfile
      tmpfile="$(mktemp /tmp/octoprint-snapshot-XXXXXX.jpg)"
      if curl -s -o "$tmpfile" -f "$SNAPSHOT_URL"; then
        aws s3 cp "$tmpfile" "s3://$S3_BUCKET/$key" \
          --endpoint-url "$S3_ENDPOINT" --region garage --quiet
        rm -f "$tmpfile"
        echo "$PUBLIC_BASE_URL/$key"
      else
        rm -f "$tmpfile"
        echo ""
      fi
    }

    upload_timelapse() {
      local movie_path="$1"
      local movie_basename="$2"
      local key="timelapses/$movie_basename"
      aws s3 cp "$movie_path" "s3://$S3_BUCKET/$key" \
        --endpoint-url "$S3_ENDPOINT" --region garage --quiet
      echo "$PUBLIC_BASE_URL/$key"
    }

    format_time() {
      local seconds="$1"
      # Truncate to integer (OctoPrint sends float)
      seconds="''${seconds%%.*}"
      local hours=$((seconds / 3600))
      local minutes=$(( (seconds % 3600) / 60 ))
      if [ "$hours" -gt 0 ]; then
        echo "''${hours}h ''${minutes}m"
      else
        echo "''${minutes}m"
      fi
    }

    EVENT="$1"
    shift

    case "$EVENT" in
      PrintStarted)
        NAME="$1"
        SNAP_URL="$(upload_snapshot "start")"
        MSG=":3dprinter: **Print started:** $NAME"
        if [ -n "$SNAP_URL" ]; then
          MSG="$MSG"$'\n'"![]($SNAP_URL)"
        fi
        post_to_mattermost "$MSG"
        ;;

      PrintDone)
        NAME="$1"
        TIME_STR="$(format_time "$2")"
        SNAP_URL="$(upload_snapshot "done")"
        MSG=":white_check_mark: **Print done:** $NAME ($TIME_STR)"
        if [ -n "$SNAP_URL" ]; then
          MSG="$MSG"$'\n'"![]($SNAP_URL)"
        fi
        post_to_mattermost "$MSG"
        ;;

      PrintFailed)
        NAME="$1"
        REASON="$2"
        SNAP_URL="$(upload_snapshot "failed")"
        MSG=":x: **Print failed:** $NAME (reason: $REASON)"
        if [ -n "$SNAP_URL" ]; then
          MSG="$MSG"$'\n'"![]($SNAP_URL)"
        fi
        post_to_mattermost "$MSG"
        ;;

      MovieDone)
        MOVIE_PATH="$1"
        MOVIE_BASENAME="$2"
        GCODE_NAME="$3"
        TIMELAPSE_URL="$(upload_timelapse "$MOVIE_PATH" "$MOVIE_BASENAME")"
        MSG=":movie_camera: **Timelapse ready:** [$MOVIE_BASENAME]($TIMELAPSE_URL)"
        if [ -n "$GCODE_NAME" ]; then
          MSG="$MSG (from $GCODE_NAME)"
        fi
        post_to_mattermost "$MSG"
        ;;

      *)
        echo "Unknown event: $EVENT" >&2
        exit 1
        ;;
    esac
  '';
};
```

**Step 2: Add the script to system packages**

In the module's `environment.systemPackages`, add `octoprint-notify`:

```nix
environment.systemPackages = [
  rpicam-apps
  pkgs.rpi.libcamera
  octoprint-notify
];
```

Note: `awscli2`, `curl`, and `jq` are pulled in as `runtimeInputs` of the script wrapper and don't need to be listed separately.

**Step 3: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 4: Commit**

```
feat(octoprint): notification script for Mattermost with S3 media upload

Handles PrintStarted, PrintDone, PrintFailed (with snapshot upload)
and MovieDone (with timelapse upload). All media gets permanent URLs
via Garage's website endpoint.
```

---

## Task 5: Configure OctoPrint event subscriptions

**Files:**
- Modify: `modules/services/octoprint.nix`

**Step 1: Add event subscriptions to extraConfig**

Add the `events` key to `services.octoprint.extraConfig`:

```nix
events = {
  enabled = true;
  subscriptions = [
    {
      event = "PrintStarted";
      command = "${octoprint-notify}/bin/octoprint-notify PrintStarted {name}";
      type = "system";
      shell = false;
    }
    {
      event = "PrintDone";
      command = "${octoprint-notify}/bin/octoprint-notify PrintDone {name} {time}";
      type = "system";
      shell = false;
    }
    {
      event = "PrintFailed";
      command = "${octoprint-notify}/bin/octoprint-notify PrintFailed {name} {reason}";
      type = "system";
      shell = false;
    }
    {
      event = "MovieDone";
      command = "${octoprint-notify}/bin/octoprint-notify MovieDone {movie} {movie_basename} {gcode}";
      type = "system";
      shell = false;
    }
  ];
};
```

Using full store paths (`${octoprint-notify}/bin/...`) since `shell = false` means no PATH lookup. This also ensures Nix tracks the dependency.

**Step 2: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 3: Commit**

```
feat(octoprint): wire event subscriptions to notification script
```

---

## Task 6: Configure timelapse settings

**Files:**
- Modify: `modules/services/octoprint.nix`

The old config had timelapse set to `type: off` with fps 25 and postRoll 3. We should enable timelapse recording so MovieDone events actually fire.

**Step 1: Add timelapse config to extraConfig**

Update the `webcam` section in `extraConfig`:

```nix
webcam = {
  stream = "/webcam/api/stream.mjpeg?src=printer";
  snapshot = "/webcam/api/frame.jpeg?src=printer";
  ffmpeg = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
  timelapse = {
    type = "timed";
    fps = 25;
    postRoll = 3;
  };
};
```

Note: Setting `type = "timed"` enables timed timelapse capture. The user can change to `"zchange"` via UI if preferred. This ensures MovieDone events fire.

**Step 2: Verify**

Run: `just check`
Expected: No evaluation errors

**Step 3: Commit**

```
feat(octoprint): enable timed timelapse capture for MovieDone events
```

---

## Task 7: Manual deployment steps

These are runtime/deployment steps, not code changes.

**Step 1: Create Mattermost incoming webhook**

In Mattermost (`mm.lackac.hu`):
1. Go to **Main Menu > Integrations > Incoming Webhooks**
2. Create a webhook for the desired channel (e.g. `3d-printer`)
3. Note the webhook URL

**Step 2: Add webhook URL to oxygen secrets**

```bash
sops secrets/oxygen.yaml
# Add:
#   mattermost:
#     webhookUrl: "https://mm.lackac.hu/hooks/<generated-key>"
```

Commit: `chore(secrets): store Mattermost webhook URL for OctoPrint notifications`

**Step 3: Create DNS record for octoprint.s3.lackac.hu**

Add an A record in DNSimple pointing `octoprint.s3.lackac.hu` to boron's Tailscale IP.

**Step 4: Deploy boron**

```bash
just deploy boron
```

This applies the Garage website endpoint and Caddy vhost changes.

**Step 5: Enable website mode on the octoprint bucket**

SSH to boron:

```bash
ssh boron
garage bucket website --allow octoprint
```

If the `octoprint` bucket doesn't exist yet, create it first:

```bash
garage bucket create octoprint
garage key create octoprint-key
# Note the Key ID and Secret Key
garage bucket allow --read --write --owner octoprint --key octoprint-key
garage bucket website --allow octoprint
```

Then update `secrets/oxygen.yaml` with the new key credentials if they differ from what's already stored.

**Step 6: Deploy oxygen**

```bash
just deploy oxygen
```

**Step 7: Verify**

1. Check OctoPrint is running: `https://op.lackac.hu`
2. Check webcam flip is applied (image should be flipped H+V)
3. Trigger a test: start a short print or manually run the notify script on oxygen:
   ```bash
   ssh oxygen
   sudo -u octoprint /nix/store/.../octoprint-notify PrintStarted test-file.gcode
   ```
4. Verify the Mattermost channel receives a notification with a snapshot
5. Check the snapshot is accessible at `https://octoprint.s3.lackac.hu/snapshots/...`

---

## Summary of changes

| File | Changes |
|------|---------|
| `modules/services/octoprint.nix` | Webcam flip, sops secrets + AWS credentials template, notification script, event subscriptions, timelapse config |
| `modules/services/garage.nix` | `s3_web` endpoint config, Caddy vhost for `octoprint.s3.lackac.hu` |
| `secrets/oxygen.yaml` | Add `mattermost/webhookUrl` (manual sops edit) |
