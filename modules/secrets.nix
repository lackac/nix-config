{ ... }: {
  flake.modules.nixos.secrets = {
    sops = {
      age.keyFile = "/var/lib/sops-nix/key.txt";
    };
  };
}
