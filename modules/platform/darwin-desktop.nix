{ config, lib, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.homeManager.darwin-desktop =
    { lib, osConfig, ... }:
    {
      targets.darwin.currentHostDefaults = lib.mkIf (osConfig.networking.hostName == "lithium") {
        NSGlobalDomain = {
          AppleEnableSwipeNavigateWithScrolls = false;
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.trackpad.fourFingerHorizSwipeGesture" = 2;
          "com.apple.trackpad.fourFingerVertSwipeGesture" = 2;
          "com.apple.trackpad.threeFingerDragGesture" = false;
          "com.apple.trackpad.threeFingerHorizSwipeGesture" = 1;
          "com.apple.trackpad.threeFingerVertSwipeGesture" = 0;
        };
      };
    };

  flake.modules.darwin.desktop =
    { ... }:
    {
      system.primaryUser = vars.username;

      security.pam.services.sudo_local.touchIdAuth = true;
      security.pam.services.sudo_local.reattach = true;

      time.timeZone = "Europe/Budapest";

      launchd.user.agents.remap-keys = {
        serviceConfig = {
          Label = "hu.lackac.remap-keys";
          ProgramArguments = [
            "/bin/sh"
            (builtins.toString (builtins.path { path = ../../scripts/remap-keys.sh; }))
          ];
          RunAtLoad = true;
        };
      };

      system.defaults = {
        dock = {
          autohide = true;
          show-recents = false;
          tilesize = 36;
          mru-spaces = false;
          expose-group-apps = true;
          showAppExposeGestureEnabled = true;
          showMissionControlGestureEnabled = true;
        };

        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          FXDefaultSearchScope = "SCcf";
          FXEnableExtensionChangeWarning = false;
          FXPreferredViewStyle = "Nlsv";
          QuitMenuItem = true;
          ShowPathbar = true;
          ShowStatusBar = true;
          ShowExternalHardDrivesOnDesktop = true;
          ShowHardDrivesOnDesktop = true;
          ShowMountedServersOnDesktop = true;
          ShowRemovableMediaOnDesktop = true;
          _FXShowPosixPathInTitle = false;
          _FXSortFoldersFirst = true;
        };

        loginwindow.GuestEnabled = false;
        menuExtraClock.Show24Hour = true;

        screencapture = {
          disable-shadow = true;
          location = "~/Documents/Screenshots";
          type = "png";
        };

        screensaver = {
          askForPassword = true;
        };

        spaces."spans-displays" = false;

        trackpad = {
          Clicking = true;
          TrackpadFourFingerHorizSwipeGesture = 2;
          TrackpadFourFingerVertSwipeGesture = 2;
          TrackpadRightClick = true;
          TrackpadThreeFingerHorizSwipeGesture = 1;
          TrackpadThreeFingerDrag = false;
          TrackpadThreeFingerVertSwipeGesture = 0;
        };

        WindowManager = {
          EnableStandardClickToShowDesktop = true;
          StandardHideDesktopIcons = false;
          HideDesktop = false;
          StageManagerHideWidgets = false;
          StandardHideWidgets = false;
        };

        NSGlobalDomain = {
          AppleEnableSwipeNavigateWithScrolls = false;
          AppleKeyboardUIMode = 3;
          ApplePressAndHoldEnabled = false;
          AppleShowScrollBars = "Always";
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          AppleSpacesSwitchOnActivate = true;
          NSTableViewDefaultSizeMode = 2;
          "com.apple.mouse.tapBehavior" = 1;
          "com.apple.keyboard.fnState" = true;
          "com.apple.swipescrolldirection" = true;
          "com.apple.trackpad.scaling" = 3.0;
          "com.apple.sound.beep.feedback" = 0;
          AppleInterfaceStyleSwitchesAutomatically = true;
          NSNavPanelExpandedStateForSaveMode = true;
          NSNavPanelExpandedStateForSaveMode2 = true;
        };

        CustomUserPreferences = {
          NSGlobalDomain.WebKitDeveloperExtras = true;
          "com.apple.desktopservices" = {
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
          "com.apple.ImageCapture".disableHotPlug = true;
        };
      };

      system.activationScripts.postActivation.text = lib.mkAfter ''
        sudo -u ${vars.username} /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';

      system.stateVersion = 6;
    };
}
