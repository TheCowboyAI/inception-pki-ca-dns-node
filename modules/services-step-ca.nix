{ lib, pkgs, ... }:
{

  services = {

    ## configuration file indirection is needed to support reloading
    ## environment.etc."smallstep/ca.json".source = configFile;

    ## https://search.nixos.org/options?channel=unstable&show=services.step-ca.settings&from=0&size=50&sort=relevance&type=packages&query=step-ca
    ## https://github.com/NixOS/nixpkgs/blob/d4ee9275ce1c18b52140da2d151c91be167eee0b/nixos/modules/services/security/step-ca.nix#L124
    ## systemctl -f
    ##
    step-ca = {
      enable = true;
      openFirewall = true;

      address =  "127.0.0.1";
      port = 443;

      ## Make sure to use a quoted absolute path instead of a path literal to prevent it from being copied to the globally readable Nix store.
      intermediatePasswordFile = "/run/keys/smallstep-password"; # FIXME is world readable

      ## Settings that go into ca.json. See the step-ca manual for more information.
      ## settings = builtins.fromJSON (builtins.readFile "/etc/smallstep/ca.json");
      settings = {
        dnsNames = ["localhost"];
        root = ./step-ca/init-structure/secrets/root_ca.crt;
        crt = ./step-ca/init-structure/secrets/intermediate_ca.crt;
        key = ./step-ca/init-structure/secrets/intermediate_ca.key;
        # root = /var/lib/step-ca/secrets/root_ca.crt;
        # crt = /var/lib/step-ca/secrets/intermediate_ca.crt;
        # key = /var/lib/step-ca/secrets/intermediate_ca.key;
        db = {
          type = "badger";
          dataSource = "/var/lib/step-ca/db";
        };
        authority = {
          provisioners = [
            {
              type = "ACME";
              name = "acme";
            }
            # {
            #   type = "ACME";
            #   name = "acme";
            # }
          ];
        };
      };
    };

    ## https://yilozt.github.io/en/posts/sql-init-nixos/
    mysql = {
      enable = true;
      package = pkgs.mariadb_114;
    };
  };
}
