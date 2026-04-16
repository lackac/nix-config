{ ... }:
{
  flake.modules.homeManager.ghostty =
    { pkgs, ... }:
    {
      programs.ghostty = {
        enable = true;
        package = pkgs.ghostty-bin;
        settings = {
          theme = "light:iTerm2 Solarized Light,dark:iTerm2 Solarized Dark";
          font-family = "CaskaydiaCove Nerd Font Mono Light";
          font-family-bold = "CaskaydiaCove Nerd Font Mono Semibold";
          font-family-italic = "CaskaydiaCove Nerd Font Mono Light Italic";
          font-family-bold-italic = "CaskaydiaCove Nerd Font Mono Semibold Italic";
          font-feature = "+zero";
          font-size = 14;
          cursor-style = "block";
          copy-on-select = false;
          shell-integration = "detect";
          shell-integration-features = "no-cursor";
          confirm-close-surface = false;
          quit-after-last-window-closed = true;
          macos-option-as-alt = false;
          window-save-state = "always";
          keybind = [
            "super+f5=reload_config"
            "alt+arrow_left=esc:b"
            "alt+arrow_right=esc:f"
            "alt+backspace=text:\\x17"
            "alt+b=esc:b"
            "alt+c=esc:c"
            "alt+d=esc:d"
            "alt+f=esc:f"
            "alt+l=esc:l"
            "alt+t=esc:t"
            "alt+.=esc:."
            "alt+[=esc:["
            "alt+]=esc:]"
          ];
        };
      };
    };
}
