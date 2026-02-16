{ ... }: {
  flake.modules.nixos.secrets = {
    sops = {
      defaultSopsFile = null; # Each host sets its own
      age.keyFile = "/var/lib/sops-nix/key.txt";
    };
  };
}
