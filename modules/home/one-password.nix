{ config, inputs, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.darwin.onePassword = {
    homebrew.casks = [
      "1password"
      "1password-cli"
    ];

    home-manager.users.${vars.username}.imports = [ inputs.self.modules.homeManager.onePassword ];
  };

  flake.modules.homeManager.onePassword =
    {
      lib,
      config,
      ...
    }:
    let
      opAgentSock = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      opAgentSockSsh = lib.replaceStrings [ " " ] [ "\\ " ] opAgentSock;
      opPluginsPath = "${config.xdg.configHome}/op/plugins.sh";
    in
    {
      home.sessionVariables.SSH_AUTH_SOCK = opAgentSock;

      programs.ssh.matchBlocks."*".identityAgent = opAgentSockSsh;

      programs.bash.bashrcExtra = lib.mkAfter ''
        if [ -f "${opPluginsPath}" ]; then
          source "${opPluginsPath}"
        fi
      '';

      programs.zsh.initContent = lib.mkAfter ''
        if [ -f "${opPluginsPath}" ]; then
          source "${opPluginsPath}"
        fi

        if command -v op &>/dev/null; then
          eval "$(op completion zsh)"
          compdef _op op
        fi
      '';
    };
}
