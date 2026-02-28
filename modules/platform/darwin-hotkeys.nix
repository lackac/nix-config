{ lib, ... }:
let
  hotkeyEnums = {
    missionControl = 32;
    applicationWindows = 33;
    missionControlDedicatedKey = 34;
    applicationWindowsDedicatedKey = 35;
    turnDockHidingOnOff = 52;
    selectPreviousInputSource = 60;
    selectNextInputSource = 61;
    moveLeftASpace = 79;
    moveLeftASpaceDedicatedKey = 80;
    moveRightASpace = 81;
    moveRightASpaceDedicatedKey = 82;
    showContextualMenu = 159;
  };

  disableHotKeys = with hotkeyEnums; [
    missionControl
    missionControlDedicatedKey
    applicationWindows
    applicationWindowsDedicatedKey
    turnDockHidingOnOff
    selectPreviousInputSource
    selectNextInputSource
    moveLeftASpace
    moveLeftASpaceDedicatedKey
    moveRightASpace
    moveRightASpaceDedicatedKey
    showContextualMenu
  ];

  appleSymbolicHotkeysSettings = lib.listToAttrs (
    map (id: {
      name = builtins.toString id;
      value = {
        enabled = false;
      };
    }) (lib.sort lib.lessThan disableHotKeys)
  );
in
{
  flake.modules.darwin.disable-hotkeys =
    { ... }:
    {
      system.defaults.CustomUserPreferences."com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = appleSymbolicHotkeysSettings;
      };
    };
}
