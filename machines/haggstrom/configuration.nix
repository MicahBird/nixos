{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "haggstrom"; # Define your hostname.
  boot.tmp.cleanOnBoot = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.groups = {
  snowflake = {
    gid = 1000;
    };
  };

  users.users.snowflake = {
    isNormalUser = true;
    description = "snowflake";
    group = "snowflake";
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
  };

  
  services = {
    flatpak.enable = true;
    dbus.enable = true;
    openssh.enable = true;
    desktopManager.plasma6.enable = true;
    nfs.server.enable = true;
    ollama = {
      enable = true;
      acceleration = "rocm";
      host = "0.0.0.0";
      openFirewall = true;
    };
    displayManager.ly = {
      enable = true;
      # Later me, invesigate config options: https://codeberg.org/AnErrupTion/ly/src/branch/master/src/config/Config.zig
      # settings = {
      #};
    };
    logind.extraConfig = ''
    HandlePowerKey=poweroff
    '';
  };

  services.flatpak.packages = [
    "com.heroicgameslauncher.hgl"
    "com.usebottles.bottles"
    "com.github.tchx84.Flatseal"
  ];
  
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    htop
    tmux
    git
    rsync
    busybox
    bluez-tools
    librewolf-bin
  ];

  networking = {
    firewall.allowedTCPPorts = [ 2049 ]; # NFS
    interfaces.eno1 = {
      useDHCP = false;
      ipv4.addresses = [{
        address = "192.168.1.119";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.1.1";
      interface = "enp3s0";
    };
    nameservers = ["192.168.1.1"];
  };


  hardware = {
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;
      bluetooth.package = pkgs.bluez;
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    cpu.amd = {
      updateMicrocode = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  jovian = {
    hardware = {
      has.amd.gpu = true;
      amd.gpu.enableBacklightControl = false;
    };
    steam = {
      updater.splash = "vendor";
      enable = true;
      autoStart = false;
      user = "snowflake";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = true;
    };
  };

  system.stateVersion = "24.11";
}
