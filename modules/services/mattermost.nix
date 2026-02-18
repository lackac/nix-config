{ ... }:
{
  flake.modules.nixos.mattermost =
    { pkgs, ... }:
    {
      services.mattermost = {
        enable = true;
        package = pkgs.mattermostLatest;
        siteUrl = "https://mm.lackac.hu";
        port = 8065;
        host = "127.0.0.1";
        mutableConfig = false;

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

          EmailSettings = {
            SendEmailNotifications = false;
            EnablePreviewModeBanner = false;
          };
        };
      };
    };
}
