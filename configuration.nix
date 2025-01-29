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

      ##./programs-gpg.nix

      ./scripts

      ./modules/disk-config.nix
      ./modules/networking.nix
      ./modules/programs.nix
      ./modules/secrets.nix

      ./modules/services.nix
      ./modules/services-step-ca.nix
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

  ## Set your hostname here not in ./modules/networking.nix
  networking.hostName = "ca-dns";

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

  # disable coredump that could be exploited later and also slow down the system when something crashes
  systemd.coredump.enable = false;

  ## our systemd containers have access to root folder:
  # system.activationScripts.script.makeStepCaDir = "mkdir -p /root/container_data/step-ca";
  # system.activationScripts.script.makeStepDbDir = "mkdir -p /root/container_data/step-db";

  security.sudo.wheelNeedsPassword = false;

  # giving root a password enables su which we may want
  users.users.root = {
    isSystemUser = true;
    hashedPassword = "$6$z4glAe5PkxpsXOOU$KyX75c.WfktMoP28c5Tssj9VW/tO7lhlWMCuPanu9YRXp2kLMt8q51r6LVKC3R75E04SKXEvJ2LOo2F92sfGj.";
    shell = pkgs.zsh;

    ### Add your SSH key/s for the root user - used when updating the system
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13eQloVGYlOogC/eYDUcSt7p6gV3YT9LsPrNS1RDex sparkx@twr-z790"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi+tsPpSLRXWmEitPvf3M7OGRF8AIvja+JJJ8Ku0ZrQ steele-sshkey@pmx-vm"
    ];
  };

  system.activationScripts.script.text = " touch /home/cowboy/.zshrc ";
  users.users.cowboy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # hashedPassword = "$6$z4glAe5PkxpsXOOU$KyX75c.WfktMoP28c5Tssj9VW/tO7lhlWMCuPanu9YRXp2kLMt8q51r6LVKC3R75E04SKXEvJ2LOo2F92sfGj."; ## Original
    shell = pkgs.zsh;
    createHome = true;
    home = "/home/cowboy";

    ### Add a password for the cowboy user
    hashedPassword = "$y$j9T$BBYMFiVDbITAU0Z4w4Xqe/$KSetJ4nA6IBh2qCRweWjce0VgSNXDSpQk15HehlNRp7";
    ### Add your SSH key/s for the cowboy user - used when updating the system
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13eQloVGYlOogC/eYDUcSt7p6gV3YT9LsPrNS1RDex sparkx@twr-z790"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi+tsPpSLRXWmEitPvf3M7OGRF8AIvja+JJJ8Ku0ZrQ steele-sshkey@pmx-vm"
    ];
  };


  services.getty.autologinUser = lib.mkForce "cowboy";

  environment.etc."doc/help.md".source = ./scripts/readme.md;

  users.motd = ''
    NixOS CA-DNS Configuration
    ==========================

    For instructions type: `help`
  '';

  ## scripts to enable
  add-key.enable = true;
  enable-fido.enable = true;
  completely-reset-my-yubikey.enable = true;
  edit-env.enable = true;
  enable-pgp-touch.enable = true;
  enable-piv-touch.enable = true;
  make-certkey.enable = true;
  make-domain-cert.enable = true;
  make-rootca.enable = true;
  make-subkeys.enable = true;
  make-tls-client.enable = true;
  random-6.enable = true;
  random-8.enable = true;
  random-mgmt-key.enable = true;
  random-pass.enable = true;
  set-attributes.enable = true;
  set-fido-pin.enable = true;
  set-fido-retries.enable = true;
  set-logs-enabled.enable = true;
  set-logs-disabled.enable = true;
  set-oauth-password.enable = true;
  set-pgp-pins.enable = true;
  set-piv-pins.enable = true;
  set-yubikey.enable = true;
  xfer-certs.enable = true;
  xfer-keys.enable = true;


  ## This value determines the NixOS release from which the default settings for stateful data, like file locations and database versions
  ## on your system were taken. It‘s perfectly fine and recommended to leave this value at the release version of the first install of this system.
  ## Before changing this value read the documentation for this option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11";  ## Did you read the comment?
}
