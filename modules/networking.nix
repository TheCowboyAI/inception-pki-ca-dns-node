{ lib, pkgs, ... }:
{

  # networking = {
  #   hostName = "minio";
  #   # we REQUIRE this for zfs
  #   # 8 hexadecimal chars, unique in the network
  #   # CHANGE THIS
  #   hostId = "9f7c98b3";

  #   useDHCP = lib.mkDefault true;
  #   resolvconf.enable = false;
  #   dhcpcd.enable = true;
  #   useNetworkd = true;
  #   networkmanager.enable = true;
  #   wireless.enable = false;

  #   defaultGateway = {
  #     address = "172.16.0.1";
  #     interface = "enp1s0";
  #   };


  #   nameservers = [ "10.0.0.254" "1.1.1.1" ];

  #   # we should have a fixed IP
  #   interfaces = {
  #     enp1s0 = {
  #       useDHCP = false;
  #       ipv4.addresses = [
  #         {
  #           address = "172.16.0.2";
  #           prefixLength = 24;
  #         }
  #       ];
  #     };
  #   };

  #   # enable firewall and block all ports
  #   firewall.enable = true;
  #   firewall.allowedTCPPorts = [ 22 9000 9001 ];
  #   firewall.allowedUDPPorts = [ ];
  # };


  ### Original uncomment below
  # networking = {
  #   useDHCP = false;
  #   resolvconf.enable = false;
  #   dhcpcd.enable = false;
  #   dhcpcd.allowInterfaces = [ ];
  #   useNetworkd = false;
  #   networkmanager.enable = false;
  #   wireless.enable = false;
  #   interfaces = { };

  #   # enable firewall and block all ports
  #   firewall.enable = true;
  #   firewall.allowedTCPPorts = [ ];
  #   firewall.allowedUDPPorts = [ ];
  # };
  ### Original uncomment above


  networking.firewall = {
    enable = true;
    ## 9000 - prometheus node-exporter
    ## 8500 - step-ca
    allowedTCPPorts = [ 22 9000 80 443 8500 ];
    # allowedUDPPorts = [ ];
    # allowedUDPPortRanges = [
    #   { from = 4000; to = 4007; }
    #   { from = 8000; to = 8010; }
    # ];
  };
}
