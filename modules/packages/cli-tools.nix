{ ... }:
{
  flake.modules.homeManager.cli-tools =
    { pkgs, ... }:
    let
      leaf = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "leaf";
        version = "0.18.0";

        src = pkgs.fetchurl {
          url = "https://github.com/DeepanshuMishraa/leaf/releases/download/v${finalAttrs.version}/leaf-aarch64-apple-darwin.tar.gz";
          hash = "sha256-+Os8F87QWps3abnva1rIXd+zisY1DB7nJ/r0V0B+Qxo=";
        };

        sourceRoot = ".";
        installPhase = ''
          runHook preInstall
          install -Dm755 leaf "$out/bin/leaf"
          runHook postInstall
        '';

        meta = {
          description = "Terminal document reader and diff reviewer";
          homepage = "https://leaf.dipxsy.app/";
          license = pkgs.lib.licenses.mit;
          mainProgram = "leaf";
          platforms = [ "aarch64-darwin" ];
        };
      });
    in
    {
      home.packages = with pkgs; [
        btop
        doggo
        duf
        gdu
        ncdu
        fd
        jq
        just
        leaf
        ripgrep
        sad
        yt-dlp
        yq-go

        gnupg
        gnumake

        bc
        gcal
        ipcalc
        watch

        nix-output-monitor
        nix-init
        nix-melt
        nix-tree

        imagemagick
        pngpaste

        awscli2
        croc
        gogcli
        hunspell
      ];
    };
}
