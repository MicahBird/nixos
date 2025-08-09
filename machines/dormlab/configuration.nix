# Heavily inspired by the following blog post: https://skogsbrus.xyz/building-a-router-with-nixos/
{ config, pkgs, lib, ... }:
let
  wan = "eno1";
  lan = "enp6s0";

  dhcpLease = "infinite";
  dnsMasqFormatDhcpHost = key: value: "${key},${value.ip}";
  formatHostName = key: value: "${value.ip} ${value.name}";
  dnsMasqFormatDhcpRange = x: "${x}.10,${x}.245,${dhcpLease}";
  mergeAttrSets = attrsets: builtins.foldl' lib.recursiveUpdate { } attrsets;

  dnsEnabledInterfaces = [ "br0" ];
  # dhcpEnabledIpSubnets = (map dnsMasqFormatDhcpRange [cfg.privateSubnet cfg.guestSubnet cfg.workSubnet ]);
  # staticIps = lib.mapAttrsToList dnsMasqFormatDhcpHost cfg.hosts;

  allowedUdpPorts = [
    # https://serverfault.com/a/424226
    # DNS
    53
    # DHCP
    67
    68
    # NTP
    123
    # Wireguard
    666
  ];
  allowedTcpPorts = [
    # https://serverfault.com/a/424226
    # SSH
    22
    # DNS
    53
    # HTTP(S)
    80
    443
    110
    # Email (pop3, pop3s)
    995
    114
    # Email (imap, imaps)
    993
    # Email (SMTP Submission RFC 6409)
    587
    # Git
    2222
  ];
  # inherit (lib) mapAttrs' genAttrs nameValuePair mkOption types mkIf mkEnableOption;

  # Router settings
  routerIp = "172.16.0.1";
in {

  imports = [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "dormlab"; # Define your hostname.
  boot.tmp.cleanOnBoot = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups = { snowflake = { gid = 1000; }; };
  security.sudo.wheelNeedsPassword = false;
  users.users.snowflake = {
    isNormalUser = true;
    description = "snowflake";
    group = "snowflake";
    extraGroups =
      [ "networkmanager" "wheel" "render" "video" "audio" "input" "docker" ];
  };

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services = { openssh.enable = true; };

  hardware = {
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
    bluetooth.package = pkgs.bluez;
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.amd = { updateMicrocode = true; };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  environment.systemPackages = with pkgs; [ ollama ];

  # Router
  boot = {
    kernel = {
      sysctl = {
        # Forward on all interfaces.
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
    };
  };

  networking.useDHCP = false;
  # request an IP from ISP
  networking.interfaces."${wan}".useDHCP = true;

  networking.firewall = {
    enable = false;
    trustedInterfaces = [ "br0" ];
    # Flush config on reload
    extraStopCommands = ''
      iptables -F
      iptables -t nat -F
      ip6tables -F
      ip6tables -t nat -F || true
    '';
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "${wan}";
  };

  networking.bridges = {
    br0 = {
      interfaces = [
        "${lan}"
        # wireless interface added by hostapd
      ];
    };
  };

  networking.interfaces = {
    br0 = {
      ipv4.addresses = [{
        address = "172.16.0.1";
        prefixLength = 24;
      }];
    };
  };

  networking.networkmanager.enable = false;

  services.dnsmasq = {
    enable = true;
    settings = mergeAttrSets [
      {
        # sensible behaviours
        domain-needed = true;
        bogus-priv = true;
        no-resolv = true;

        # upstream name servers
        server = [ "9.9.9.9" "1.1.1.1" ];
        expand-hosts = true;

        # # local domains
        # domain = "home";
        # local = "/home/";
      }
      { interface = dnsEnabledInterfaces; }
      {
        dhcp-range = "172.16.0.101,172.16.0.254";
      }
      # { dhcp-host = staticIps; }
    ];
  };

  services.tailscale = {
    enable = true;
    disableTaildrop = true;
    authKeyFile = "/home/snowflake/authKeyFile.txt";
    extraSetFlags = [
      "--advertise-exit-node"
      "--advertise-routes=172.16.0.0/24"
      "--accept-dns=false"
    ];
  };

  # # Define host names to make dnsmasq resolve them, e.g. http://router.home
  # networking.extraHosts =
  #   lib.concatStringsSep "\n" (lib.mapAttrsToList formatHostName cfg.hosts);

  # Old nixos-router config
  # # 1. Enable the router module.
  # router.enable = true;
  #
  # # 2. Configure the network interfaces.
  # router.interfaces = {
  #   # The WAN
  #   eno1 = {
  #     # # This interface will get its IP configuration from an upstream DHCP server (e.g., your ISP).
  #     # dhcpcd.enable = true;
  #     # Enable IPv4 packet forwarding on this interface.
  #     ipv4.enableForwarding = true;
  #   };
  #
  #   # The LAN 
  #   enp6s0 = {
  #     ipv4 = {
  #       # Enable IPv4 packet forwarding on this interface.
  #       enableForwarding = true;
  #
  #       # Configure the static IP address for the router on the LAN.
  #       addresses = [
  #         {
  #           address = "172.16.0.1";
  #           prefixLength = 24; # Corresponds to the 172.16.0.0/24 subnet.
  #         }
  #       ];
  #
  #       # Enable the Kea DHCP server to assign IP addresses to clients on the LAN.
  #       # It automatically uses the subnet defined in `addresses` above.
  #       kea.enable = true;
  #     };
  #   };
  #
  #   # Wi-Fi AP
  #   wlp4s0.hostapd.enable = true;
  # };
  #
  # # 3. Configure firewall rules in the default network namespace.
  # router.networkNamespaces.default = {
  #   nftables.textRules = ''
  #     # This ruleset provides basic firewalling and NAT (Network Address Translation).
  #
  #     # Table for filtering forwarded traffic.
  #     table inet filter {
  #       chain forward {
  #         type filter hook forward priority 0;
  #         # By default, drop all forwarded packets.
  #         policy drop;
  #
  #         # Allow traffic that is part of an established or related connection.
  #         # This is crucial for return traffic from the WAN to the LAN.
  #         ct state established,related accept;
  #
  #         # Allow new connections originating from the LAN and going to the WAN.
  #         iifname "${lan}" oifname "${wan}" accept;
  #       }
  #     }
  #
  #     # Table for Network Address Translation (NAT).
  #     table ip nat {
  #       chain postrouting {
  #         type nat hook postrouting priority 100;
  #
  #         # Perform masquerading (a form of NAT) for traffic from our LAN
  #         # subnet going out the WAN interface. This makes all LAN traffic
  #         # appear to come from the router's single public IP address.
  #         ip saddr 172.16.0.0/24 oifname "${wan}" masquerade;
  #       }
  #     }
  #   '';
  # };

  system.stateVersion = "25.05";
}
