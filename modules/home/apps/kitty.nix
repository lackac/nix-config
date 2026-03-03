{ ... }:
{
  flake.modules.homeManager.kitty =
    { ... }:
    {
      programs.kitty = {
        enable = true;
        shellIntegration.mode = null;
        autoThemeFiles = {
          light = "Solarized_Light";
          dark = "Solarized_Dark";
          noPreference = "Solarized_Dark";
        };
        font = {
          name = "CaskaydiaCove Nerd Font Mono Light";
          size = 14.0;
        };
        settings = {
          bold_font = "CaskaydiaCove Nerd Font Mono Semibold";
          italic_font = "CaskaydiaCove Nerd Font Mono Light Italic";
          bold_italic_font = "CaskaydiaCove Nerd Font Mono Semibold Italic";
          adjust_line_height = "100%";
          adjust_column_width = "100%";
          disable_ligatures = "cursor";
          font_features = "FiraCodeNerdFontCompleteM-Retina +zero";
          confirm_os_window_close = 0;
          clipboard_control = "write-clipboard write-primary read-clipboard read-primary no-append";
          macos_quit_when_last_window_closed = true;
          kitty_mod = "cmd";
          clear_all_shortcuts = true;
          kitten_alias = "hints hints --hints-offset=0";
        };
        keybindings = {
          "kitty_mod+c" = "copy_to_clipboard";
          "kitty_mod+v" = "paste_from_clipboard";
          "kitty_mod+s" = "paste_from_selection";
          "kitty_mod+o" = "pass_selection_to_program";
          "kitty_mod+n" = "new_os_window";
          "kitty_mod+equal" = "change_font_size all +2.0";
          "kitty_mod+minus" = "change_font_size all -2.0";
          "kitty_mod+0" = "change_font_size all 0";
          "kitty_mod+p>u" = "kitten hints";
          "kitty_mod+p>f" = "kitten hints --type path --program -";
          "kitty_mod+p>shift+f" = "kitten hints --type path";
          "kitty_mod+p>h" = "kitten hints --type hash --program -";
          "kitty_mod+p>n" = "kitten hints --type linenum --linenum-action=tab nvim +{line} {path}";
          "kitty_mod+enter" = "toggle_fullscreen";
          "kitty_mod+f5" = "load_config_file";
          "alt+left" = "send_text all \\x1b\\x62";
          "alt+right" = "send_text all \\x1b\\x66";
          "alt+backspace" = "send_text all \\x17";
          "alt+b" = "send_text all \\eb";
          "alt+c" = "send_text all \\ec";
          "alt+d" = "send_text all \\ed";
          "alt+f" = "send_text all \\ef";
          "alt+l" = "send_text all \\el";
          "alt+t" = "send_text all \\et";
          "ctrl+alt+h" = "send_key ctrl+alt+h";
          "ctrl+alt+l" = "send_key ctrl+alt+l";
          "ctrl+alt+left" = "send_key ctrl+alt+left";
          "ctrl+alt+right" = "send_key ctrl+alt+right";
          "alt+." = "send_text all \\e.";
          "alt+[" = "send_text all \\e[";
          "alt+]" = "send_text all \\e]";
        };
      };
    };
}
