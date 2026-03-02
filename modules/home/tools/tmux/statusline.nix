{ ... }:
{
  flake.modules.homeManager.tmux-statusline =
    { ... }:
    {
      programs.tmux.extraConfig = ''
        set -g message-style "bg=colour109,fg=colour237"
        set -g message-command-style "bg=colour109,fg=colour237"
        set -g pane-border-style "fg=colour236"
        set -g pane-active-border-style "fg=colour109"
        set -g status-style "bg=colour237,none"
        set -g status-left " #S "
        set -g status-left-style "fg=colour237,bold"
        if-shell -b '[ "$(hostname -s)" = "lithium" ]' 'set -ag status-left-style "bg=colour166"' 'set -ag status-left-style "bg=colour61"'
        set -g status-left-length "100"
        set -g status-right "#[fg=colour240,bg=colour237,nobold,nounderscore,noitalics] #(whoami)@#h #[fg=colour109] %F ∙ %a #[fg=colour237,bg=default] %R "
        set -g status-right-style "bg=colour109,none"
        set -g status-right-length "100"
        setw -g window-status-format " #I ∙ #W "
        setw -g window-status-current-format "#[fg=colour237,bg=colour109] #I ∙ #W ∙ #F #[default]"
        setw -g window-status-separator " "
        setw -g window-status-style "bg=colour237,fg=colour109,none"
        setw -g window-status-activity-style "bg=colour237,fg=colour109,underscore"

        set -g display-panes-active-colour colour33
        set -g display-panes-colour colour167

        setw -g clock-mode-colour colour64
      '';
    };
}
