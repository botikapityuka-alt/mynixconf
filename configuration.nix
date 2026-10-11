# Edit this configuration file to define what should be installed on
# your system.
# Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config, lib, pkgs, ... }:

let
  # Itt definiáljuk a saját helyi JDK-nkat
  myLocalJdk = pkgs.stdenv.mkDerivation {
    pname = "custom-local-jdk";
    version = "26";

    # IDE ÍRD A HELYI JDK MAPPÁD ELÉRÉSI UTÁT
    src = /home/botond/java-26-openjdk;

    # NixOS-specifikus javítások (Dynamic Linker beállítása a binárisokhoz)
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      glibc

      # Grafikus felülethez (X11)
      xorg.libX11
      xorg.libXext
      xorg.libXi
      xorg.libXrender
      xorg.libXtst
      xorg.libXrandr
      xorg.libXt
      xorg.libXxf86vm

      # Modern ablakkezelés & GTK
      gtk3
      glib
      cairo
      gdk-pixbuf

      # Betűtípusok és hang
      freetype
      fontconfig
      alsa-lib

      # Nyomtatás és multimédia
      cups
      giflib
      lcms2

      # --- ITT A KIMAXOLT MEGOLDÁS A LIBJPEG-RE ---
      # Átkonfiguráljuk a csomagot, hogy a v8-as API-val forduljon le (ez adja a libjpeg.so.8-at)
      (libjpeg_turbo.override { enableJpeg8 = true; })
    ];
    autoPatchelfIgnoreMissingDeps = false;

    # Egyszerűen átmásoljuk a helyi mappa tartalmát a Nix store-ba
    installPhase = ''
      mkdir -p $out
      cp -r * $out/
    '';
  };
in
{
  # <--- ITT KEZDŐDIK A KIFEJEZÉS TÖRZSE, nem zárjuk le üresen!
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = "nixos-gep";
  networking.networkmanager.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  system.stateVersion = "25.11";

  # NVIDIA beállítások megtartása
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    powerManagement.enable = true;
    open = true;
    nvidiaSettings = true;
  };

  # Felhasználó megtartása
  users.users.botond = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    initialPassword = "1";
  };



  # SDDM Kijelzőkezelő és KDE Plasma 6 bekapcsolása
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.flatpak.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Alapvető asztali szolgáltatások
  services.dbus.enable = true;
  xdg.portal.enable = true;

  # Nem szabad tulajdonosi csomagok engedélyezése
  nixpkgs.config.allowUnfree = true;



  # NVIDIA Wayland környezeti változók a KDE-hez is (biztonság kedvéért) + JAVA_HOME
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    JAVA_HOME = "${myLocalJdk}";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [

    stdenv.cc.cc.lib
    zlib
    glibc

    # X11 / Grafikus könyvtárak az IntelliJ saját JRE-jéhez
    xorg.libX11
    xorg.libXext
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xorg.libXrandr

    # Betűtípusok és renderelés
    freetype
    fontconfig

    # Egyéb alapvető függőségek
    alsa-lib



  ];








  # Rendszerszintű csomagok
  environment.systemPackages = with pkgs; [
    kitty
    neovim
    git
    firefox
    unzip
    stdenv.cc # Includes gcc, coreutils, and glibc
    gnumake
    gdb
    binutils
    pkg-config
    ripgrep
    fd
    vim
    nerd-fonts.jetbrains-mono
    clang
    cmake
    ninja
    python3
    nixd
    nixpkgs-fmt
    gcc16
    (import (builtins.fetchTarball "https://github.com/botikapityuka-alt/nur_sajat/archive/main.tar.gz") { }).emacs-custom
    myLocalJdk # <--- Nagy J-vel javítva, hogy egyezzen a fenti névvel!
    jdk21
    jdk17
    (pkgs.writeShellScriptBin "set-java17" ''
      export JAVA_HOME="${pkgs.jdk17}"
      export PATH="${pkgs.jdk17}/bin:$PATH"
      echo "Átváltva Java 17-re!"
      exec $SHELL
    '')

    (pkgs.writeShellScriptBin "set-java21" ''
      export JAVA_HOME="${pkgs.jdk21}"
      export PATH="${pkgs.jdk21}/bin:$PATH"
      echo "Átváltva Java 21-re!"
      exec $SHELL
    '')

    (pkgs.writeShellScriptBin "set-java26" ''
      export JAVA_HOME="${myLocalJdk}"
      export PATH="${myLocalJdk}/bin:$PATH"
      echo "Átváltva a saját Java 26-odra!"
      exec $SHELL
    '')
    (pkgs.makeDesktopItem {
      name = "intellij-custom";
      desktopName = "IntelliJ IDEA (Letöltött)";
      genericName = "Java IDE";
      exec = "/home/botond/.ids/idea-IU-262.8665.258/bin/idea %f";
      icon = "/home/botond/.ids/idea-IU-262.8665.258/bin/idea.svg";
      comment = "A hivatalos weboldalról letöltött IntelliJ IDEA";
      categories = [ "Development" "IDE" ];
      terminal = false;
      type = "Application";
      mimeTypes = [ "text/x-java" "application/x-java-archive" ];

    })
    localsend
    ollama



    rustup
    (import ./optimized-fish.nix pkgs)
    ungoogled-chromium
        (pkgs.vscode.fhsWithPackages (ps: with ps; [
      # Itt megadhatsz extra függőségeket, de mivel a rendszeredben
      # szinte minden ott van, ez a minimális környezet elég lesz a VSCode-nak:
      git
      openssl
      pkg-config
    ]))



  ];
  environment.pathsToLink = [ "/share/applications" ];



}
