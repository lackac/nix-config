{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: {
  # `programs.git` will generate the config file: ~/.config/git/config
  # to make git use this config file, `~/.gitconfig` should not exist!
  #
  #    https://git-scm.com/docs/git-config#Documentation/git-config.txt---global
  home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    rm -f ${config.home.homeDirectory}/.gitconfig
  '';

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = myvars.userfullname;
    userEmail = myvars.useremail;

    # includes = [
    #   {
    #     # use different email & name for work
    #     path = "~/work/.gitconfig";
    #     condition = "gitdir:~/work/";
    #   }
    # ];

    extraConfig = {
      init.defaultBranch = "main";
      trim.bases = "dev,develop,master,main"; # for git-trim
      push.autoSetupRemote = true;
      pull.rebase = true;

      # replace https with ssh
      url = {
        "ssh://git@github.com/lackac" = {
          insteadOf = "https://github.com/lackac";
        };
        # "ssh://git@gitlab.com/" = {
        #   insteadOf = "https://gitlab.com/";
        # };
        # "ssh://git@bitbucket.com/" = {
        #   insteadOf = "https://bitbucket.com/";
        # };
      };
    };

    # signing = {
    #   key = "xxx";
    #   signByDefault = true;
    # };

    # A syntax-highlighting pager in Rust(2019 ~ Now)
    delta = {
      enable = true;
      options = {
        diff-so-fancy = true;
        line-numbers = true;
        true-color = "always";
        # features => named groups of settings, used to keep related settings organized
        # features = "";
      };
    };

    aliases = {
      br = "branch";
      co = "checkout";
      st = "status";
      dc = "diff --cached";
      update = "submodule update --init --recursive";
      foreach = "submodule foreach";

      start = "!git init && git commit --allow-empty -m \"chore: inception\"";
      ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
      ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
      cl = "log -n25 --no-merges --date=short --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cd)%Creset' -- lib";
      conflicts = "!git ls-files --unmerged | cut -c51- | sort -u | xargs $EDITOR";
      resolve = "!git ls-files --unmerged | cut -c51- | sort -u | xargs git add";
      headless = "!sh -c 'git symbolic-ref HEAD refs/heads/$0 && rm .git/index && git clean -fdx'";
      human = "name-rev --name-only --refs=refs/heads/*";
      humin = "name-rev --refs=refs/heads/* --stdin";
    };
  };
}
