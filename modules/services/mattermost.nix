{ ... }: {
  flake.modules.nixos.mattermost = { config, ... }: {
    services.mattermost = {
      enable = true;
      siteUrl = "https://mm.lackac.hu";
      port = 8065;
      host = "127.0.0.1";
      mutableConfig = false;
    };
  };
}
