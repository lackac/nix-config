{config, ...}: let
  hostName = "beryllium";
in {
  programs.ssh.matchBlocks."github.com".identityFile = "${config.home.homeDirectory}/.ssh/${hostName}";
}
