{ ... }:
{
  flake.modules.homeManager.hammerspoon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hsRepo = "${config.home.homeDirectory}/Code/lackac/hs-config";
      hsPrivateRepo = "${config.home.homeDirectory}/Code/lackac/hs-config-private";
    in
    {
      xdg.configFile."hammerspoon".source = config.lib.file.mkOutOfStoreSymlink hsRepo;

      home.activation.hammerspoonPrivateOverlay = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "${hsRepo}/.git" ] && [ -d "${hsPrivateRepo}/.git" ]; then
          ${pkgs.stow}/bin/stow \
            --dir "${hsPrivateRepo}" \
            --target "${hsRepo}" \
            --restow \
            .
        else
          echo "note: hammerspoon private overlay skipped (hs-config or hs-config-private missing)"
        fi
      '';
    };
}
