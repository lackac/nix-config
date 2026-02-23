{ ... }:
{
  flake.modules.nixos.gitea =
    { ... }:
    {
      users.groups.git = { };

      users.users.git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/gitea";
        createHome = true;
        useDefaultShell = true;
      };

      services.gitea = {
        enable = true;
        user = "git";
        group = "git";

        database = {
          type = "postgres";
          createDatabase = true;
          socket = "/run/postgresql";
          name = "git";
          user = "git";
        };

        settings = {
          actions = {
            ENABLED = true;
            DEFAULT_ACTIONS_URL = "github";
          };

          log = {
            MODE = "console";
            LEVEL = "Info";
          };

          repository = {
            DEFAULT_BRANCH = "main";
            DEFAULT_REPO_UNITS = "repo.code,repo.releases";
          };

          server = {
            DOMAIN = "git.lackac.hu";
            ROOT_URL = "https://git.lackac.hu/";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
            DISABLE_SSH = false;
            START_SSH_SERVER = false;
            SSH_PORT = 22;
            SSH_USER = "git";
          };

          service = {
            DISABLE_REGISTRATION = true;
            SHOW_REGISTRATION_BUTTON = false;
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

      services.openssh.extraConfig = ''
        Match User git
          PasswordAuthentication no
          KbdInteractiveAuthentication no
          PermitTTY no
          AllowTcpForwarding no
          X11Forwarding no
          PermitTunnel no
      '';
    };
}
