{lib}: rec {
  mainGateway = "10.7.0.1"; # main router
  nameservers = [
    "45.90.28.171"
    "45.90.30.171"
  ];
  prefixLength = 24;

  hostsAddr = {
    # example = {
    #   iface = "en1";
    #   ipv4 = "10.7.0.42";
    # };
  };

  hostsInterface =
    lib.attrsets.mapAttrs
    (
      key: val: {
        interfaces."${val.iface}" = {
          useDHCP = false;
          ipv4.addresses = [
            {
              inherit prefixLength;
              address = val.ipv4;
            }
          ];
        };
      }
    )
    hostsAddr;

  ssh = {
    # define the host alias for remote builders
    # this config will be written to /etc/ssh/ssh_config
    #
    # Config format:
    #   Host —  given the pattern used to match against the host name given on the command line.
    #   HostName — specify nickname or abbreviation for host
    #   IdentityFile — the location of your SSH key authentication file for the account.
    # Format in details:
    #   https://www.ssh.com/academy/ssh/config
    extraConfig =
      ''
      ''
      + (lib.attrsets.foldlAttrs
        (acc: host: val:
          acc
          + ''
            Host ${host}
              HostName ${val.ipv4}
              Port 22
          '')
        ""
        hostsAddr);

    # this config will be written to /etc/ssh/ssh_known_hosts
    knownHosts =
      # Update only the values of the given attribute set.
      #
      #   mapAttrs
      #   (name: value: ("bar-" + value))
      #   { x = "a"; y = "b"; }
      #     => { x = "bar-a"; y = "bar-b"; }
      lib.attrsets.mapAttrs
      (host: value: {
        hostNames = [host] ++ (lib.optional (hostsAddr ? host) hostsAddr.${host}.ipv4);
        publicKey = value.publicKey;
      })
      {
        # Define the root user's host key for remote builders, so that nix can verify all the remote builders

        # example.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl root@example";
        # ruby.publicKey = "";
        # kana.publicKey = "";

        # ==================================== Other SSH Service's Public Key =======================================

        # https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
        "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
  };
}
