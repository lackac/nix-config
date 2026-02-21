{ ... }:
{
  flake.modules.nixos.octoprint-proxy =
    { config, pkgs, ... }:
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
          op.lackac.hu {
            handle_path /webcam/* {
              reverse_proxy 127.0.0.1:1984
            }

            handle {
              reverse_proxy 127.0.0.1:5000
            }
          }
        '';
      };

      sops.secrets."dnsimple/token" = { };

      sops.templates."caddy/env".content = ''
        DNSIMPLE_API_ACCESS_TOKEN=${config.sops.placeholder."dnsimple/token"}
      '';

      systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."caddy/env".path;

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    };
}
