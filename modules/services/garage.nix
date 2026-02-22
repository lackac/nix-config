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
      };

      sops.secrets."garage/adminToken" = {
        sopsFile = ../../secrets/boron.yaml;
      };

      sops.templates."garage/env".content = ''
        GARAGE_RPC_SECRET=${config.sops.placeholder."garage/rpcSecret"}
        GARAGE_ADMIN_TOKEN=${config.sops.placeholder."garage/adminToken"}
      '';

      # Caddy reverse proxy for S3 API
      services.caddy.extraConfig = ''
        s3.lackac.hu {
          reverse_proxy localhost:3900
        }
      '';
    };
}
