doit:
  just makesd
  just copyenv

makesd:
  sh -c 'sudo nix run "github:nix-community/disko#disko-install" -- --write-efi-boot-entries --flake .#nixos-yubikey --disk main /dev/sda'

copyenv:
  sudo mkdir -p /media/yubikey
  sudo mount /dev/sda2 /media/yubikey
  sudo cp ../secrets/* /media/yubikey/home/yubikey
  sudo cp ../secrets/.env /media/yubikey/home/yubikey
  sync
  sudo umount /media/yubikey
  sudo rmdir /media/yubikey