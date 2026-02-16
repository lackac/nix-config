{ ... }: {
  flake.modules.nixos.postgres = { pkgs, ... }: {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      dataDir = "/var/lib/postgresql/16";
    };
  };
}
