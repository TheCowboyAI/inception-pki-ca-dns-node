{ config, pkgs, lib, inputs, ... }:
{
  # System packages
  environment.systemPackages = with pkgs; [
    cryptsetup
    git
    just
    micro
    gitAndTools.git-extras
    gnupg
    pcsclite
    pcsctools
    pgpdump
    pinentry-curses
    pwgen
    gpg-tui ## https://github.com/orhun/gpg-tui
    openssl
    jq
    jc
    glow

    ## step-ca ## Private certificate authority (X.509 & SSH) & ACME server for secure automated certificate management, so you can use TLS everywhere & SSO for SSH
    step-cli ## https://github.com/smallstep/cli - Zero trust swiss army knife for working with X509, OAuth, JWT, OATH OTP, etc

    yubikey-manager
    yubikey-manager-qt
    yubikey-personalization
    age-plugin-yubikey
    piv-agent ## https://github.com/smlx/piv-agent

    tree
    mc
    dig
    haveged ## remedy low-entropy conditions
  ];

  services.udev.packages = with pkgs; [
    yubikey-personalization
    libu2f-host
  ];

  services.pcscd.enable = true;

  ## sets SSH_AUTH_SOCK to point at yubikey-agent
  ## yubikey-agent will use whatever pinentry is specified in programs.gnupg.agent.pinentryPackage.
  services.yubikey-agent.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -la";
    };

    histSize = 10000;
    loginShellInit = "source ~/.env";
  };


  # Keys needed to connect to private github.com repos
  # home.file.".ssh/cowboy-id-ed25519.pub".source = config.lib.file.mkOutOfStoreSymlink "/etc/agenix/ssh/cowboy-id-ed25519.pub";
  # home.file.".ssh/cowboy-id-ed25519".source = config.lib.file.mkOutOfStoreSymlink "/etc/agenix/ssh/cowboy-id-ed25519";

  # environment.etc.".ssh/cowboy-id-ed25519.pub".source = "/etc/agenix/ssh/cowboy-id-ed25519.pub";
  # environment.etc.".ssh/cowboy-id-ed25519".source = "/etc/agenix/ssh/cowboy-id-ed25519";

}
