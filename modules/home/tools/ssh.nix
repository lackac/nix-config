{ ... }:
{
  flake.modules.homeManager.ssh =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        includes = lib.optionals isDarwin [
          "~/.ssh/config.local"
          "${config.home.homeDirectory}/.colima/ssh_config"
        ];

        extraOptionOverrides = lib.optionalAttrs isDarwin {
          IgnoreUnknown = "UseKeychain";
          UseKeychain = "yes";
        };

        matchBlocks."*" = {
          serverAliveInterval = 60;
          serverAliveCountMax = 3;
          controlMaster = "auto";
          controlPath = "/tmp/%r@%h:%p";
          controlPersist = "yes";
        };
      };
    };
}
