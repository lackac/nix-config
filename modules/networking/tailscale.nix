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

  flake.modules.nixos.tailscale-home-router = {
    services.tailscale = {
      useRoutingFeatures = "server";
      extraSetFlags = [
        "--advertise-routes=10.7.0.0/16,192.168.107.0/24"
        "--advertise-exit-node"
        # Keep redundant routers from using each other's subnet routes.
        "--accept-routes=false"
      ];
    };
  };

  flake.modules.darwin.tailscale = {
    homebrew.casks = [
      "tailscale-app"
    ];
  };
}
