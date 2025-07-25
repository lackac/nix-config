{
  pkgs,
  nvf-config,
  ...
}: {
  home.packages = [
    nvf-config.packages.${pkgs.system}.default
  ];
}
