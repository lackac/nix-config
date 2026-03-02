{ ... }:
{
  flake.modules.homeManager.tmux-autostart =
    { ... }:
    {
      programs.zsh.loginExtra = ''
        if [[ -o INTERACTIVE && -t 2 && -z $TMUX && -z $ZSH_EXECUTION_STRING && -z $ZSH_SCRIPT && -z $ZED_TERM ]]; then
          tmux attach || sesh connect main || tmux new-session -s main
        fi
      '';
    };
}
