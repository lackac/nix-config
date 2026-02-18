{ ... }:
{
  flake.modules.nixos.octoprint = {
    services.octoprint = {
      enable = true;
      host = "127.0.0.1";
      port = 5000;
      plugins =
        plugins: with plugins; [
          dashboard
          mqtt
          firmwareupdater
          fullscreen
          displaylayerprogress
          resource-monitor
          marlingcodedocumentation
        ];
      extraConfig = {
        serial = {
          autoconnect = true;
          port = "/dev/serial/by-id/usb-Prusa_Research__prusa3d.com__Original_Prusa_i3_MK3_CZPX1420X004XK79619-if00";
        };
      };
    };

    services.mjpg-streamer = {
      enable = true;
      inputPlugin = "input_uvc.so -r 640x480 -f 10 -d /dev/video0";
      outputPlugin = "output_http.so -w @www@ -n -p 8080";
    };

    users.users.octoprint.extraGroups = [
      "dialout"
      "video"
    ];
  };
}
