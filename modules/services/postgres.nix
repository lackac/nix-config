{ ... }: {
  flake.modules.nixos.postgres = { pkgs, ... }: {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
      dataDir = "/var/lib/postgresql/18";
    };
  };
}
