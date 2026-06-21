{
  lib,
  ...
}:
let
  caddyWithDnsimple =
    pkgs:
    pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/dnsimple@v0.0.0-20251214142352-69317c3989f0" ];
      hash = "sha256-d0u7nd1neq5LuqLkVYbidWpD4ICRZpRkT0yCFpo1N3k=";
    };
in
{
  flake.modules.nixos.caddy =
    { pkgs, config, ... }:
    {
      services.caddy = {
        enable = true;
        package = caddyWithDnsimple pkgs;

        email = "admin@lackac.hu";
        globalConfig = ''
          acme_dns dnsimple {
            api_access_token {$DNSIMPLE_API_ACCESS_TOKEN}
          }
        '';
        extraConfig = ''
          mm.lackac.hu {
            reverse_proxy 127.0.0.1:8065
          }
        '';
      };

      sops.secrets."dnsimple/token" = {
        sopsFile = ../../secrets/common.yaml;
      };

      sops.templates."caddy/env".content = ''
        DNSIMPLE_API_ACCESS_TOKEN=${config.sops.placeholder."dnsimple/token"}
      '';

      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."caddy/env".path;
    };

  flake.modules.darwin.caddy =
    { config, pkgs, ... }:
    let
      caddyPackage = caddyWithDnsimple pkgs;
    in
    {
      sops = {
        secrets."dnsimple/token".sopsFile = ../../secrets/common.yaml;

        templates."caddy/env".content = ''
          DNSIMPLE_API_ACCESS_TOKEN=${config.sops.placeholder."dnsimple/token"}
        '';
      };

      environment.systemPackages = [
        caddyPackage
      ];

      environment.etc."caddy/darwin.Caddyfile".text = ''
        {
          local_certs
        }

        import /etc/caddy/local.d/*.caddy
      '';

      launchd.daemons.caddy = {
        command = ''
          /bin/sh -c 'set -a; . ${
            config.sops.templates."caddy/env".path
          }; set +a; exec ${caddyPackage}/bin/caddy run --config /etc/caddy/darwin.Caddyfile --adapter caddyfile'
        '';
        serviceConfig = {
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/var/log/caddy.log";
          StandardErrorPath = "/var/log/caddy.log";
        };
      };

      launchd.daemons.caddy.environment = {
        HOME = "/var/lib/caddy";
        XDG_DATA_HOME = "/var/lib/caddy/data";
        XDG_CONFIG_HOME = "/var/lib/caddy/config";
        XDG_CACHE_HOME = "/var/lib/caddy/cache";
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "Setting up /var/lib/caddy..."
        mkdir -p /var/lib/caddy/data /var/lib/caddy/config /var/lib/caddy/cache
        chmod 700 /var/lib/caddy
        chmod 700 /var/lib/caddy/data
        chmod 700 /var/lib/caddy/config
        chmod 700 /var/lib/caddy/cache
      '';
    };

  flake.modules.darwin.local-development-proxy =
    { pkgs, ... }:
    {
      services.dnsmasq = {
        enable = true;
        port = 5353;
        addresses.test = "127.0.0.1";
      };

      environment.systemPackages = [
        pkgs.dnsmasq
      ];

      environment.etc."caddy/local.d/placeholder.caddy".text = ''
        # Add project-specific local development routes in this directory.
        #
        # Example:
        # project.test, admin.project.test {
        #   tls internal
        #   reverse_proxy 127.0.0.1:5000
        # }
      '';
    };
}
