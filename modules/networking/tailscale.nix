{ ... }: {
  flake.modules.nixos.tailscale = { config, ... }: {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      authKeyFile = config.sops.secrets."tailscale/authKey".path;
    };

    sops.secrets."tailscale/authKey" = { };

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
