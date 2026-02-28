{ ... }:
{
  flake.modules.homeManager.yazi =
    { ... }:
    {
      programs.yazi = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        settings = {
          manager = {
            show_hidden = true;
            sort_dir_first = true;
          };
        };
      };
    };
}
