{
  programs.zsh.loginExtra = ''
    # Execute code only if STDERR is bound to a TTY but not already in a TMUX session.
    if [[ -o INTERACTIVE && -t 2 && -z $TMUX && -z $ZSH_EXECUTION_STRING && -z $ZSH_SCRIPT && -z $ZED_TERM ]]; then
      # Enter tmux (attach to existing session or start a new one)
      tmux attach || tmux new-session -s main
    fi
  '';
}
