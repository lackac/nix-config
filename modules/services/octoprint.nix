{ ... }:
{
  flake.modules.nixos.octoprint =
    { pkgs, ... }:
    let
      rpicam-apps = pkgs.rpi.rpicam-apps.override {
        withDrmPreview = false;
        withQtPreview = false;
        withEglPreview = false;
        withOpenCVPostProc = false;
      };
    in
    {
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
          webcam = {
            stream = "/webcam/api/stream.mjpeg?src=printer";
            snapshot = "/webcam/api/frame.jpeg?src=printer";
            ffmpeg = "${pkgs.ffmpeg-headless}/bin/ffmpeg";
          };
        };
      };

      services.go2rtc = {
        enable = true;
        settings.streams.printer = "exec:${rpicam-apps}/bin/rpicam-vid -t 0 --codec mjpeg --width 1920 --height 1080 --framerate 15 -q 80 -n -o -";
      };

      environment.systemPackages = [
        rpicam-apps
        pkgs.rpi.libcamera
      ];

      users.users.octoprint.extraGroups = [
        "dialout"
        "video"
      ];
    };
}
