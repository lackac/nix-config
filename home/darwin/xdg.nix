{ config,  ...}:
{
  # enable management of XDG base directories on macOS.
  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/Library/Caches";
  };

  home.sessionVariables = {
    XDG_RUNTIME_DIR = "${config.home.homeDirectory}/Library/Caches/TemporaryItems/runtime";
  };
}
