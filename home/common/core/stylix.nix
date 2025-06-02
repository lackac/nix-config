{pkgs, ...}: {
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";

    fonts = {
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };

      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };

      monospace = {
        package = pkgs.nerd-fonts.caskaydia-cove;
        name = "CaskaydiaCove Nerd Font Mono Light";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        terminal = if pkgs.stdenv.isDarwin then 14 else 13;
      };
    };

    autoEnable = false;
    targets = {
      bat.enable = true;
      fzf.enable = true;
      kitty.enable = true;
      lazygit.enable = true;
      neovim.enable = true;
      starship.enable = true;
      tmux.enable = true;
      yazi.enable = true;
    };
  };
}
