{ ... }:
{
  flake.modules.nixos.gitea =
    { ... }:
    {
      services.gitea = {
        enable = true;

        database = {
          type = "postgres";
          createDatabase = true;
          socket = "/run/postgresql";
          name = "gitea";
          user = "gitea";
        };

        settings = {
          server = {
            DOMAIN = "git.lackac.hu";
            ROOT_URL = "https://git.lackac.hu/";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
            DISABLE_SSH = true;
          };

          session = {
            COOKIE_SECURE = true;
          };
        };
      };

      services.caddy.extraConfig = ''
        git.lackac.hu {
          reverse_proxy 127.0.0.1:3000
        }
      '';
    };
}
