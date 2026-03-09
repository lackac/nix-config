{ lib, ... }:
{
  flake.modules.darwin.keyboard-layout =
    { ... }:
    {
      system.activationScripts.keyboard-layouts.text = lib.mkAfter ''
        echo "Installing keyboard layouts..." >&2
        install -d -m755 "/Library/Keyboard Layouts"
        install -m644 "${./keyboard-layouts/abc-exthun.keylayout}" "/Library/Keyboard Layouts/ABC – ExtHun.keylayout"
        install -m644 "${./keyboard-layouts/abc-exthun.icns}" "/Library/Keyboard Layouts/ABC – ExtHun.icns"
      '';

      system.defaults.CustomUserPreferences."com.apple.HIToolbox" = {
        AppleEnabledInputSources = [
          {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
          }
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = -4797;
            "KeyboardLayout Name" = "ABC – ExtHun";
          }
        ];
        AppleSelectedInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = -4797;
            "KeyboardLayout Name" = "ABC – ExtHun";
          }
        ];
      };
    };
}
