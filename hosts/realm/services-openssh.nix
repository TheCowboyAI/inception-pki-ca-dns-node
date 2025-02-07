
{ lib, config, ... }:
{
  ## Many services also provide an option to open the required firewall ports automatically.
  ## For example, the media server Jellyfin offers the option services.jellyfin.openFirewall = true; which will open the required TCP ports.
  ## All ports will be opened from networking.nix so that we have a consistent setup !!!

  ## Add your inception SSH key/s for the cowboy user, it ends up in the right place: /etc/ssh/authorized_keys.d/cowboy:
  ## This file can be taken from ./inception/deployment_machine/ssh/ssh_cowboy_xxx.pub
  users.users."cowboy".openssh.authorizedKeys = {
    ## Keep only this in production !!!
    keyFiles = [
      ./inception/realm_node/ssh/ssh_cowboy_authorized_keys ## Do NOT Edit
    ];

    ## Remove for production !!!
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13eQloVGYlOogC/eYDUcSt7p6gV3YT9LsPrNS1RDex sparkx@twr-z790"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi+tsPpSLRXWmEitPvf3M7OGRF8AIvja+JJJ8Ku0ZrQ steele-sshkey@pmx-vm"
    ];
  };

  ## Copy files received from inception archive to realm_node:
  environment.etc = {
      ## Transfer SSH principals file:
      "ssh/principals" = {
        source = ./inception/realm_node/ssh/ssh_cowboy_principals; ## Do NOT Edit
        mode = "0600";
      };

      ## Transfer Host SSH keypair:
      "ssh/ssh_host_ed25519_key" = {
        source = ./inception/realm_node/ssh/ssh_host_ed25519_key; ## Do NOT Edit
        mode = "0600";
      };
      "ssh/ssh_host_ed25519_key.pub" = {
        source = ./inception/realm_node/ssh/ssh_host_ed25519_key.pub; ## Do NOT Edit
        mode = "0644";
      };
      "ssh/ssh_host_ed25519_key-cert.pub" = {
        source = ./inception/realm_node/ssh/ssh_host_ed25519_key-cert.pub; ## Do NOT Edit
        mode = "0600";
      };

      ## Transfer Hosts CA keypair:
      "ssh/ssh_cowboy_hosts_ca" = {
        source = ./inception/realm_node/ssh/ssh_hosts_ca_cowboyai_local_1; ## Filename can change Edit here
        mode = "0400";
      };
      "ssh/ssh_cowboy_hosts_ca.pub" = {
        source = ./inception/realm_node/ssh/ssh_hosts_ca_cowboyai_local_1.pub; ## Filename can change Edit here
        mode = "0444";
      };

      ## Transfer Users CA keypair:
      "ssh/ssh_cowboy_users_ca" = {
        source = ./inception/realm_node/ssh/ssh_users_ca_cowboyai_local_1; ## Filename can change Edit here
        mode = "0400";
      };
      "ssh/ssh_cowboy_users_ca.pub" = {
        source = ./inception/realm_node/ssh/ssh_users_ca_cowboyai_local_1.pub; ## Filename can change Edit here
        mode = "0444";
      };


      ## Transfer ssh_git_secrets_key keypair to be used with git secrets:
      # "ssh/ssh_git_secrets_key" = {
      #   source = ./inception/realm_node/ssh/ssh_git_secrets_key_cowboy_local_1; ## Edit here
      #   mode = "0400";
      # };
      # "ssh/ssh_git_secrets_key.pub" = {
      #   source = ./inception/realm_node/ssh/ssh_git_secrets_key_cowboy_local_1.pub; ## Edit here
      #   mode = "0444";
      # };

      ## set correct mode for the files - DO NOT Edit below
      ## Find the correct rights !!!
      "ssh/moduli" = {
        mode = "0400";
      };
      "ssh/ssh_config" = {
        mode = "0600";
      };
      "ssh/sshd_config" = {
        mode = "0600";
      };
      "ssh/ssh_known_hosts" = {
        mode = "0600";
      };
  };

  ## https://nixos.wiki/wiki/Nixos-rebuild
  ## error: cannot add path '/nix/store/w500x2i41v66sskr81w8f37yiml24qyp-sshd.conf-final' because it lacks a signature by a trusted key
  nix.settings.trusted-users = [ "cowboy" ];

  services = {
    ## SSH server enabled with keys, no passwords
    ## https://mynixos.com/nixpkgs/option/services.openssh.hostKeys
    ## OpenSSH defaults here https://github.com/NixOS/nixpkgs/issues/113729
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"

        # HostKey = "/etc/ssh/ssh_cowboy_host_ed25519_key"; ## This is a default
        HostCertificate = "/etc/ssh/ssh_host_ed25519_key-cert.pub";
        TrustedUserCAKeys = "/etc/ssh/ssh_cowboy_users_ca.pub";

        ## https://security.stackexchange.com/questions/254193/openssh-authorizedprincipalsfile-allows-any-user
        AuthorizedPrincipalsFile = "/etc/ssh/principals/%u"; ## keep %u at the end !!!
      };

      ## Several IT news outlets have reported the possibility that nations may have broken commonly used primes, which mean they could read encrypted traffic transmitted over “secure” channels.
      ## Protecting your server against that threat is fairly simple, just edit the /etc/ssh/moduli file and comment the lines where the fifth field is 1023 or 1535 (which denotes the size).
      ## This forces the algorithm to use keys from Group 14 (2048-bit or more).
      ## Higher groups mean more secure keys that are less likely to be broken in near future, but also require additional time to compute.
      # moduliFile = "/etc/cowboy_moduli/cowboy_generated_moduli";

      ## This is automagically set by users.users."cowboy".openssh.authorizedKeys.keyFiles
      # authorizedKeysFiles = [
      #   "/etc/ssh/ssh_cowboy_authorized_keys"
      # ];
    };

  };

  programs.ssh = {
    #enable = true;

    ## https://nixos.org/manual/nixos/stable/options#opt-programs.ssh.knownHostsFiles
    # knownHostsFiles

    # knownHosts = {
    #   myhost = {
    #     extraHostNames = [ "myhost.mydomain.com" "10.10.1.4" ];
    #     publicKeyFile = ./pubkeys/myhost_ssh_host_dsa_key.pub;
    #   };
    #   "myhost2.net".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIRuJ8p1Fi+m6WkHV0KWnRfpM1WxoW8XAS+XvsSKsTK";
    #   "myhost2.net/dsa" = {
    #     hostNames = [ "myhost2.net" ];
    #     publicKeyFile = ./pubkeys/myhost2_ssh_host_dsa_key.pub;
    #   };
    #   certAuthority = true;
    # };

    #IdentityFile '' + config.age.secrets.github-key.path + ''
    extraConfig = ''
      ## !!! This file is imutable - you can only edit it through ~/nixos-main-config/home/base/tui/ssh.nix !!!
      ## a private key that is used during authentication will be added to ssh-agent if it is running
      ## lets you avoid reentering the key passphrase every time
      AddKeysToAgent yes

      Host git-cowboy
        # git clone git@git-cowboy:TheCowboyAI/<REPO>.git .
        # test connection with: ssh git@git-cowboy
        Hostname git-cowboy
        Port 2222
        IdentityFile
        ForwardAgent yes
        IdentitiesOnly yes
        AddKeysToAgent yes

    '';
  };
}
