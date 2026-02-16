{ ... }: {
  flake.modules.nixos.caddy = { pkgs, config, ... }: {
    services.caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/dnsimple@69317c3989f098249310c981d4bc9aebe2a4b559" ];
        hash = "sha256-J82XQgnl+K51sEY1FEb60Z+B71qyrEy00gMg2zBVJgA=";
      };

      email = "admin@lackac.hu";
      globalConfig = ''
        acme_dns dnsimple {
          token {$DNSIMPLE_TOKEN}
        }
      '';
      extraConfig = ''
        mm.lackac.hu {
          reverse_proxy 127.0.0.1:8065
        }
      '';
    };

    sops.secrets."dnsimple/token" = { };

    systemd.services.caddy.serviceConfig.EnvironmentFile =
      config.sops.secrets."dnsimple/token".path;
  };
}
