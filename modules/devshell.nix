{ inputs, ... }: {
  perSystem = { pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        # Nix tools
        nil
        nixfmt-rfc-style

        # Secrets
        age
        sops
        ssh-to-age

        # Deployment
        inputs.colmena.packages.${system}.colmena
        nixos-anywhere
        nixos-rebuild

        # Utilities
        just
        pwgen
      ];
    };
  };
}
