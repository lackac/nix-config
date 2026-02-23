{ ... }:
{
  flake.modules.nixos."gitea-runner" =
    { config, pkgs, ... }:
    let
      hostName = config.networking.hostName;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      services.gitea-actions-runner.instances.${hostName} = {
        enable = true;
        name = "${hostName}-${system}";
        url = "https://git.lackac.hu";
        tokenFile = config.sops.templates."gitea-actions-runner/token.env".path;

        labels = [
          "${system}:host"
          "${hostName}:host"
        ];
      };

      sops.secrets."gitea/runnerRegistrationToken" = {
        sopsFile = ../../secrets/common.yaml;
      };

      sops.templates."gitea-actions-runner/token.env".content = ''
        TOKEN=${config.sops.placeholder."gitea/runnerRegistrationToken"}
      '';
    };
}
