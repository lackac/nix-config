_:
#############################################################
#
#  beryllium - Mac Mini M1 8G
#
#############################################################
let
  hostname = "beryllium";
in {
  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;
}
