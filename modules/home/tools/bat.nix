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
        };
      };

      home.shellAliases = {
        batw = "bat --wrap=character";
      };
    };
}
