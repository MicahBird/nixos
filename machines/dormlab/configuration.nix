# Heavily inspired by the following blog post: https://skogsbrus.xyz/building-a-router-with-nixos/
{ config, pkgs, lib, ... }:
let
  wan = "eno1";
  lan = "enp7s0";

  # TODO: Use these values and add hosts options similar to the above guide
  # dhcpLease = "infinite";
  # dnsMasqFormatDhcpHost = key: value: "${key},${value.ip}";
  # formatHostName = key: value: "${value.ip} ${value.name}";
  # dnsMasqFormatDhcpRange = x: "${x}.10,${x}.245,${dhcpLease}";
  mergeAttrSets = attrsets: builtins.foldl' lib.recursiveUpdate { } attrsets;

  dnsEnabledInterfaces = [ "br0" "wlp5s0" ];
  # dhcpEnabledIpSubnets = (map dnsMasqFormatDhcpRange [cfg.privateSubnet cfg.guestSubnet cfg.workSubnet ]);
  # staticIps = lib.mapAttrsToList dnsMasqFormatDhcpHost cfg.hosts;

  allowedUdpPorts = [
    # DNS
    53
  ];
  allowedTcpPorts = [
    # # SSH
    # 22
    # DNS
    53
  ];
  # inherit (lib) mapAttrs' genAttrs nameValuePair mkOption types mkIf mkEnableOption;

  # Router settings
  routerIp = "172.16.0.1";

  # ZFS Latest compatible kernel: https://wiki.nixos.org/wiki/ZFS
  zfsCompatibleKernelPackages = lib.filterAttrs (name: kernelPackages:
    (builtins.match "linux_[0-9]+_[0-9]+" name) != null
    && (builtins.tryEval kernelPackages).success
    && (!kernelPackages.${config.boot.zfs.package.kernelModuleAttribute}.meta.broken))
    pkgs.linuxKernel.packages;
  latestKernelPackage = lib.last
    (lib.sort (a: b: (lib.versionOlder a.kernel.version b.kernel.version))
      (builtins.attrValues zfsCompatibleKernelPackages));
