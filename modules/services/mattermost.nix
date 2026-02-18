{ ... }:
{
  flake.modules.nixos.mattermost =
    { config, pkgs, ... }:
    {
      sops.secrets."minio/mattermostAccessKey" = {
        sopsFile = ../../secrets/carbon.yaml;
        owner = "mattermost";
        group = "mattermost";
      };

      sops.secrets."minio/mattermostSecretKey" = {
        sopsFile = ../../secrets/carbon.yaml;
        owner = "mattermost";
        group = "mattermost";
      };

      sops.templates."mattermost/env" = {
        owner = "mattermost";
        group = "mattermost";
        mode = "0400";
        content = ''
          MM_FILESETTINGS_AMAZONS3ACCESSKEYID=${config.sops.placeholder."minio/mattermostAccessKey"}
          MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY=${config.sops.placeholder."minio/mattermostSecretKey"}
        '';
      };

      services.mattermost = {
        enable = true;
        package = pkgs.mattermostLatest;
        siteUrl = "https://mm.lackac.hu";
        port = 8065;
        host = "127.0.0.1";
        mutableConfig = false;
        environmentFile = config.sops.templates."mattermost/env".path;

        settings = {
          ServiceSettings = {
            SessionLengthWebInHours = 744;
            SessionLengthMobileInHours = 744;
            SessionLengthSSOInHours = 744;

            EnableSVGs = true;
            EnableLatex = true;
            EnableInlineLatex = true;

            EnableBotAccountCreation = true;
            EnablePostUsernameOverride = true;
            EnablePostIconOverride = true;
            EnableUserAccessTokens = true;
          };

          LogSettings = {
            ConsoleLevel = "INFO";
          };

          FileSettings = {
            DriverName = "amazons3";
            AmazonS3Bucket = "mattermost";
            AmazonS3Region = "us-east-1";
            AmazonS3Endpoint = "boron.at-larch.ts.net:9000";
            AmazonS3SSL = true;
          };

          EmailSettings = {
            SendEmailNotifications = false;
            EnablePreviewModeBanner = false;
          };
        };
      };
    };
}
