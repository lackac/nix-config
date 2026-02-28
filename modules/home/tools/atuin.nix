{ ... }:
{
  flake.modules.homeManager.atuin =
    { ... }:
    {
      programs.atuin = {
        enable = true;
        enableBashIntegration = true;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          dialect = "uk";
          inline_height = 25;
          common_subcommands = [
            "apt"
            "aws"
            "brew"
            "cargo"
            "colima"
            "composer"
            "dnf"
            "docker"
            "gh"
            "git"
            "go"
            "ip"
            "jj"
            "just"
            "kubectl"
            "mix"
            "nix"
            "nmcli"
            "npm"
            "oc"
            "op"
            "opencode"
            "pecl"
            "pnpm"
            "podman"
            "port"
            "sops"
            "systemctl"
            "tailscale"
            "tea"
            "tmux"
            "yarn"

            "100s"
            "cplus"
            "t"
          ];
        };
      };
    };
}
