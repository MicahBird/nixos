# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "ntfs" ];

  networking.hostName = "bricolage"; # Define your hostname.
  boot.tmp.cleanOnBoot = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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

  ### Services
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  programs.sway.xwayland.enable = true;
  services.displayManager.ly.enable = true;
  
  # enable sway window manager
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };
  security.pam.services.swaylock = {};

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware = {
      bluetooth.enable = true;
      enableRedistributableFirmware = true;
    cpu.amd = {
      updateMicrocode = true;
    };
  };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  services = {
      flatpak.enable = true;
      dbus.enable = true;
  };

  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [pkgs.xdg-desktop-portal-gtk];
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  systemd.services.NetworkManager-wait-online.enable = false;

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
    extraGroups = [ "networkmanager" "wheel" "video" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ ];
  };


  # Config working
  services.syncthing.enable = true;
  services.syncthing.systemService = true;
  services.syncthing.user = "snowflake";
  services.syncthing.group = "snowflake";
  services.syncthing.configDir = "/home/snowflake/.config/syncthing"; # Removed for flake

  programs.zsh.enable = true;
  programs.zsh.autosuggestions.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    htop
    ansible
    tmux
    neovim
    autojump
    kubectl
    kubernetes-helm
    k9s
    git
    gcc
    cmake
    llvm
    gnumake
    jdk
    localsend
    tree-sitter
    # CLI Tools
    cmus
    croc
    fzf
    bat
    jq
    fx
    fzf
    imagemagick
    ffmpeg
    exiftool
    ripgrep
    scrcpy
    espeak
    lf
    aria2
    p7zip
    unzip
    uv
    hugo
    dua
    tree
    usbutils
    curl
    zstd
    rclone
    tty-clock
    mpv
    qalculate-gtk
    hunspell
    cifs-utils
    chezmoi
    file
    cargo
    # Languages
    nodePackages_latest.nodejs
    python3
    foot
    android-tools
    audacity
    firefox
    gimp
    handbrake
    inkscape
    keepassxc
    kitty
    libreoffice
    moonlight-qt
    usbimager
    vscode
    tesseract
    # Linux spesific utils
    gnome-disk-utility
    nautilus
    openiscsi
    busybox
    pavucontrol
    networkmanagerapplet
    # Window manager utils
    autotiling
    waybar
    grim # screenshot functionality
    slurp # screenshot functionality
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    # mako # notification system developed by swaywm maintainer
    fuzzel
    nwg-panel
    nwg-look
    wdisplays
    shikane
    swaynotificationcenter
    lxqt.lxqt-policykit
    # Fonts & Icons
    ubuntu-sans
    ubuntu-classic
    morewaita-icon-theme
    colloid-gtk-theme
    gnome-themes-extra
  ];

  services.flatpak.packages = [
    "com.obsproject.Studio"
    "io.gitlab.librewolf-community"
    "io.github.ungoogled_software.ungoogled_chromium"
    "com.usebottles.bottles"
  ];
  
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" "Ubuntu" ]; })
  ];
  fonts.fontDir.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
  ];

  # List services that you want to enable:
  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  # services.openiscsi.enable = true;
  
  services.playerctld.enable = true;
  services.keyd.enable = true;
  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome.gvfs;
  };
  services.gnome.glib-networking.enable = true;
  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.blueman.enable = true;
  
  # keyd is the GOAT for being able to have capslock be control and ESC :)
  services.keyd.keyboards = {
    default = {
      ids = [ "*" ];
      settings = {
        main = {
          capslock = "overload(control, esc)";
        };
      };
    };
  };


  services.nfs.server.enable = true;
  services.rpcbind.enable = true;
  networking.firewall.allowedTCPPorts = [ 2049 ];

  # TEMP!!
  # services.globalprotect.enable = true;


  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
