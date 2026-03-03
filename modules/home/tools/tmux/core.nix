{ ... }:
{
  flake.modules.homeManager.tmux-core =
    { pkgs, ... }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
    in
    {
      programs.tmux = {
        enable = true;
        prefix = "C-a";
        baseIndex = 1;
        clock24 = true;
        escapeTime = 11;
        historyLimit = 50000;
        mouse = true;

        plugins = with pkgs; [
          tmuxPlugins.better-mouse-mode
          tmuxPlugins.extrakto
          tmuxPlugins.open
          tmuxPlugins.yank
          {
            plugin = tmuxPlugins.mkTmuxPlugin {
              pluginName = "smart-splits";
              rtpFilePath = "smart-splits.tmux";
              version = "v2.0.3";
              src = fetchFromGitHub {
                owner = "mrjones2014";
                repo = "smart-splits.nvim";
                rev = "v2.0.3";
                hash = "sha256-zfuBaSnudCWw0N1XAms9CeVrAuPEAPDXxLLg1rTX7FE=";
              };
            };

            extraConfig = ''
              bind-key -n C-Left if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
              bind-key -n C-Down if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
              bind-key -n C-Up if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
              bind-key -n C-Right if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'
            '';
          }
        ];

        extraConfig = ''
          set -g default-terminal "tmux-256color"

          set -sa terminal-features ",xterm-kitty:RGB"
          set -gq allow-passthrough on
          set -sa terminal-overrides ',*:Smulx=\E[4::%p1%dm'
          set -sa terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

          setw -g other-pane-height 15
          setw -g other-pane-width 80

          unbind s
          bind C-e switch-client -l
          bind C-a send-prefix

          unbind c
          bind c command-prompt "new-window -n '%%'"
          unbind s
          bind s command-prompt -p "SSH to:" "new-window -n '%1' 'ssh %1'"
          unbind w
          unbind "'"
          bind "'" choose-window
          bind C-s last-window

          unbind f
          bind f popup -E
          unbind l
          bind l popup -E -w 80% -h 80% lazygit
          bind g split-window -h -b -p 62 -c "#{pane_current_path}" lazygit
          bind v split-window -h -b -p 62 -c "#{pane_current_path}" nvim
          unbind m
          bind m command-prompt -p "man" "split-window -h 'exec man %%'"
          unbind %
          bind | split-window -h
          bind - split-window -v

          bind Left select-pane -L
          bind Down select-pane -D
          bind Up select-pane -U
          bind Right select-pane -R

          bind -r M-C-h select-window -t :-
          bind -r M-C-l select-window -t :+
          bind -r M-C-Left select-window -t :-
          bind -r M-C-Right select-window -t :+

          bind -r H resize-pane -L 5
          bind -r J resize-pane -D 5
          bind -r K resize-pane -U 5
          bind -r L resize-pane -R 5

          bind -r < resize-pane -L 5
          bind -r ( resize-pane -D 5
          bind -r ) resize-pane -U 5
          bind -r > resize-pane -R 5

          setw -g xterm-keys on
          setw -g mode-keys vi

          setw -g monitor-activity on
          set -g visual-activity off

          setw -g allow-rename off

          set -g set-titles on
          set -g set-titles-string '#S ∙ #I ∙ #W ∙ #T'

          ${
            if isDarwin then
              ''
                bind C-c run "tmux save-buffer - | pbcopy"
                bind C-v run "tmux set-buffer $(pbpaste); tmux paste-buffer"
              ''
            else
              ""
          }
        '';
      };
    };
}
