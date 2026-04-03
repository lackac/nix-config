{ ... }:
{
  flake.modules.nixos."git-actions-runner" =
    { config, pkgs, ... }:
    let
      hostName = config.networking.hostName;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      services.gitea-actions-runner.package = pkgs.forgejo-runner;

      services.gitea-actions-runner.instances.${hostName} = {
        enable = true;
        name = "${hostName}-${system}";
        url = "https://git.lackac.hu";
        tokenFile = config.sops.templates."git-actions-runner/token.env".path;

        hostPackages = with pkgs; [
          bash
          coreutils
          curl
          gawk
          gitMinimal
          gnused
          nodejs
          wget
          nix
        ];

        labels = [
          "${system}:host"
          "${hostName}:host"
        ];
      };

      sops.secrets."git-actions-runner/runnerRegistrationToken" = {
        sopsFile = ../../secrets/common.yaml;
      };

      sops.templates."git-actions-runner/token.env".content = ''
        TOKEN=${config.sops.placeholder."git-actions-runner/runnerRegistrationToken"}
      '';
    };
}
