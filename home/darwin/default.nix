{
  mylib,
  myvars,
  ...
}: {
  home.homeDirectory = "/Users/${myvars.username}";
  imports =
    (mylib.scanPaths ./.)
    ++ [
      ../common/core
      ../common/tui
      ../common/gui
      ../common/home.nix
    ];

  # enable management of XDG base directories on macOS.
  xdg.enable = true;
}
