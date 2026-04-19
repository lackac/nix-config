{ lib, ... }:
{
  flake.modules.darwin.keyboard-layout =
    { ... }:
    {
      system.activationScripts.extraActivation.text = lib.mkAfter ''
        rm -rf "/Library/Keyboard Layouts/ABC – ExtHun.bundle"
        rm -f "/Library/Keyboard Layouts/ABC – ExtHun.keylayout"
        rm -f "/Library/Keyboard Layouts/ABC – ExtHun.icns"
        cp -R "${./keyboard-layouts/abc-exthun.bundle}" "/Library/Keyboard Layouts/ABC – ExtHun.bundle"
      '';

      system.defaults.CustomUserPreferences."com.apple.HIToolbox" = {
        AppleEnabledInputSources = [
          {
            "Bundle ID" = "com.apple.CharacterPaletteIM";
            InputSourceKind = "Non Keyboard Input Method";
          }
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = -30646;
            "KeyboardLayout Name" = "ABC – ExtHun";
          }
        ];
        AppleSelectedInputSources = [
          {
            InputSourceKind = "Keyboard Layout";
            "KeyboardLayout ID" = -30646;
            "KeyboardLayout Name" = "ABC – ExtHun";
          }
        ];
      };
    };
}
