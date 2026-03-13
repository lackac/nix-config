{ ... }:
{
  flake.modules.homeManager.git =
    { vars, pkgs, ... }:
    {
      home.packages = with pkgs; [
        delta
        git-lfs
        gh
        tea
      ];

      home.shellAliases = {
        gst = "git status -sb";
        gl = "git log --decorate --graph --pretty=\"%C(auto)%h%d %C(bold)%s %C(blue)%ar%Creset %ad\" --date=iso";
        glb = "gl --branches";
        glp = "git log -p --decorate";
        gco = "git checkout";
        gc = "git commit -v";
        gca = "git commit -v -a";
        gcp = "git cherry-pick";
        gp = "git push";
        gpu = "git push -u origin";
        gll = "git pull";
        gsps = "git stash && git pull && git stash pop";
      };

      programs.git = {
        enable = true;
        includes = [
          { path = "~/.config/git/local"; }
        ];
        ignores = [
          ".DS_Store"
          "*.orig"
          "*.rej"
          "*~"
          "*.swp"
          ".#*"
          "*.o"
          ".envrc"
          ".direnv/"
          ".bundle"
          "vendor/ruby/"
          ".irbrc"
          ".pryrc"
          "tags"
          ".tags"
          ".tags[0-9]"
          "devlog.md"
          ".private-journal"
        ];

        settings = {
          user = {
            name = vars.fullName;
            email = vars.email;
            signingkey = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF5ifzgwgrEKpUsQpIVw2vraFWQ/oqSgljIKUaP06QS6 git-signing";
          };

          alias = {
            br = "branch";
            co = "checkout";
            st = "status";
            dc = "diff --cached";
            update = "pull --rebase --autostash";
            foreach = "submodule foreach";
            start = "!git init && git commit --allow-empty -m \"chore: inception\"";
            human = "name-rev --name-only --refs=refs/heads/*";
            humin = "name-rev --refs=refs/heads/* --stdin";
            ls = "log --pretty=format:'%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]' --decorate";
            ll = "log --pretty=format:'%C(yellow)%h%Cred%d %Creset%s%Cblue [%cn]' --decorate --numstat";
            conflicts = "diff --name-only --diff-filter=U";
            resolve = "!git ls-files --unmerged | cut -c51- | sort -u | xargs git add";
          };

          url."ssh://git@github.com/".insteadOf = "https://github.com/";

          gpg.format = "ssh";
          commit.gpgsign = true;
          tag.gpgsign = true;

          init.defaultBranch = "main";
          fetch.prune = true;

          push = {
            autoSetupRemote = true;
            default = "simple";
            followTags = true;
          };

          pull.rebase = true;
          branch.autosetuprebase = "always";
          merge.conflictstyle = "zdiff3";
          rerere.enabled = true;

          rebase = {
            autosquash = true;
            autostash = true;
          };

          core.pager = "delta";
          interactive.diffFilter = "delta --color-only";

          delta = {
            navigate = true;
            diff-so-fancy = true;
            line-numbers = true;
            true-color = "always";
            detect-dark-light = "auto";
          };

          diff = {
            algorithm = "histogram";
            colorMoved = "default";
            colorMovedWS = "allow-indentation-change";
            submodule = "log";
          };

          status.submoduleSummary = true;
          submodule.recurse = true;
        };
      };

      programs.lazygit = {
        enable = true;
        settings = {
          gui = {
            showIcons = true;
            nerdFontsVersion = "3";
            showCommandLog = false;
          };

          git.autoFetch = false;
          confirmOnQuit = false;
        };
      };
    };
}
