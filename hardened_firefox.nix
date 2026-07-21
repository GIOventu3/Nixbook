{ config, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];
  
  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "gio" ];
  nixpkgs.config.virtualbox.enableExtensionPack = true; 
 
  # FIX: Kept Nvidia fixes, added explicit Realtek SD card reader kernel modules
  boot.initrd.availableKernelModules = [ "rtsx_pci_sdmmc" ];
  
  # -----------------------------------------------------------------
  # PERFORMANCE TWEAKS: Zen Kernel & Memory Optimizations
  # -----------------------------------------------------------------
  boot.kernelPackages = pkgs.linuxPackages_zen; # Swapped to responsive Zen Kernel
  boot.kernelModules = [ "rtsx_pci_sdmmc" ];
  boot.kernelParams = [ 
    "nvidia-drm.modeset=1" 
    "pcie_port_pm=off" 
  ];
  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # Don't aggressively swap background apps to storage
  };

  # -----------------------------------------------------------------
  # MEMORY COMPRESSION: ZRAM
  # -----------------------------------------------------------------
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100; # Compresses background memory data instead of choking
  };

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
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "power" "docker" ];
    packages = with pkgs; [ ];
  };

  # Enable experimental features for Nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Install Firefox with Privacy Hardening + 144Hz/Hardware Acceleration Fixes
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      Preferences = {
        # -----------------------------------------------------------------
        # 144Hz HIGH REFRESH RATE & WAYLAND/NVIDIA PERFORMANCE FIXES
        # -----------------------------------------------------------------
        # Forces Firefox to target your monitor's actual refresh rate (144Hz)
        "layout.frame_rate" = 144;
        
        # Enable VA-API Hardware Video Acceleration (Offloads YT decoding to GPU)
        "media.hardware-video-decoding.enabled" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "gfx.webrender.all" = true; # Force WebRender GPU Acceleration
        "widget.dmabuf.force-enabled" = true; # Zero-copy Wayland buffers

        # Prevent frame pacing stutters on high refresh rate displays
        "gfx.canvas.accelerated" = true;
        "dom.ipc.processCount" = 8; # Reverted low cap; prevents UI thread blocking

        # -----------------------------------------------------------------
        # PRIVACY & SECURITY HARDENING
        # -----------------------------------------------------------------
        "browser.tabs.unloadOnLowMemory" = true;
        "network.cookie.cookieBehavior" = 1; # Reject cross-site tracking cookies
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "dom.private-attribution.submission.enabled" = false; # Disable ad measurement telemetry
        
        # Extended privacy prefs
        "privacy.donottrackheader.enabled" = true;
        "privacy.fingerprintingProtection" = true;
        "browser.discovery.enabled" = false;
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
      };
    };
  };

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
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
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
    WLR_NO_HARDWARE_CURSORS = "1"; 
    NIXOS_OZONE_GL_TRANSPORT = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Container services
  virtualisation.podman.enable = true;
  virtualisation.docker.enable = true; 

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
    # Updated to follow whatever kernel is active seamlessly
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Configure Laptop Hybrid Graphics (Optimized for dGPU tasks)
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      sync.enable = false;
      intelBusId = "PCI:0:2:0";   
      nvidiaBusId = "PCI:1:0:0";  
    };
  };
  
  # STEAM
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
    pkgs.winboat
    pkgs.qemu 
    exfat
    ntfs3g
    pkgs.cloudflare-warp      
           
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

  # ASUS Laptop background daemon
  services.asusd = {
    enable = true;
  };

  services.supergfxd.enable = true;  
 
  # -----------------------------------------------------------------
  # DAEMONS & PROCESS TUNING
  # -----------------------------------------------------------------
  programs.gamemode.enable = true;
 
  programs.gamescope = {
    enable = true;
    capSysNice = true; 
  };

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp; # Auto-deprioritize browser/discord when playing games
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
