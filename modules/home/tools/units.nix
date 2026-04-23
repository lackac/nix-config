{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (config) vars;
  lithiumSecretsFile = ../../../secrets/lithium.yaml;
  lithiumSecretsText = builtins.readFile lithiumSecretsFile;
  lithiumHasUnitsSecret =
    lib.hasPrefix "units:" lithiumSecretsText || lib.hasInfix "\nunits:" lithiumSecretsText;
  mkRefreshCurrency =
    pkgs:
    pkgs.writeShellApplication {
      name = "units-refresh-currency";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.units
      ];
      text = builtins.readFile ./units/refresh-currency.sh;
    };
in
{
  flake.modules.homeManager.units =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      unitsStateDir = "${config.xdg.stateHome}/units";
      currencyFile = "${unitsStateDir}/currency.units";
      overlayFile = "${config.xdg.configHome}/units/overlay.units";
      refreshCurrency = mkRefreshCurrency pkgs;
    in
    {
      home.packages = [
        pkgs.units
        refreshCurrency
      ];

      home.sessionVariables.MYUNITSFILE = overlayFile;

      xdg.configFile."units/overlay.units".text = ''
        !include ${currencyFile}
      '';

      home.activation.unitsState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${unitsStateDir}"
        touch "${currencyFile}"
      '';
    };

  flake.modules.darwin.units =
    { pkgs, ... }:
    let
      refreshCurrency = mkRefreshCurrency pkgs;
    in
    {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];

      home-manager.users.${vars.username} =
        { config, ... }:
        let
          unitsStateDir = "${config.xdg.stateHome}/units";
        in
        {
          sops = {
            defaultSopsFile = lithiumSecretsFile;
            age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
            secrets = lib.mkIf lithiumHasUnitsSecret {
              "units/openexchangerates-app-id".path = "${config.xdg.configHome}/units/openexchangerates-app-id";
            };
          };

          launchd.agents.units-currency-refresh = {
            enable = true;
            config = {
              ProgramArguments = [ "${refreshCurrency}/bin/units-refresh-currency" ];
              RunAtLoad = true;
              StartCalendarInterval = builtins.genList (index: {
                Hour = index * 2;
                Minute = 0;
              }) 12;
              StandardOutPath = "${unitsStateDir}/refresh.log";
              StandardErrorPath = "${unitsStateDir}/refresh.error.log";
              EnvironmentVariables = {
                XDG_CONFIG_HOME = config.xdg.configHome;
                XDG_STATE_HOME = config.xdg.stateHome;
              };
            };
          };
        };
    };
}
