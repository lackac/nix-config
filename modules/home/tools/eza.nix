{ ... }:
{
  flake.modules.homeManager.eza =
    { ... }:
    {
      programs.eza = {
        enable = true;
        git = true;
        icons = "auto";
      };

      home.shellAliases = {
        ls = "eza";
        l = "ls -l";
        la = "ls -a";
        lla = "ls -la";
        lk = "eza -l --sort=size";
        lt = "eza -l --sort=modified";
        lc = "eza -l --sort=changed";
        lu = "eza -l --sort=accessed";
        tree = "eza --tree";
      };
    };
}
