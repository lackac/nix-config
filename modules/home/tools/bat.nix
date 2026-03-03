{ ... }:
{
  flake.modules.homeManager.bat =
    { ... }:
    {
      programs.bat = {
        enable = true;
        config = {
          pager = "less -FR";
          style = "plain";
          theme = "auto";
          "theme-light" = "Solarized (light)";
          "theme-dark" = "Solarized (dark)";
        };
      };

      home.shellAliases = {
        batw = "bat --wrap=character";
      };
    };
}
