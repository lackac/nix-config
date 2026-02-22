{ ... }:
{
  flake.modules.nixos.mattermost =
    { config, pkgs, ... }:
    {
      sops.secrets."garage/mattermostAccessKey" = {
        sopsFile = ../../secrets/carbon.yaml;
        owner = "mattermost";
        group = "mattermost";
      };

      sops.secrets."garage/mattermostSecretKey" = {
        sopsFile = ../../secrets/carbon.yaml;
        owner = "mattermost";
        group = "mattermost";
      };

      sops.templates."mattermost/env" = {
        owner = "mattermost";
        group = "mattermost";
        mode = "0400";
        content = ''
          MM_FILESETTINGS_AMAZONS3ACCESSKEYID=${config.sops.placeholder."garage/mattermostAccessKey"}
          MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY=${config.sops.placeholder."garage/mattermostSecretKey"}
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

          ImageProxySettings = {
            Enable = true;
            ImageProxyType = "local";
          };

          FileSettings = {
            DriverName = "amazons3";
            AmazonS3Bucket = "mattermost";
            AmazonS3Region = "garage";
            AmazonS3Endpoint = "s3.lackac.hu";
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
