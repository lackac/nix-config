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

        settings."*" = {
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;
          ControlMaster = "auto";
          ControlPath = "/tmp/%r@%h:%p";
          ControlPersist = "yes";
        };
      };
    };
}
