{ lib, pkgs, modulesPath, ... }:
{

  system.copySystemConfiguration = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  imports =
    [
      ## If you use hardened.nix in system configuration, manually set environment.memoryAllocator.provider = "libc";
      ## See https://github.com/NixOS/nixpkgs/issues/108262 - nextcloud-setup-start[1613]: free(): invalid pointer
      ## AND  https://discourse.nixos.org/t/cant-configure-sysctl-unprivileged-userns-clone-for-plex/35464
      (modulesPath + "/profiles/hardened.nix")

      (modulesPath + "/installer/scan/not-detected.nix")
      (modulesPath + "/profiles/qemu-guest.nix")

      #./modules/keynode-scripts.nix

      #../../modules/disk-config.nix
      ./networking.nix
      ../../modules/programs.nix
      ../../modules/secrets.nix

      ../../modules/services.nix
      ./services-openssh.nix
      ./services-step-ca.nix
      ./programs-gpg.nix
    ];


  # ## If you use hardened.nix in system configuration, manually set environment.memoryAllocator.provider = "libc" and everything works fine!
  # environment.memoryAllocator.provider = "libc";
  # ## bwrap: No permissions to creating new namespace, likely because the kernel does not allow non-privileged user namespaces.
  # ## On e.g. debian this can be enabled with 'sysctl kernel.unprivileged_userns_clone=1'.
  # boot = {
  #   kernel.sysctl = {
  #     "kernel.unprivileged_userns_clone" = 1; # for plex, nextcloud, etc with hardened kernel
  #   };
  # };

  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.growPartition = lib.mkDefault true;

  ## Set your hostname and extrahosts here not in ./modules/networking.nix
  networking = {
    hostName = "realm";
    extraHosts = ''
      127.0.0.1 realm-cowboy
      127.0.0.1 ns-cowboy
      127.0.0.1 git-cowboy
      127.0.0.1 ca-cowboy
      127.0.0.1 ocsp-cowboy
      127.0.0.1 pgp-cowboy
    '';
  };

  ## Set your time zone.
  ## time.timeZone = "America/Boise";
  time.timeZone = "Europe/Bucharest";
  ## Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Perform garbage collection weekly to maintain low disk usage
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };
  nix.optimise.automatic = true;
  # system.autoUpgrade = {
  #   enable = true;
  #   allowReboot = true;
  # };

  # disable coredump that could be exploited later and also slow down the system when something crashes
  systemd.coredump.enable = false;

  ## Users
  security.sudo.wheelNeedsPassword = false;

  ## User root does NOT have ANY keys or passwords !!!
  users.users.root = {
    isSystemUser = true;
    shell = pkgs.zsh;
  };

  system.activationScripts.script.text = " touch /home/cowboy/.zshrc ";

  services.getty.autologinUser = lib.mkForce "cowboy";

  users.users.cowboy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    createHome = true;
    home = "/home/cowboy";

    ## We do not set ANY keys or passwords for user cowboy here - we do it in ./modules/services-openssh.nix !!!
    ### Add a password for the cowboy user:
    ## hashedPassword = "$y$j9T$BBYMFiVDbITAU0Z4w4Xqe/$KSetJ4nA6IBh2qCRweWjce0VgSNXDSpQk15HehlNRp7";
    ### Add your SSH key/s for the cowboy user:
    ## openssh.authorizedKeys.keys = [
    ##   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13eQloVGYlOogC/eYDUcSt7p6gV3YT9LsPrNS1RDex sparkx@twr-z790"
    ##   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi+tsPpSLRXWmEitPvf3M7OGRF8AIvja+JJJ8Ku0ZrQ steele-sshkey@pmx-vm"
  };

  users.motd = ''
    CowboyAI NixOS REALM NODE
    ==========================
    For instructions type: `help`

  '';


  ## This value determines the NixOS release from which the default settings for stateful data, like file locations and database versions
  ## on your system were taken. It‘s perfectly fine and recommended to leave this value at the release version of the first install of this system.
  ## Before changing this value read the documentation for this option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11";  ## Did you read the comment?
}
