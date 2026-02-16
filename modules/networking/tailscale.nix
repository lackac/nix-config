_: {
  flake.modules.nixos.tailscale =
    { config, ... }:
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
        authKeyFile = config.sops.secrets."tailscale/authKey".path;
      };

      sops.secrets."tailscale/authKey" = {
        sopsFile = ../../secrets/common.yaml;
      };

      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };
}
