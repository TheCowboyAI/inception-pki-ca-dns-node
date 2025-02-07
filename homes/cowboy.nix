{ config, pkgs, ... }:
{
  # username = "cowboy";
  # userfullname = "CowboyAI";
  # useremail = "15813839+Sparkxxx@users.noreply.github.com";
  # #networking = import ./networking.nix {inherit lib;};
  # domain = "thecowboy.ai";
  # # git config --global user.email "15813839+Sparkxxx@users.noreply.github.com"
  # # git config --global user.name "cowboy"

  imports = [

  ];

  programs.home-manager.enable = true;

  home = {
    username = "cowboy";
    homeDirectory = "/home/cowboy";

    # stateVersion value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.11";

    packages = with pkgs; [
      # your desired nixpkgs here
      git
    ];

    file = {};
    ##sessionVariable = { EDITOR = "nano"; };
  };

  ## For programs for which Home Manager doesn't have configuration options, you can use it to manage your dotfiles directly
  ## This will create symlink $XDG_CONFIG_HOME/i3blocks/config and ~/.gdbinit
  # xdg.configFile."i3blocks/config".source = ./i3blocks.conf;
  # home.file.".gdbinit".text = ''
  #     set auto-load safe-path /nix/store
  # '';

  ## Copy files received from inception archive to cadns_node:
  # environment.etc = {
  #   ## Transfer CowboyAI GPG public key to the node:
  #   "gpg/gpg_CowboyAI_key.pub" = {
  #     source = ./gpg_CowboyAI_key.pub;
  #     mode = "0655";
  #   };
  # };

  ## https://mynixos.com/options/programs.gpg - error: The option `programs.gpg' does not exist
  programs.gpg = {
    enable = true;
    homedir = "/home/cowboy/.gnupg";

    #  $GNUPGHOME/trustdb.gpg stores all the trust level you specified in `programs.gpg.publicKeys` option.
    #
    # If set `mutableTrust` to false, the path $GNUPGHOME/trustdb.gpg will be overwritten on each activation.
    # Thus we can only update trsutedb.gpg via home-manager.
    mutableTrust = false;

    # $GNUPGHOME/pubring.kbx stores all the public keys you specified in `programs.gpg.publicKeys` option.
    #
    # If set `mutableKeys` to false, the path $GNUPGHOME/pubring.kbx will become an immutable link to the Nix store, denying modifications.
    # Thus we can only update pubring.kbx via home-manager
    mutableKeys = false;
    # publicKeys = [
    #   # https://www.gnupg.org/gph/en/manual/x334.html
    #   {
    #     source = "/etc/gpg/gpg_CowboyAI_key.pub";
    #     trust = 5;
    #   } # ultimate trust, my own keys.
    # ];

    # This configuration is based on the tutorial below, it allows for a robust setup
    # https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1
    # ~/.gnupg/gpg.conf
    settings = {
      # Get rid of the copyright notice
      no-greeting = true;

      # Disable inclusion of the version string in ASCII armored output
      no-emit-version = true;
      # Do not write comment packets
      no-comments = false;
      # Export the smallest key possible
      # This removes all signatures except the most recent self-signature on each user ID
      export-options = "export-minimal";

      # Show the 16-character key ID with 0x before it
      keyid-format = "0xlong";
      # List all keys (or the specified ones) along with their fingerprints
      with-fingerprint = true;

      # Display the calculated validity of user IDs during key listings Show expired subkeys
      list-options = "show-uid-validity show-unusable-subkeys";
      verify-options = "show-uid-validity show-keyserver-urls";

      # Select the strongest cipher
      personal-cipher-preferences = "AES256"; ##checked
      # Select the strongest digest
      personal-digest-preferences = "SHA512"; ##checked
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";

      # This preference list is used for new keys and becomes the default for "setpref" in the edit menu
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      # Use the strongest cipher algorithm
      cipher-algo = "AES256";
      # Use the strongest digest algorithm
      digest-algo = "SHA512";
      # Message digest algorithm used when signing a key
      cert-digest-algo = "SHA512"; ##checked
      # Use RFC-1950 ZLIB compression
      compress-algo = "ZLIB";

      # Disable weak algorithm
      disable-cipher-algo = "3DES";
      # Treat the specified digest algorithm as weak
      weak-digest = "SHA1";

      # The cipher algorithm for symmetric encryption for symmetric encryption with a passphrase
      s2k-cipher-algo = "AES256";
      # The digest algorithm used to mangle the passphrases for symmetric encryption
      s2k-digest-algo = "SHA512";
      # Selects how passphrases for symmetric encryption are mangled
      s2k-mode = "3";
      # Specify how many times the passphrases mangling for symmetric encryption is repeated
      s2k-count = "65011712";

      #UTF-8 support for compatibility
      charset = "utf-8";

      # Assume that the arguments are already given as UTF8 strings. The default
      # (--no-utf8-strings) is to assume that arguments are encoded in the
      # character set as specified by --charset. These options effects all
      # following arguments. Both options may used multiple times.
      utf8-strings = true;

      # Do not merge primary user ID and primary key in --with-colon listing mode and print all timestamps as seconds since 1970-01-01
      # fixed-list-mode = true;

      # When verifying a signature made from a subkey, ensure that the cross
      # certification "back signature" on the subkey is present and valid.
      # This protects against a subtle attack against subkeys that can sign.
      # Defaults to --require-cross-certification for gpg2.
      require-cross-certification = true;

      # --no-throw-keyids Do not put the recipient key IDs into encrypted messages.
      # This helps to hide the receivers of the message and is a limited
      # countermeasure against traffic analysis. ([Using a little social engineering
      # anyone who is able to decrypt the message can check whether one of the other
      # recipients is the one he suspects.]) On the receiving side, it may slow down
      # the decryption process because all available secret keys must be tried.
      # --no-throw-keyids disables this option. This option is essentially the same
      # as using --hidden-recipient for all recipients.
      throw-keyids = true;

      #Output ASCII instead of binary
      #armor = true;

      #Enable smartcard
      #use-agent = true;

      #Disable recipient key ID in messages (breaks Mailvelope) Key ID -> 0x0000000000000000 unable to decrypt
      #throw-keyids
      #Default key ID to use (helpful with throw-keyids)
      #default-key 0xFF00000000000001
      #trusted-key 0xFF00000000000001

      # keyserver = "hkps://keys.openpgp.org";
      # auto-key-retrieve = true;
      # auto-key-import = true;
      # keyserver-options = "honor-keyserver-url";
      #Group recipient keys (preferred ID last)
      #group keygroup = 0xFF00000000000003 0xFF00000000000002 0xFF00000000000001
      #Keyserver URL
      #keyserver hkps://keys.openpgp.org
      #keyserver hkps://keys.mailvelope.com
      #keyserver hkps://keyserver.ubuntu.com:443
      #keyserver hkps://pgpkeys.eu
      #keyserver hkps://pgp.circl.lu
      #keyserver hkp://zkaan2xfbuxia2wpf7ofnkbz6r5zdbbvxbunvp5g2iebopbfc4iqmbad.onion
      #Keyserver proxy
      #keyserver-options http-proxy=http://127.0.0.1:8118
      #keyserver-options http-proxy=socks5-hostname://127.0.0.1:9050
      #Enable key retrieval using WKD and DANE
      #auto-key-locate wkd,dane,local
      #auto-key-retrieve
      #Trust delegation mechanism
      #trust-model tofu+pgp
      #Verbose output
      #verbose
    };
  };

  ## https://discourse.nixos.org/t/how-to-set-up-a-system-wide-ssh-agent-that-would-work-on-all-terminals/14156/9
  # programs.gnupg = {
  #   dirmngr.enable = true;
  #   agent = {
  #     enable = true;
  #     enableSSHSupport = true;
  #     enableBrowserSocket = true;
  #     settings = {
  #       default-cache-ttl = "600";
  #       max-cache-ttl = "7200";
  #     };
  #   };
  # };


  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    #defaultCacheTtl = 6*h;
    #defaultCacheTtlSsh = 6*h;
    #maxCacheTtl = 100*y; # effectively unlimited
    #maxCacheTtlSsh = 100*y; # effectively unlimited
    #sshKeys = [ "0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
    extraConfig = ''
      allow-preset-passphrase
    '';
  };

  ## https://rycee.gitlab.io/home-manager/options.xhtml#opt-programs.git.signing
  programs.git = {
    enable = true;
    userName = "";
    userEmail = "";
    ##signing.key = "0x0123456789ABCDEF";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    #autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -la";
    };

    #histSize = 10000;
    #loginShellInit = "source ~/.env";

    # initExtra = (
    #   if config.services.gpg-agent.enable then
    #     ''
    #       if [[ -z "$SSH_AUTH_SOCK" ]]; then
    #         export SSH_AUTH_SOCK="$(${config.programs.gpg.package}/bin/gpgconf --list-dirs agent-ssh-socket)"
    #       fi
    #     ''
    #   else
    #     ""
    # );
  };
}
