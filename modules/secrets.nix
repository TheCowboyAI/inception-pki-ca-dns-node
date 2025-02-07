{
  lib,
  config,
  pkgs,
  agenix,
  mysecrets,
  ...
}:
with lib; let
  cfg = config.modules.secrets;

  noaccess = {
    mode = "0000";
    owner = "root";
  };
  high_security = {
    mode = "0500";
    owner = "root";
  };
  user_readable = {
    mode = "0500";
    owner = "cowboy";
  };
in {
  # imports = [
  #   agenix.nixosModules.default
  # ];

  options.modules.secrets = {
    desktop.enable = mkEnableOption "NixOS Secrets for Desktops";

    server.network.enable = mkEnableOption "NixOS Secrets for Network Servers";
    server.application.enable = mkEnableOption "NixOS Secrets for Application Servers";
    server.operation.enable = mkEnableOption "NixOS Secrets for Operation Servers(Backup, Monitoring, etc)";
    server.kubernetes.enable = mkEnableOption "NixOS Secrets for Kubernetes";
    server.webserver.enable = mkEnableOption "NixOS Secrets for Web Servers(contains tls cert keys)";

    impermanence.enable = mkEnableOption "whether use impermanence and ephemeral root file system";
  };

  config =
    mkIf (
      cfg.desktop.enable
      || cfg.server.application.enable
      || cfg.server.network.enable
      || cfg.server.operation.enable
      || cfg.server.kubernetes.enable
    ) (mkMerge [
      {
        environment.systemPackages = [
          agenix.packages."${pkgs.system}".default
        ];

        # if you changed this key, you need to regenerate (agenix rekey) all encrypt files from the decrypt contents!
        age.identityPaths =
          if cfg.impermanence.enable
          then [
            # To decrypt secrets on boot, this key should exists when the system is booting,
            # so we should use the real key file path(prefixed by `/persistent/`) here, instead of the path mounted by impermanence.
            "/persistent/etc/ssh/ssh_host_ed25519_key" # Linux
          ]
          else [
            "/etc/ssh/ssh_host_ed25519_key"
          ];

        assertions = [
          {
            # This expression should be true to pass the assertion
            assertion =
              !(cfg.desktop.enable
                && (
                  cfg.server.application.enable
                  || cfg.server.network.enable
                  || cfg.server.operation.enable
                  || cfg.server.kubernetes.enable
                ));
            message = "Enable either desktop or server's secrets, not both!";
          }
        ];
      }

      (mkIf cfg.desktop.enable {
        age.secrets = {
          # ---------------------------------------------
          # no one can read/write this file, even root.
          # ---------------------------------------------
          # .age.age means the decrypted file is still encrypted by age(via a passphrase)
          # https://rgoulter.com/blog/posts/programming/2022-06-10-a-visual-explanation-of-gpg-subkeys.html
          # "sparkx-gpg-subkeys.priv.age" =
          #   {
          #     file = "${mysecrets}/gpg/sparkx-gpg-2025-05-23-subkeys.priv.age.age";
          #   }
          #   // noaccess;

          # ---------------------------------------------
          # only root can read this file.
          # ---------------------------------------------
          # "wg-business.conf" =
          #   {
          #     file = "${mysecrets}/wg-business.conf.age";
          #   }
          #   // high_security;

          # Used only by NixOS Modules
          # smb-credentials is referenced in /etc/fstab, by ../hosts/ai/cifs-mount.nix
          # "smb-credentials" =
          #   {
          #     file = "${mysecrets}/smb-credentials.age";
          #   }
          #   // high_security;

          # "rclone.conf" =
          #   {
          #     file = "${mysecrets}/rclone.conf.age";
          #   }
          #   // high_security;

          # "nix-access-tokens" =
          #   {
          #     file = "${mysecrets}/nix-access-tokens.age";
          #   }
          #   // high_security;

          # ---------------------------------------------
          # user can read this file.
          # ---------------------------------------------
          "github-id-ed25519.pub" =
            {
              file = "${mysecrets}/ssh/ssh_host_ed25519_key.pub.age";
            }
            // user_readable;

          "github-id-ed25519" =
            {
              file = "${mysecrets}/ssh/ssh_host_ed25519_key.age";
            }
            // user_readable;

        };

        ## place secrets in /etc/
        environment.etc = {
          # wireguard config used with `wg-quick up wg-business`
          # "wireguard/wg-business.conf" = {
          #   source = config.age.secrets."wg-business.conf".path;
          # };

          # "agenix/rclone.conf" = {
          #   source = config.age.secrets."rclone.conf".path;
          # };

          "agenix/ssh/ssh_host_ed25519_key.pub" = {
            source = config.age.secrets."ssh_host_ed25519_key.pub".path;
            mode = "0600";
            user = "cowboy";
          };

          "agenix/ssh/ssh_host_ed25519_key" = {
            source = config.age.secrets."ssh_host_ed25519_key".path;
            mode = "0600";
            user = "cowboy";
          };

          # "agenix/sparkx-gpg-subkeys.priv.age" = {
          #   source = config.age.secrets."sparkx-gpg-subkeys.priv.age".path;
          #   mode = "0000";
          # };

        };
      })

      # (mkIf cfg.server.webserver.enable {
      #   age.secrets = {
      #     "certs/ecc-server.key" = {
      #       file = "${mysecrets}/certs/ecc-server.key.age";
      #       mode = "0400";
      #       owner = "caddy"; # used by caddy only
      #     };
      #   };
      # })


    ]);
}
