{ lib, ... }: {
  options.vars = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "lackac";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Laszlo Bacsi";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "lackac@lackac.hu";
    };
    sshAuthorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINb0PBMOy7MjJoOJSmlQ2FG4deJJd8Gn8IaE+kDJbMYB lackac@lithium"
      ];
      description = "SSH public keys authorized across all hosts";
    };
  };
}
