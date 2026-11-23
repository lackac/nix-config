{ inputs, ... }:
{
  flake.modules.darwin.opencode-desktop =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2-desktop
      ];
    };

  flake.modules.homeManager.opencode =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      opencode = inputs.llm-agents.packages.${system}.opencode2;
      repo = "${config.home.homeDirectory}/Code/lackac/oc-config";
      target = "${config.xdg.configHome}/opencode";
    in
    {
      home.packages = [
        (pkgs.runCommand "opencode-cli" { } ''
          mkdir -p "$out/bin"
          ln -s ${opencode}/bin/opencode2 "$out/bin/opencode"
          ln -s ${opencode}/bin/opencode2 "$out/bin/oc"
        '')
        inputs.llm-agents.packages.${system}.opencode-browse
      ];

      xdg.configFile."opencode".source = config.lib.file.mkOutOfStoreSymlink repo;

      programs.zsh.initContent = ''
        if [[ ''${START_OPENCODE:-} == 1 ]]; then
          unset START_OPENCODE
          autoload -Uz add-zsh-hook

          # Run after direnv's precmd hook and keep the job in this shell for fg.
          _start_opencode() {
            add-zsh-hook -d precmd _start_opencode
            command opencode
            return 0
          }
          add-zsh-hook precmd _start_opencode
        fi
      '';

      home.activation.opencodeDirectory = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        if [ ! -f "${repo}/opencode.jsonc" ]; then
          echo "OpenCode config checkout missing: ${repo}" >&2
          exit 1
        fi
        if [ -d "${target}" ] && [ ! -L "${target}" ]; then
          echo "OpenCode config directory already exists: ${target}" >&2
          exit 1
        fi
      '';
    };
}
