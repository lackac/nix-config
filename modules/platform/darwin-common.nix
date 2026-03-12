{ config, ... }:
let
  inherit (config) vars;
in
{
  flake.modules.darwin.common =
    { pkgs, ... }:
    {
      # Determinate Nix owns the daemon.
      nix.enable = false;

      # Workaround: https://github.com/NixOS/nix/issues/7273
      nix.settings.auto-optimise-store = false;

      nix.gc.automatic = false;

      nix.settings = {
        trusted-users = [ vars.username ];
        substituters = [ "https://nix-community.cachix.org" ];
        trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
        builders-use-substitutes = true;
      };

      environment.systemPackages = with pkgs; [
        git
        neovim
        curl
        wget
        htop
        btop
        fastfetch
        jq
        ripgrep
        fd
        tree
        rsync
        just
        ruby
        python3
      ];

      environment.variables.EDITOR = "nvim";

      users.users.${vars.username} = {
        home = "/Users/${vars.username}";
        openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
      };

      services.openssh = {
        enable = true;
        extraConfig = ''
          PasswordAuthentication no
          KbdInteractiveAuthentication no
        '';
      };

      programs.zsh.enable = true;
      environment.shells = [ pkgs.zsh ];
    };
}
