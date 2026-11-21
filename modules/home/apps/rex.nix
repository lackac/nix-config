{ config, inputs, ... }:
{
  flake.modules.nixos.rex =
    {
      config,
      lib,
      vars,
      ...
    }:
    let
      rex = config.services.rex.package;
    in
    {
      imports = [ inputs.rex.nixosModules.default ];

      services.rex.loginServer = {
        enable = true;
        accounts.${vars.username}.principals = [ "tailscale:lackac@github" ];
        tailscaleServe = {
          enable = true;
          httpsPort = 7297;
        };
      };

      users.users.${vars.username}.linger = true;

      # Keep the personal server running for both native and SSH clients.
      systemd.user.services.rex = {
        description = "Personal Rex server";
        wantedBy = [ "default.target" ];
        unitConfig.ConditionUser = vars.username;
        environment = {
          TERMINFO_DIRS = "${rex}/share/terminfo:";
          REX_CGROUP_DELEGATED = "1";
        };
        serviceConfig = {
          Type = "notify";
          ExecStart = "${lib.getExe rex} server run --log-format text";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Delegate = true;
          DelegateSubgroup = "server";
        };
      };
    };

  flake.modules.darwin.rex = {
    home-manager.users.${config.vars.username}.imports = [ config.flake.modules.homeManager.rex ];
  };

  flake.modules.homeManager.rex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      repo = "${config.home.homeDirectory}/Code/lackac/rex-config";
      target = "${config.xdg.configHome}/rex";
      shellInit = ''
        if [ -n "''${REX_BIN_DIR:-}" ]; then
          export PATH="$REX_BIN_DIR:$PATH"
        fi
        ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
          # Match the app's macOS socket outside Rex, despite our shell's
          # XDG_RUNTIME_DIR. Explicit server selections remain untouched.
          rex() {
            if [ -z "''${REX_SERVER:-}" ]; then
              env -u XDG_RUNTIME_DIR rex "$@"
            else
              command rex "$@"
            fi
          }
        ''}
      '';
    in
    {
      imports = [ inputs.rex.homeManagerModules.default ];

      # The normally installed app owns its server and updates. This package
      # supplies the CLI, terminfo, and the Home Manager-managed SSH guard.
      programs.rex.enable = true;

      xdg.configFile."rex" = {
        source = config.lib.file.mkOutOfStoreSymlink repo;
        # Adopt the bootstrap symlink; rexDirectory still refuses a real directory.
        force = true;
      };

      # Finder-launched apps do not inherit the shell's Nix PATH.
      xdg.dataFile."rex/tools.lua" = {
        force = true;
        text = ''
          return {
            rex = "/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex",
            fzf = "${lib.getExe pkgs.fzf}",
            zoxide = "${lib.getExe pkgs.zoxide}",
            lazygit = "${lib.getExe pkgs.lazygit}",
            node = "${lib.getExe pkgs.nodejs}",
            direnv = "${lib.getExe pkgs.direnv}",
            zsh = "${lib.getExe pkgs.zsh}",
          }
        '';
      };

      programs.bash.bashrcExtra = lib.mkAfter shellInit;
      programs.zsh.initContent = lib.mkOrder 2000 shellInit;

      home.activation.rexDirectory = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        if [ ! -f "${repo}/init.lua" ]; then
          echo "Rex config checkout missing: ${repo}" >&2
          exit 1
        fi
        if [ -e "${target}" ] && [ ! -L "${target}" ]; then
          echo "Rex config directory already exists: ${target}" >&2
          exit 1
        fi
      '';
    };
}
