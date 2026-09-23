{ ... }:
{
  flake.modules.homeManager.tmux-autostart =
    { ... }:
    {
      programs.zsh.loginExtra = ''
        # Ghostty retains its launch environment for new windows. Discard tmux
        # metadata inherited from an older server before deciding to autostart.
        if [[ -n ''${TMUX:-} ]]; then
          tmux_env_server_pid="''${''${TMUX#*,}%%,*}"
          tmux_server_pid="$(tmux display-message -p '#{pid}' 2>/dev/null || true)"
          if [[ "$tmux_env_server_pid" != "$tmux_server_pid" ]]; then
            unset TMUX TMUX_PANE
          fi
        fi

        if [[ -o INTERACTIVE && -t 2 && -z $TMUX && -z $ZSH_EXECUTION_STRING && -z $ZSH_SCRIPT && -z $ZED_TERM ]]; then
          tmux attach || sesh connect main || tmux new-session -s main
        fi
      '';
    };
}
