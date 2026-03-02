{ ... }:
{
  flake.modules.darwin.hammerspoon =
    { ... }:
    {
      system.defaults.CustomUserPreferences."org.hammerspoon.Hammerspoon" = {
        MJConfigFile = "~/.config/hammerspoon/init.lua";
      };
    };
}
