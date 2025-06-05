{
  programs.sesh.settings.session = [
    {
      name = "home (~)";
      path = "~";
    }
    {
      name = "dot config";
      path = "~/.config";
    }
    {
      name = "nix config";
      path = "~/Code/lackac/nix-config";
      windows = [ "" "󰊢" ];
    }
    {
      name = "btop";
      path = "~";
      startup_command = "btop";
    }
  ];
}
