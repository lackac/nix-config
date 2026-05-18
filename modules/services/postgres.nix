{ ... }:
{
  flake.modules.darwin.postgres =
    {
      config,
      lib,
      pkgs,
      vars,
      ...
    }:
    let
      stateDir = "${config.home-manager.users.${vars.username}.xdg.stateHome}/postgresql";
      postgresqlPackage = pkgs.postgresql_18.withPackages (ps: [
        ps.pgvector
      ]);
    in
    {
      services.postgresql = {
        enable = true;
        package = postgresqlPackage;
        dataDir = "${stateDir}/18";
        initdbArgs = [
          "--encoding=UTF8"
          "--locale=en_US.UTF-8"
        ];
        enableTCPIP = false;
        authentication = lib.mkForce ''
          local all all trust
          host all all 127.0.0.1/32 trust
          host all all ::1/128 trust
        '';
      };

      launchd.user.agents.postgresql.serviceConfig = {
        StandardOutPath = "${stateDir}/stdout.log";
        StandardErrorPath = "${stateDir}/stderr.log";
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        echo "Setting up ${stateDir}..."
        mkdir -p "${stateDir}"
        chown ${vars.username}:staff "${stateDir}"
        chmod 700 "${stateDir}"
      '';
    };

  flake.modules.nixos.postgres =
    { pkgs, ... }:
    {
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_18;
        dataDir = "/var/lib/postgresql/18";
      };
    };
}
