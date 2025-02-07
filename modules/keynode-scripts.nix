{ lib, pkgs, ... }:{

imports = [
  ./keynode-scripts
];

environment.etc."doc/help.md".source = ./keynode-scripts/readme.md;

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
}
