{
  lib,
  ...
}:
let
  certDir = "/var/lib/minio/certs";
in
{
  flake.modules.nixos.minio =
    { config, pkgs, ... }:
    {
      services.minio = {
        enable = true;
        listenAddress = ":9000";
        consoleAddress = ":9001";
        certificatesDir = certDir;
        rootCredentialsFile = config.sops.templates."minio/root-credentials".path;
      };

      services.tailscale.extraSetFlags = lib.mkAfter [ "--hostname=boron" ];
      services.tailscale.extraUpFlags = lib.mkAfter [ "--advertise-tags=tag:homelab,tag:minio" ];

      sops.secrets."minio/rootUser" = {
        sopsFile = ../../secrets/boron.yaml;
        owner = "minio";
        group = "minio";
      };

      sops.secrets."minio/rootPassword" = {
        sopsFile = ../../secrets/boron.yaml;
        owner = "minio";
        group = "minio";
      };

      sops.templates."minio/root-credentials" = {
        owner = "minio";
        group = "minio";
        mode = "0400";
        content = ''
          MINIO_ROOT_USER=${config.sops.placeholder."minio/rootUser"}
          MINIO_ROOT_PASSWORD=${config.sops.placeholder."minio/rootPassword"}
        '';
      };

      systemd.services.minio-tailscale-certificate = {
        description = "Refresh MinIO TLS certificate from Tailscale";
        wants = [
          "network-online.target"
          "tailscaled.service"
          "tailscaled-autoconnect.service"
        ];
        after = [
          "network-online.target"
          "tailscaled.service"
          "tailscaled-autoconnect.service"
        ];
        before = [ "minio.service" ];
        wantedBy = [ "multi-user.target" ];

        path = [
          pkgs.coreutils
          pkgs.jq
          pkgs.systemd
          pkgs.tailscale
        ];

        serviceConfig = {
          Type = "oneshot";
        };

        script = ''
          certPath="${certDir}/public.crt"
          keyPath="${certDir}/private.key"

          beforeHash=""
          if [ -f "$certPath" ] && [ -f "$keyPath" ]; then
            beforeHash="$(sha256sum "$certPath" "$keyPath" | sha256sum | cut -d ' ' -f 1)"
          fi

          dnsName="$(tailscale status --json --peers=false | jq -r '.Self.DNSName')"
          dnsName="''${dnsName%.}"
          if [ -z "$dnsName" ] || [ "$dnsName" = "null" ]; then
            echo "tailscale DNS name is not available"
            exit 1
          fi

          install -d -m 0750 -o minio -g minio "${certDir}"
          tailscale cert --min-validity 720h --cert-file "$certPath" --key-file "$keyPath" "$dnsName"
          chown minio:minio "$certPath" "$keyPath"
          chmod 0440 "$certPath"
          chmod 0400 "$keyPath"

          afterHash="$(sha256sum "$certPath" "$keyPath" | sha256sum | cut -d ' ' -f 1)"
          if [ "$beforeHash" != "$afterHash" ] && systemctl is-active --quiet minio.service; then
            systemctl try-restart --no-block minio.service
          fi
        '';
      };

      systemd.timers.minio-tailscale-certificate = {
        description = "Renew MinIO TLS certificate from Tailscale";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
      };

      systemd.services.minio = {
        requires = [ "minio-tailscale-certificate.service" ];
        after = [ "minio-tailscale-certificate.service" ];
      };
    };
}
