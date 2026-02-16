{ ... }: {
  flake.modules.nixos.mattermost = { config, ... }: {
    services.mattermost = {
      enable = true;
      siteUrl = "http://${config.networking.hostName}:8065";
      port = 8065;
      host = "0.0.0.0";
      mutableConfig = false;
    };

    networking.firewall.interfaces."tailscale0" = {
      allowedTCPPorts = [ 8065 ];
    };
  };
}
