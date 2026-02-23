{ ... }:
{
  flake.modules.nixos.octoprint =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      rpicam-apps = pkgs.rpi.rpicam-apps.override {
        withDrmPreview = false;
        withQtPreview = false;
        withEglPreview = false;
        withOpenCVPostProc = false;
      };

      octoprint-with-filamentmanager = pkgs.octoprint.override {
        packageOverrides =
          self: super:
          let
            buildPlugin =
              args:
              self.buildPythonPackage (
                args
                // {
                  pname = "octoprint-plugin-${args.pname}";
                  propagatedBuildInputs = (args.propagatedBuildInputs or [ ]) ++ [ super.octoprint ];
                  doCheck = false;
                }
              );
          in
          {
            sqlalchemy-legacy =
              self.callPackage "${pkgs.path}/pkgs/development/python-modules/sqlalchemy/1_4.nix"
                { };

            backports-csv = self.buildPythonPackage rec {
              pname = "backports.csv";
              version = "1.0.7";
              format = "setuptools";

              src = pkgs.fetchurl {
                url = "https://files.pythonhosted.org/packages/source/b/backports.csv/backports.csv-${version}.tar.gz";
                sha256 = "sha256-Enff/3MTCy4Qa/PdNHrbPF9sQ0CIIonYjzEkDaksvW0=";
              };

              pythonNamespaces = [ "backports" ];
              doCheck = false;

              meta = {
                description = "CSV module backport";
                homepage = "https://pypi.org/project/backports.csv/";
                license = lib.licenses.psfl;
              };
            };

            filamentmanager = buildPlugin rec {
              pname = "filamentmanager";
              version = "1.9.1";
              format = "setuptools";

              src = pkgs.fetchFromGitHub {
                owner = "OllisGit";
                repo = "OctoPrint-FilamentManager";
                rev = version;
                sha256 = "035h20hmsbvih0pg23qpnvk72l9vraxa2hhrll8lza7yhqjmml5w";
              };

              postPatch = ''
                substituteInPlace octoprint_filamentmanager/data/__init__.py \
                  --replace "row.keys()" "list(row.keys())"
              '';

              propagatedBuildInputs = with self; [
                backports-csv
                uritools
                sqlalchemy-legacy
              ];

              meta = {
                description = "OctoPrint filament inventory manager";
                homepage = "https://github.com/OllisGit/OctoPrint-FilamentManager";
                license = lib.licenses.agpl3Only;
              };
            };

          };
      };

      octoprint-notify = pkgs.writeShellApplication {
        name = "octoprint-notify";
        runtimeInputs = with pkgs; [
          awscli2
          curl
          jq
          yq-go
        ];
        text = ''
          export WEBHOOK_URL_FILE="/run/secrets/mattermost/webhookUrl"
          export AWS_SHARED_CREDENTIALS_FILE="${config.sops.templates."octoprint/aws-credentials".path}"
          exec ${../../scripts/octoprint-notify.sh} "$@"
        '';
      };
    in
    {
      services.octoprint = {
        enable = true;
        package = octoprint-with-filamentmanager;
        host = "127.0.0.1";
        port = 5000;
        plugins =
          plugins: with plugins; [
            dashboard
            filamentmanager
            mqtt
            fullscreen
            resource-monitor
            marlingcodedocumentation
          ];
        extraConfig = {
          server = {
            onlineCheck.enabled = false;
            pluginBlacklist.enabled = false;
            # Trust Tailscale network for the "public access" IP check
            ipCheck.trustedSubnets = [ "100.64.0.0/10" ];
          };
          serial = {
            autoconnect = true;
            port = "/dev/serial/by-id/usb-Prusa_Research__prusa3d.com__Original_Prusa_i3_MK3_CZPX1420X004XK79619-if00";
          };
          webcam = {
            stream = "/webcam/api/stream.mjpeg?src=printer";
            snapshot = "/webcam/api/frame.jpeg?src=printer";
            ffmpeg = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
            timelapse = {
              type = "timed";
              fps = 25;
              postRoll = 3;
              options.interval = 10;
            };
          };
          plugins = {
            announcements = {
              _config_version = 1;
              channels = {
                _blog.read_until = 1765879200;
                _important.read_until = 1698310200;
                _octopi.read_until = 1746515700;
                _plugins.read_until = 1765324800;
                _releases.read_until = 1764593700;
              };
            };
            dashboard = {
              _config_version = 2;
              _webcamArray = [
                {
                  disableNonce = false;
                  flipH = null;
                  flipV = null;
                  name = "Default";
                  rotate = null;
                  streamRatio = "16:9";
                  url = "/webcam/api/stream.mjpeg?src=printer";
                }
              ];
              clearOn_Feedrate = "2";
              clearOn_Filament = "2";
              clearOn_LayerGraph = "1";
              clearOn_PrintThumbnail = "2";
              clearOn_PrinterMessage = "2";
              commandWidgetArray = [
                {
                  command = "echo \"47.6\" | bc";
                  enabled = false;
                  icon = "command-icon.png";
                  interval = "60";
                  name = "Simulated Chamber";
                  type = "3/4";
                }
              ];
              showJobControlButtons = true;
              showSystemInfo = true;
              showTempGaugeColors = true;
              showWebCam = true;
            };
            displaylayerprogress = {
              showAllPrinterMessages = false;
            };
            classicwebcam = {
              _config_version = 1;
              flipH = true;
              flipV = true;
              stream = "/webcam/api/stream.mjpeg?src=printer";
              snapshot = "/webcam/api/frame.jpeg?src=printer";
            };
            filamentmanager = {
              _config_version = 1;
              database.clientID = "ea6d5cb2-903f-11ea-bd70-dca6323bf0ec";
            };
            resource_monitor = {
              _config_version = 2;
            };
            # Nix manages all packages; disable pip-based plugin/update systems
            _disabled = [
              "pluginmanager"
              "softwareupdate"
            ];
          };
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
        };
      };

      services.go2rtc = {
        enable = true;
        settings.streams.printer = "exec:${rpicam-apps}/bin/rpicam-vid -t 0 --codec mjpeg --width 1920 --height 1080 --framerate 15 -q 80 -n -o -";
      };

      environment.systemPackages = [
        rpicam-apps
        pkgs.rpi.libcamera
        octoprint-notify
      ];

      users.users.octoprint.extraGroups = [
        "dialout"
        "video"
      ];

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
    };
}
