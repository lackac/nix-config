{ config, inputs, ... }:
{
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
            tree = "${lib.getExe pkgs.tree}",
            lazygit = "${lib.getExe pkgs.lazygit}",
            python3 = "${lib.getExe pkgs.python3}",
            direnv = "${lib.getExe pkgs.direnv}",
            zsh = "${lib.getExe pkgs.zsh}",
            extrakto = "${pkgs.tmuxPlugins.extrakto}/share/tmux-plugins/extrakto/extrakto.py",
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
