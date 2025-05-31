{
  pkgs,
  ...
}:
{
  programs.kitty = {
    enable = true;

    # kitty has catppuccin theme built-in,
    # all the built-in themes are packaged into an extra package named `kitty-themes`
    # and it's installed by home-manager if `theme` is specified.
    themeFile = "Catppuccin-Mocha";

    font = {
      name = "CaskaydiaCove Nerd Font Mono Light";
      size = if pkgs.stdenv.isDarwin then 14 else 13;
    };

    settings = {
      bold_font = "CaskaydiaCove Nerd Font Mono Semibold";
      italic_font = "CaskaydiaCove Nerd Font Mono Light Italic";
      bold_italic_font = "CaskaydiaCove Nerd Font Mono Semibold Italic";
      adjust_line_height = "100%";
      adjust_column_width = "100%";
      disable_ligatures = "cursor";
      confirm_os_window_close = "0";
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary no-append";
      macos_quit_when_last_window_closed = true;
      kitty_mod = if pkgs.stdenv.isDarwin then "cmd" else "ctrl+shift";
      clear_all_shortcuts = true;
    };

    keybindings = {
      "kitty_mod+c" = "copy_to_clipboard";
      "kitty_mod+v" = "paste_from_clipboard";
      "kitty_mod+n" = "new_os_window";
      "kitty_mod+equal" = "change_font_size all +2.0";
      "kitty_mod+minus" = "change_font_size all -2.0";
      "kitty_mod+0" = "change_font_size all 0";
      "kitty_mod+enter" = "toggle_fullscreen";
      "kitty_mod+f5" = "load_config_file";
      "alt+left" = "send_text all \x1b\x62";
      "alt+right" = "send_text all \x1b\x66";
      "alt+backspace" = "send_text all \x17";
      "alt+b" = "send_text all \eb";
      "alt+c" = "send_text all \ec";
      "alt+d" = "send_text all \ed";
      "alt+f" = "send_text all \ef";
      "alt+t" = "send_text all \et";
      "alt+." = "send_text all \e.";
    };

    extraConfig = ''
      allow_remote_control yes
      listen_on unix:$${HOME}/.local/state/kitty/kitty
    '';
  };
}
