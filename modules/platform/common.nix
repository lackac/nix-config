{ config, lib, ... }:
let
  inherit (config) vars;

  commonPackages =
    pkgs: with pkgs; [
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
    ];

  commonBase = pkgs: {
    environment.systemPackages = commonPackages pkgs;

    environment.variables.EDITOR = lib.mkForce "nvim";

    users.users.${vars.username}.openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;

    services.openssh.enable = true;
  };
in
{
  # NixOS common base
  flake.modules.nixos.common =
    { pkgs, ... }:
    lib.mkMerge [
      (commonBase pkgs)
      {
        nix.settings = {
          trusted-users = [
            "@wheel"
            vars.username
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };

        users.users.${vars.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };

        services.openssh = {
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
        };
      }
    ];

  flake.modules.darwin.common =
    { pkgs, lib, ... }:
    lib.mkMerge [
      (commonBase pkgs)
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
          m-cli
          ruby
          python3
        ];

        users.users.${vars.username} = {
          home = "/Users/${vars.username}";
        };

        services.openssh = {
          extraConfig = ''
            PasswordAuthentication no
            KbdInteractiveAuthentication no
          '';
        };

        programs.zsh.enable = true;
        environment.shells = [ pkgs.zsh ];
      }
    ];
}
