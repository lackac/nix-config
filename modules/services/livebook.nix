_:
let
  hostName = "lb.lackac.hu";
  port = 8080;
  iframePort = 8081;
  stateDirectory = "livebook";
in
{
  flake.modules.nixos.livebook =
    { config, vars, ... }:
    {
      users.groups.livebook-data = { };
      users.users.${vars.username}.extraGroups = [ "livebook-data" ];

      sops.secrets."livebook/password".sopsFile = ../../secrets/boron.yaml;
      sops.secrets."livebook/secretKeyBase".sopsFile = ../../secrets/boron.yaml;
      sops.secrets."livebook/cookie".sopsFile = ../../secrets/boron.yaml;

      sops.templates."livebook/env" = {
        mode = "0400";
        content = ''
          LIVEBOOK_PASSWORD=${config.sops.placeholder."livebook/password"}
          LIVEBOOK_SECRET_KEY_BASE=${config.sops.placeholder."livebook/secretKeyBase"}
          LIVEBOOK_COOKIE=${config.sops.placeholder."livebook/cookie"}
        '';
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/${stateDirectory} 2770 root livebook-data - -"
      ];

      virtualisation.oci-containers.containers.livebook = {
        image = "ghcr.io/livebook-dev/livebook:0.19.7";
        autoStart = true;
        ports = [
          "127.0.0.1:${toString port}:${toString port}"
          "127.0.0.1:${toString iframePort}:${toString iframePort}"
        ];
        volumes = [
          "/var/lib/${stateDirectory}:/data"
        ];
        environmentFiles = [ config.sops.templates."livebook/env".path ];
        environment = {
          LIVEBOOK_HOME = "/data";
          LIVEBOOK_IP = "::";
          LIVEBOOK_PORT = toString port;
          LIVEBOOK_IFRAME_PORT = toString iframePort;
          LIVEBOOK_PROXY_HEADERS = "x-forwarded-for,x-forwarded-proto";
        };
        extraOptions = [ "--pull=always" ];
      };

      services.caddy.extraConfig = ''
        ${hostName} {
          reverse_proxy 127.0.0.1:${toString port}
        }
      '';
    };
}
