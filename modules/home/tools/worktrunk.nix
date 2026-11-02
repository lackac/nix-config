{ ... }:
{
  flake.modules.homeManager.worktrunk =
    { ... }:
    {
      programs.worktrunk = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;

        settings = {
          worktree-path = "{{ repo_path }}/../{{ repo }}--{{ branch | sanitize }}";
          pre-start.copy = "wt step copy-ignored";

          # Cover whole ignored directories and ignored children of tracked directories.
          # Root anchors keep similarly named dependency directories intact.
          step.copy-ignored.exclude = [
            "/.direnv/"
            "/.direnv/**"
            "/.devenv/"
            "/.devenv/**"
            "/tmp/"
            "/tmp/**"
            "/log/"
            "/log/**"
            "/logs/"
            "/logs/**"
          ];
        };
      };
    };
}
