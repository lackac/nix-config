_: {
  flake.modules.nixos.caddy =
    { pkgs, config, ... }:
    {
      services.caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/dnsimple@v0.0.0-20251214142352-69317c3989f0" ];
          hash = "sha256-J82XQgnl+K51sEY1FEb60Z+B71qyrEy00gMg2zBVJgA=";
        };

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

      sops.secrets."dnsimple/token" = { };

      sops.templates."caddy/env".content = ''
        DNSIMPLE_API_ACCESS_TOKEN=${config.sops.placeholder."dnsimple/token"}
      '';

      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."caddy/env".path;
    };
}
