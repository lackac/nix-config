{
  pkgs,
  lib,
  config,
  ...
}: {
  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-light.yaml";
    polarity = "light";

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
        terminal =
          if pkgs.stdenv.isDarwin
          then 14
          else 13;
      };
    };

    autoEnable = false;
    targets = {
      bat.enable = true;
      btop.enable = true;
      fzf.enable = true;
      kitty.enable = true;
      lazygit.enable = true;
      neovim.enable = true;
      starship.enable = true;
      yazi.enable = true;
    };
  };

  specialisation.dark.configuration.stylix = {
    base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";
    polarity = lib.mkForce "dark";
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "theme";
      runtimeInputs = with pkgs; [home-manager coreutils ripgrep];
      runtimeEnv = {
        XDG_RUNTIME_DIR = config.home.sessionVariables.XDG_RUNTIME_DIR;
      };
      excludeShellChecks = ["SC2018" "SC2019" "SC2086"];
      text = ''
        theme="''${1-}"

        if [[ -z $theme ]]; then
          # TODO: add support for Linux
          theme=$( (defaults read -g AppleInterfaceStyle 2>/dev/null || echo "light") | tr 'A-Z' 'a-z')
        fi

        current_gen=$(home-manager generations | head -1 | rg -o '/[^ ]*')
        if [[ -d $current_gen/specialisation ]]; then
          # this is the main generation
          if [[ $theme == "light" ]]; then
            # light is the default, so we don't need to do anything
            exit 0
          fi
          if [[ -x $current_gen/specialisation/$theme/activate ]]; then
            $current_gen/specialisation/$theme/activate
          fi
        else
          # this is likely a specialisation
          if [[ $theme == "light" ]]; then
            # let's look for the most recent generation with a specialisation
            # folder (which is likely the main generation) and activate it
            for gen in $(home-manager generations | head -5 | rg -o '/[^ ]*'); do
              if [[ -d $gen/specialisation ]]; then
                $gen/activate
                break
              fi
            done
          else
            # assuming we're in the dark specialisation already, so we bail
            exit 0
          fi
        fi

        # reload themed apps
        for socket_path in "''${XDG_RUNTIME_DIR}"/*; do
          if [[ -S "$socket_path" ]]; then
            socket="$(basename "$socket_path")"
            case "$socket" in
            kitty*)
              kitty @ --to "unix:$socket_path" load-config
              ;;
            nvim.*)
              pid="''${socket#nvim.}"
              pid="''${pid%.*}"
              if ps -p $pid > /dev/null; then
                nvim --server "$socket_path" --remote-expr "nvim_set_option('background', '$theme')"
              else
                rm -f "$socket_path"
              fi
              ;;
            esac
          fi
        done
      '';
    })
  ];
}
