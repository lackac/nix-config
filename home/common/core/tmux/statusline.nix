{
  programs.tmux.extraConfig = ''
    ## Solarized colors
    # SOLARIZED TERMCOL   TMUX
    # --------- --------- ---------
    # base03    brblack   colour234
    # base02    black     colour235
    # base01    brgreen   colour240
    # base00    bryellow  colour241
    # base0     brblue    colour244
    # base1     brcyan    colour245
    # base2     white     colour254
    # base3     brwhite   colour230
    # yellow    yellow    colour136
    # orange    brred     colour166
    # red       red       colour160
    # magenta   magenta   colour125
    # violet    brmagenta  colour61
    # blue      blue       colour33
    # cyan      cyan       colour37
    # green     green      colour64

    set -g message-style "bg=colour109,fg=colour237"
    set -g message-command-style "bg=colour109,fg=colour237"
    set -g pane-border-style "fg=colour236"
    set -g pane-active-border-style "fg=colour109"
    set -g status-style "bg=colour237,none"
    set -g status-left " #S "
    set -g status-left-style "bg=colour166,fg=colour237,bold"
    set -g status-left-length "100"
    set -g status-right "#[fg=colour240,bg=colour237,nobold,nounderscore,noitalics] #(whoami)@#h #[fg=colour109] %F ∙ %a #[fg=colour237,bg=default] %R "
    set -g status-right-style "bg=colour109,none"
    set -g status-right-length "100"
    setw -g window-status-format " #I ∙ #W "
    setw -g window-status-current-format "#[fg=colour237,bg=colour109] #I ∙ #W ∙ #F #[default]"
    setw -g window-status-separator " "
    setw -g window-status-style "bg=colour237,fg=colour109,none"
    setw -g window-status-activity-style "bg=colour237,fg=colour109,underscore"

    # pane number display
    set -g display-panes-active-colour colour33
    set -g display-panes-colour colour167

    # clock
    setw -g clock-mode-colour colour64
  '';
}