in {

  imports = [ # Include the results of the hardware scan.
    /etc/nixos/hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "dormlab"; # Define your hostname.
  networking.hostId = "c8d8db12";
  boot.tmp.cleanOnBoot = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "nfs" "zfs" ];
  boot.initrd.kernelModules = [ "amdgpu" ];

  # ZFS
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/disk/by-id";
  services.zfs.autoScrub.enable = true;
  # Use latest kernel that is compatible with ZFS
  boot.kernelPackages = latestKernelPackage;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups = { snowflake = { gid = 1000; }; };
  security.sudo.wheelNeedsPassword = false;
  users.users.snowflake = {
    isNormalUser = true;
    uid = 1000;
    description = "snowflake";
    group = "snowflake";
    shell = pkgs.zsh;
    extraGroups =
      [ "networkmanager" "wheel" "render" "video" "audio" "input" "docker" "dialout" ];
  };

  programs.zsh.enable = true;
  programs.zsh.autosuggestions.enable = true;


  # User for gaming (no sudo privileges)
  users.groups = { gamer = { gid = 1001; }; };
  users.users.gamer = {
    isNormalUser = true;
    uid = 1001;
    description = "gamer";
    group = "gamer";
    extraGroups = [ "networkmanager" "render" "video" "audio" "input" "dialout" ];
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

  services = {
    openssh.enable = true;
    rpcbind.enable = true; # K3s - NFS
  };

  # Note that NFS shares on ZFS are created differently: https://nixos.wiki/wiki/ZFS#NFS_shares
  services.nfs.server.enable = true;

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

  environment.systemPackages = with pkgs; [
    ollama
    nfs-utils
    smartmontools
    gnome-disk-utility
    librewolf-bin
    ungoogled-chromium
    k9s
    distrobox
    w3m
    nvtopPackages.amd
    distrobox
    jetbrains.clion
    # Gaming
    steam-rom-manager
    # Emulators
    ryubing
  ];

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

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "br0" "${lan}" "tailscale0" "wlp5s0" ];
    # Flush config on reload
    extraStopCommands = ''
      iptables -F
      iptables -t nat -F
      ip6tables -F
      ip6tables -t nat -F || true
    '';

    # For an example of how to port forward spesific network traffic, reference: https://github.com/skogsbrus/os/blob/master/sys/router.nix

    interfaces = {
      "${wan}" = {
        allowedTCPPorts = allowedTcpPorts;
        allowedUDPPorts = allowedUdpPorts;
      };
    };
  };

  # Prevent sshd from opening port 22 (circumventing the firewall)
  services.openssh.openFirewall = false;

  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" "wlp5s0" ];
    externalInterface = "${wan}";
  };

  networking.bridges = {
    br0 = {
      interfaces = [
        "${lan}"
        # "wlp5s0"
        # Uncomment the above line to use the Wifi interface with hostapd
        
      ];
    };
  };

  networking.interfaces = {
    # WAN - request an IP from ISP
    "${wan}" = { useDHCP = true; };
    # enp2s0f0u1 = { useDHCP = true; };

    br0 = {
      ipv4.addresses = [{
        address = routerIp;
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

        dhcp-option = "6,${routerIp}";
        port = "0";
        except-interface = "lo";
        # Use blocky for DNS
        # # upstream name servers
        # server = [ "9.9.9.9" "1.1.1.1" ];
        # expand-hosts = true;

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

    
    # Working WIFI
    # services.hostapd = {
    #   enable = true;
    #   radios = {
    #     wlp5s0 = {
    #       channel = 6;
    #       countryCode = "US";
    #       settings = {
    #         logger_syslog = 127;
    #         logger_syslog_level = 2;
    #         logger_stdout = 127;
    #         logger_stdout_level = 2;
    #       };
    #       networks = {
    #         wlp5s0 = {
    #           ssid = "icecreamiscream";
    #           authentication = {
    #             wpaPassword = "bruh12345";
    #             # wpaPasswordFile = config.age.secrets.icecream_pw.path;
    #             mode = "wpa2-sha1";
    #           };
    #           logLevel = 2;
    #           # apIsolate = true;
    #         };
    #       };
    #       settings = {
    #         # Country code and 80211d are set manually to avoid 80211h when
    #         # countryCode is set (NIC seems to freak out when doing DFS)
    #         country_code = "US";
    #         ieee80211d = true;
    #       };
    #     };
    #   };
    # };

  # # Define host names to make dnsmasq resolve them, e.g. http://router.home
  # networking.extraHosts =
  #   lib.concatStringsSep "\n" (lib.mapAttrsToList formatHostName cfg.hosts);

  # Tailscale
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

  # Testing Invidious
  # services.invidious.enable = false;
  # services.invidious.settings = {
  #   default_user_preferences = {
  #     quality = "dash";
  #     quality_dash = "auto";
  #   };
  # };
  # services.invidious.sig-helper.enable = false;

  # K3s - https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/USAGE.md
  # When changing any of the options, reset the cluster: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/networking/cluster/k3s/docs/CLUSTER_UPKEEP.md
  services.k3s.package = pkgs.k3s_1_33; # Lock version
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.clusterInit = true;
  services.k3s.tokenFile = "/home/snowflake/k3sToken.txt";
  services.k3s.extraFlags = toString [
    ''--write-kubeconfig-mode "0644"''
    "--disable servicelb"
    # "--disable local-storage" # Needed for ArgoCD
    "--disable traefik"
    "--flannel-iface=br0"
    "--flannel-external-ip=false"
    "--node-ip=${routerIp}"
    "--advertise-address=${routerIp}"
    # "--debug" # Optionally add additional args to k3s
  ];

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
    oci-containers.containers = {
      # Ollama
      ollama = {
        # image = "ollama/ollama:rocm";
        image = "ollama/ollama:0.12.9-rocm";
        ports = [ "11434:11434" ];
        devices = [ "/dev/dri:/dev/dri" "/dev/kfd:/dev/kfd" ];
        volumes = [ "/home/snowflake/.ollama:/root/.ollama" ];
        extraOptions = [ "--pull=always" ];
      };
    };
  };

  services.frp = {
    enable = true;
    role = "client";
    settings = {
      auth.method = "token";
      # Workaround since secrets must be in plain text for frp
      # NOTE: When using builtins.readFile you MUST build a nix generation WITHOUT builtins.readFile FIRST, and then subsequent builds will work.
      serverAddr = lib.strings.trim
        (builtins.readFile config.age.secrets.frp-serverAddr.path);
      auth.token =
        lib.strings.trim (builtins.readFile config.age.secrets.frp-token.path);
      # Slight bruh moment
      serverPort = lib.strings.toInt (lib.strings.trim
        (builtins.readFile config.age.secrets.frp-serverPort.path));
      transport.tls.enable = true;
      proxies = [
        {
          name = "ollama";
          type = "tcp";
          localIP = "${routerIp}";
          localPort = 11434;
          remotePort = 5000;
        }
        {
          name = "nixos-ssh";
          type = "tcp";
          localIP = "${routerIp}";
          localPort = 22;
          remotePort = 5001;
        }
        # Gaming ports
        {
          name = "sunshine-47984";
          type = "tcp";
          localIP = "${routerIp}";
          localPort = 47984;
          remotePort = 47984;
        }
        {
          name = "sunshine-47989";
          type = "tcp";
          localIP = "${routerIp}";
          localPort = 47989;
          remotePort = 47989;
        }
        {
          name = "sunshine-47990";
          type = "tcp";
          localIP = "${routerIp}";
          localPort = 47990;
          remotePort = 47990;
        }
        {
          name = "sunshine-48010";
          type = "tcp";
          localIP = "${routerIp}";
          localPort = 48010;
          remotePort = 48010;
        }
        {
          name = "sunshine-47998-48000";
          type = "udp";
          localIP = "${routerIp}";
          localPort = 47998;
          remotePort = 47998;
        }
        {
          name = "sunshine-47999-48000";
          type = "udp";
          localIP = "${routerIp}";
          localPort = 47999;
          remotePort = 47999;
        }
        {
          name = "sunshine-48000-48000";
          type = "udp";
          localIP = "${routerIp}";
          localPort = 48000;
          remotePort = 48000;
        }
      ];
    };
  };

  # DNS - TODO: Blocking not working, no clue why
  networking.nameservers = [ "138.67.1.2" "138.67.1.3" ]; # Testing
  # networking.nameservers = [ "9.9.9.9" ]; # Testing
  services.blocky = {
    enable = true;
    settings = {
      ports.dns = 53; # Port for incoming DNS Queries.
      upstreams.groups.default = [
        # "9.9.9.9"
        # "149.112.112.112" # Quad 9
        "138.67.1.3"
        "138.67.1.2" # Mines DNS
      ];
      # # For initially solving DoH/DoT Requests when no system Resolver is available.
      # bootstrapDns = {
      #   upstream = "https://one.one.one.one/dns-query";
      #   ips = [ "9.9.9.9" "149.112.112.112" ]; # Quad 9
      # };
      #Enable Blocking of certain domains.
      blocking = {
        denylists = {
          #Adblocking
          ads = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts" # Pi-Hole Default block list
          ];
          #Another filter for blocking adult sites
          adult = [ "https://blocklistproject.github.io/Lists/porn.txt" ];
          #You can add additional categories
        };
        #Configure what block categories are used
        clientGroupsBlock = { "172.16.0.0/24" = [ "ads" "adult" ]; };
        blockType = "zeroIP";
      };
      log.level = "error";
    };
  };

  # GAMING ZONE!! 

  # Virutal Display - https://discourse.nixos.org/t/nixos-sunshine-setup-using-a-virtual-screen/64857/2
  boot.kernelParams = [ "video=DP-2:1920x1080R@60D" ];

  services.dbus.enable = true;
  services.desktopManager.plasma6.enable = true;

  security.rtkit.enable = true; # Enable RealtimeKit for audio purposes

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Progams 
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };

  # Sunshine for remote gaming
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # autoLogin.enable = true;
    # autoLogin.user = "gamer";
  };

  services.displayManager.autoLogin.user = "snowflake";
  services.displayManager.autoLogin.enable = true;

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.heroicgameslauncher.hgl"
    "com.usebottles.bottles"
    "com.github.tchx84.Flatseal"
  ];

  # Flatpak overrides
  services.flatpak.overrides = {
    "com.usebottles.bottles".Context = {
      # Allow Bottles to add Steam games
      filesystems = [
        "~/.local/share/Steam"
        "~/.var/app/com.valvesoftware.Steam/data/Steam"
      ];
    };
    "com.heroicgameslauncher.hgl".Context = {
      # Allow Bottles to add Steam games
      filesystems = [
        "~/.local/share/Steam"
        "~/.var/app/com.valvesoftware.Steam/data/Steam"
      ];
    };
  };

  # Auto TTY Login: https://discourse.nixos.org/t/autologin-for-single-tty/49427
  # systemd.services."getty@tty1" = {
  #   overrideStrategy = "asDropin";
  #   serviceConfig.ExecStart = [
  #     ""
  #     "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${pkgs.tmux}/bin/tmux new-session --autologin gamer --noclear --keep-baud %I 115200,38400,9600 $TERM"
  #   ];
  # };
  #
  # services.displayManager.ly = { enable = true; };

  system.stateVersion = "25.05";
}
