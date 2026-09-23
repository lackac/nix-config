{ inputs, ... }:
{
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
      ];

      xdg.configFile."opencode".source = config.lib.file.mkOutOfStoreSymlink repo;

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
