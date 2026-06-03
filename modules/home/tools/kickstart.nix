{ config, self, ... }:
let
  templateNames = builtins.filter (name: name != "default") (
    builtins.attrNames config.flake.templates
  );
  templateWords = builtins.concatStringsSep " " templateNames;
in
{
  flake.modules.homeManager.kickstart =
    { pkgs, ... }:
    let
      scriptText = builtins.replaceStrings [ "@templateFlake@" ] [ (toString self) ] (
        builtins.readFile ./kickstart.sh
      );

      script = pkgs.writeShellApplication {
        name = "kickstart";
        runtimeInputs = [
          pkgs.git
          pkgs.jq
        ];
        text = scriptText;
      };

      completionText =
        builtins.replaceStrings
          [
            "@mix@"
            "@templateWords@"
          ]
          [
            "${pkgs.beam28Packages.elixir_1_20}/bin/mix"
            templateWords
          ]
          (builtins.readFile ./_kickstart);

      completions = pkgs.runCommand "kickstart-completions" { } ''
        mkdir -p $out/share/zsh/site-functions
        cp ${pkgs.writeText "_kickstart" completionText} $out/share/zsh/site-functions/_kickstart
      '';

      package = pkgs.symlinkJoin {
        name = "kickstart";
        paths = [
          script
          completions
        ];
      };
    in
    {
      home.packages = [ package ];
    };
}
