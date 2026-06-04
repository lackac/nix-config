{
  lib,
  ...
}:
{
  flake.modules.nixos."git-actions-runner" =
    { config, pkgs, ... }:
    let
      inherit (lib)
        concatStringsSep
        escapeShellArg
        getExe
        ;

      hostName = config.networking.hostName;
      system = pkgs.stdenv.hostPlatform.system;
      labels = [
        "${system}:host"
        "${hostName}:host"
        "docker:docker://node:20-bookworm"
        "ubuntu-latest:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
      ];
      settingsFormat = pkgs.formats.yaml { };
      configFile = settingsFormat.generate "forgejo-runner-${hostName}.yaml" {
        container.docker_host = "-";
      };
      hostPackages = with pkgs; [
        bash
        coreutils
        curl
        gawk
        gitMinimal
        gnused
        nodejs
        wget
        nix
      ];
    in
    {
      systemd.services."forgejo-runner-${hostName}" = {
        description = "Forgejo Actions Runner";
        wants = [ "network-online.target" ];
        after = [
          "network-online.target"
          "podman.service"
        ];
        wantedBy = [ "multi-user.target" ];

        environment = {
          DOCKER_HOST = "unix:///run/podman/podman.sock";
          HOME = "/var/lib/forgejo-runner/${hostName}";
        };
        path = [ pkgs.coreutils ] ++ hostPackages;

        serviceConfig = {
          DynamicUser = true;
          User = "forgejo-runner";
          StateDirectory = "forgejo-runner";
          WorkingDirectory = "-/var/lib/forgejo-runner/${hostName}";
          EnvironmentFile = config.sops.templates."git-actions-runner/token.env".path;
          Restart = "on-failure";
          RestartSec = 2;
          SupplementaryGroups = [ "podman" ];
          ExecStartPre = pkgs.writeShellScript "forgejo-register-runner-${hostName}" ''
            export INSTANCE_DIR="$STATE_DIRECTORY/${hostName}"
            mkdir -vp "$INSTANCE_DIR"
            cd "$INSTANCE_DIR"

            export TOKEN_HASH_FILE="$INSTANCE_DIR/.token-hash"
            export TOKEN_HASH_CURRENT="$(printf '%s' "$TOKEN" | sha256sum | cut -d' ' -f1)"
            export TOKEN_HASH_STORED="$(cat "$TOKEN_HASH_FILE" 2>/dev/null || echo "")"
            export LABELS_FILE="$INSTANCE_DIR/.labels"
            export LABELS_WANTED="$(echo ${escapeShellArg (concatStringsSep "\n" labels)} | sort)"
            export LABELS_CURRENT="$(cat "$LABELS_FILE" 2>/dev/null || echo 0)"

            if [ ! -e "$INSTANCE_DIR/.runner" ] || [ "$LABELS_WANTED" != "$LABELS_CURRENT" ] || [ "$TOKEN_HASH_CURRENT" != "$TOKEN_HASH_STORED" ]; then
              rm -v "$INSTANCE_DIR/.runner" || true

              ${getExe pkgs.forgejo-runner} register --no-interactive \
                --instance ${escapeShellArg "https://git.lackac.hu"} \
                --token "$TOKEN" \
                --name ${escapeShellArg "${hostName}-${system}"} \
                --labels ${escapeShellArg (concatStringsSep "," labels)} \
                --config ${configFile}

              printf '%s' "$TOKEN_HASH_CURRENT" > "$TOKEN_HASH_FILE"
              echo "$LABELS_WANTED" > "$LABELS_FILE"
            fi
          '';
          ExecStart = "${getExe pkgs.forgejo-runner} daemon --config ${configFile}";
        };
      };

      sops.secrets."git-actions-runner/runnerRegistrationToken" = {
        sopsFile = ../../secrets/common.yaml;
      };

      sops.templates."git-actions-runner/token.env".content = ''
        TOKEN=${config.sops.placeholder."git-actions-runner/runnerRegistrationToken"}
      '';
    };
}
