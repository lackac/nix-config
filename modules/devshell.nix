{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      lib,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages =
          (with pkgs; [
            # Nix tools
            nil
            nixfmt

            # Secrets
            age
            sops
            ssh-to-age

            # Deployment
            inputs.colmena.packages.${system}.colmena
            # nixos-anywhere and nixos-rebuild omitted:
            # they pull in upstream nix which shadows Determinate Nix.

            # Utilities
            git
            tea
            just
            pwgen
          ])
          ++ lib.optionals pkgs.stdenv.isDarwin [
            inputs.nix-darwin.packages.${system}.darwin-rebuild
          ];
      };
    };
}
