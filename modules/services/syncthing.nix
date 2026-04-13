{ lib, ... }:
{
  flake.modules.homeManager.syncthing =
    {
      osConfig ? null,
      vars,
      ...
    }:
    let
      localHostName =
        if builtins.isAttrs osConfig then
          lib.attrByPath [ "networking" "hostName" ] null osConfig
        else
          null;

      knownPeerIds = lib.filterAttrs (
        name: id: id != null && (localHostName == null || name != localHostName)
      ) vars.syncthing.deviceIds;

      peerAddresses = name: [
        "tcp://${name}:22000"
        "quic://${name}:22000"
      ];

      sharedFolderDevices = builtins.attrNames knownPeerIds;
    in
    {
      home.file."Code/.stignore".source = ./syncthing/code.stignore;

      services.syncthing = {
        enable = true;

        # Devices and folders can migrate into Nix incrementally. Keep undeclared
        # UI-managed state during the transition.
        overrideDevices = false;
        overrideFolders = false;

        settings = {
          # Mixed declarative and UI-managed topology is intentional for now.
          devices = lib.mapAttrs (name: id: {
            inherit id;
            addresses = peerAddresses name;
          }) knownPeerIds;

          folders = {
            code = {
              path = "~/Code";
              id = "code";
              label = "Code";
              devices = sharedFolderDevices;
            };

            life = {
              path = "~/Life";
              id = "life";
              label = "Life";
              devices = sharedFolderDevices;
            };
          };

          options = {
            globalAnnounceEnabled = false;
            localAnnounceEnabled = false;
            relaysEnabled = false;
            natEnabled = false;
          };
        };
      };
    };
}
