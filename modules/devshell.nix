{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Nix tools
          nil
          nixfmt

          # Secrets
          age
          sops
          ssh-to-age

          # Deployment
          inputs.colmena.packages.${system}.colmena
          # nixos-anywhere and nixos-rebuild omitted: they pull in upstream nix
          # which shadows Determinate Nix. Run via `nix run` when needed.

          # Utilities
          git
          just
          opentofu
          pwgen
        ];
      };
    };
}
