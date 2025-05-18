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
    librewolf-bin
  ];

  hardware = {
      bluetooth.enable = true;
      enableRedistributableFirmware = true;
    cpu.amd = {
      updateMicrocode = true;
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
      autoStart = true;
      user = "snowflake";
      desktopSession = "plasma";
    };
    steamos = {
      useSteamOSConfig = true;
    };
  };

  system.stateVersion = "24.11";
}
