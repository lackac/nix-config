{ config, ... }:
let
  inherit (config) vars;
in
{
  # NixOS common base
  flake.modules.nixos.common = { pkgs, ... }: {
    nix.settings = {
      trusted-users = [ "@wheel" vars.username ];
      experimental-features = [ "nix-command" "flakes" ];
    };

    environment.systemPackages = with pkgs; [
      git neovim curl wget htop btop fastfetch
      jq ripgrep fd tree rsync just
    ];

    environment.variables.EDITOR = "nvim";

    users.users.${vars.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = vars.sshAuthorizedKeys;
    };

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };
}
