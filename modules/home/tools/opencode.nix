{ inputs, ... }:
{
  flake.modules.homeManager.opencode =
    { pkgs, ... }:
    {
      home.packages =
        let
          system = pkgs.stdenv.hostPlatform.system;
        in
        [
          inputs.oc-config.packages.${system}.opencode
          inputs.oc-config.packages.${system}.oh-my-opencode
        ];
    };
}
