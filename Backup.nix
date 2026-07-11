{ config, pkgs, ... }:{

  imports = [
    ./hardware-configuration.nix
  ];

  # Force Nvidia Modesetting on Boot
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # Bootloader configuration for UEFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  # NixOS State Version safety rule
  system.stateVersion = "26.05";

  # Enable networking & NetworkManager
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.networkmanager.dns = "none";

  # Set your time zone
  time.timeZone = "Asia/Yangon";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
 
  # Enable the X11 windowing system and GNOME Desktop Environment
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable Bluetooth Hardware Service
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true; 
  };

  # Enable sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define user account "gio"
  users.users."gio" = {
    isNormalUser = true;
    description = "GIO";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    packages = with pkgs; [ ];
  };

  # Enable experimental features for Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Install Firefox
  programs.firefox.enable = true;

  # Enable the Cloudflare WARP background daemon service
  services.cloudflare-warp.enable = true;
  services.cloudflare-warp.openFirewall = true; 
  
  # Enable NetBird mesh VPN daemon
  services.netbird.enable = true;

  # Ensures flatpak apps integrate nicely with desktop launchers
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gnome" "gtk" ];
        # Forces Niri to use the GTK file picker so sandboxed apps don't hang looking for Nautilus
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        # FIX: Explicitly pairs both portals so screenshare sessions don't drop out
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" "gtk" ];
      };
    };
  };

  # Install Steam cleanly
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Enable XWayland explicitly for legacy apps like Steam
  programs.xwayland.enable = true;

  # Flatpak support
  services.flatpak.enable = true;

  # Enable Niri (wayland compositor)
  programs.niri.enable = true;

  # Force Nvidia environment variables globally for the whole system session
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1"; # Fixes invisible cursor bugs on Nvidia
    NIXOS_OZONE_GL_TRANSPORT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Podman containers
  virtualisation.podman.enable = true;

  # Enable full 32-bit and 64-bit graphics driver support
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load NVIDIA drivers for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # Proprietary Nvidia Optimus driver settings for laptop gaming
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Configure Laptop Hybrid Graphics (Optimus PRIME Sync)
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      sync.enable = false;
      intelBusId = "PCI:0:2:0";   
      nvidiaBusId = "PCI:1:0:0";  
    };
  };

  hardware.steam-hardware.enable = true;

  # Wayfire Desktop Environment settings
  programs.wayfire = {
    enable = true;
    plugins = with pkgs.wayfirePlugins; [
      wcm
      wf-shell
      wayfire-plugins-extra
    ];
  };

  # Status bar engine
  programs.waybar.enable = false;

  # Enable Polkit security service
  security.polkit.enable = true;

  # Polkit Authentication Daemon (Ensures password prompts appear in Niri and Wayfire)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # System Fonts Configuration
  fonts.packages = with pkgs; [
    font-awesome
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  # Global system software packages
  environment.systemPackages = with pkgs; [
    distrobox
    brave
    zoom-us
    obs-studio
    ayugram-desktop
    fastfetch
    linux-wallpaperengine
    waypaper
    swaybg
    mpvpaper
    kitty
    riseup-vpn
    lutris
    wine
    wgcf
    wireguard-tools
    gnomeExtensions.appindicator 
    btop
    cmatrix
    cava
    tmux
    exiftool
    ffmpeg
    ags
    wlogout
    git
    thunar
    p7zip
    wofi
    overskride
    networkmanager_dmenu
    swaylock
    killall
    bottom
    xwayland-satellite
    awww
    swww
    vscode
    efibootmgr
    noctalia-shell
    gnome-extension-manager
    papirus-folders
    eww
    vim
    playerctl
    polkit_gnome
    tty-clock
    sl
    gimp
    jamesdsp      
    pavucontrol   
    brightnessctl 
    lavat
    asusctl       
    audacious
    sptlrx   
    steam-run
    yt-dlp
    netbird-ui
    wget          
    spotify
    prismlauncher
    qdirstat    
    pkgs.mission-center            
        
    # Official Discord Client bundled with Vencord 
    (discord.override {
      withVencord = true;
    })
      
    (papirus-icon-theme.override { color = "violet"; })
  ];

  services.udisks2.enable = true;

  # Secondary Game/Data Storage (NTFS Shared Drive Layout)
  fileSystems."/home/gio/Storage" = {
    device = "/dev/disk/by-uuid/5C9833C598339D08";
    fsType = "ntfs3";
    options = [
      "nofail"
      "uid=1000"
      "gid=100"
      "umask=000"
      "force"
    ];
  };

  # ASUS Laptop background background daemon
  services.asusd = {
    enable = true;
  };

  # FIX: Corrected option module path to use services.supergfxd.enable
  services.supergfxd.enable = true;

} # This is the close for the config
