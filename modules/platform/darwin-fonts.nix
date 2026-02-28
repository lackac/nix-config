{ ... }:
{
  flake.modules.darwin.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        material-design-icons
        font-awesome
        nerd-fonts.symbols-only
        nerd-fonts.fira-code
        nerd-fonts.caskaydia-cove
      ];
    };
}
