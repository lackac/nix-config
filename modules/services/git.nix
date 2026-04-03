{ ... }:
{
  flake.modules.nixos.git =
    { pkgs, ... }:
    let
      forgejoPort = 3000;
    in
    {
      users.groups.git = { };

      users.users.git = {
        isSystemUser = true;
        group = "git";
        home = "/var/lib/forgejo";
        createHome = true;
        useDefaultShell = true;
      };

      services.forgejo = {
        enable = true;
        package = pkgs.forgejo;
        user = "git";
        group = "git";
        stateDir = "/var/lib/forgejo";

        database = {
          type = "postgres";
          createDatabase = false;
          socket = "/run/postgresql";
          name = "forgejo";
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
            LOCAL_ROOT_URL = "http://127.0.0.1:${toString forgejoPort}/";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = forgejoPort;
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
          reverse_proxy 127.0.0.1:${toString forgejoPort}
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
