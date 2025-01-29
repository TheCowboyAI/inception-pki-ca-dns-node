{

  # the nixConfig here only affects the flake itself, not the system configuration!
  # for more information, see:
  #     https://nixos-and-flakes.thiscute.world/nixos-with-flakes/add-custom-cache-servers
  nixConfig = {
    # substituters will be appended to the default substituters when fetching packages
    extra-substituters = [
      "https://anyrun.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    # impermanence.url = "github:nix-community/impermanence";
    # haumea = {
    #   url = "github:nix-community/haumea/v0.2.2";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    ## secrets management - https://wiki.nixos.org/wiki/Agenix
    agenix = {
      # lock with git commit at 0.15.0
      url = "github:ryantm/agenix";
      # url = "github:ryantm/agenix/564595d0ad4be7277e07fa63b5a991b3c645655d";
      # replaced with a type-safe reimplementation to get a better error message and less bugs.
      # url = "github:ryan4yin/ragenix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    ## The private secrets, it's a private repository, you need to replace it with your own.
    ## Use ssh protocol to authenticate via ssh-agent/ssh-key, and shallow clone to save time
    ## Test conn with `ssh git@github-cowboy`
    ## Update only this input with: 'nix flake lock --update-input mysecrets'
    mysecrets = {
      #url = "git+ssh://git@github-sparkxxx/Sparkxxx/nix-secrets.git?shallow=1";
      url = "git+ssh://git@github-cowboy/TheCowboyAI/inception-pki-templates-secrets.git?shallow=1";
      flake = false;
    };


  };

  outputs = { self, disko, nixpkgs, nixos-facter-modules, agenix, ... }@inputs: {

    # sudo nix run 'github:nix-community/disko#disko-install' -- --write-efi-boot-entries --flake <flake-url>#<flake-attr> --disk <disk-name> <disk-device>
    # nixosConfigurations = {
    #   nixos-yubikey = nixpkgs.lib.nixosSystem {
    #     system = "x86_64-linux";
    #     specialArgs = inputs;
    #     modules = [
    #       disko.nixosModules.disko
    #       ./configuration.nix
    #     ];
    #   };
    # };


    ## 1. Get the VM ISO or PXE image from https://github.com/nix-community/nixos-images - the official starter images don't work.
    ## 2. Create a new VM in your hypervisor using the above image and boot the machine.
    ## Make sure that there is no old facter.json file in your repo.
    ## 3. Initial deployment on new VM - nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-facter ./facter.json --flake .#generic-nixos-facter --target-host root@DHCP_VM_IP
    ## 4. Updating the deployed VM - nixos-rebuild switch --flake .#generic-nixos-facter --target-host "root@cboy-ca-dns"
    ## To do a dist upgrade - nixos-rebuild switch --recreate-lock-file --flake .#generic-nixos-facter --target-host "root@cboy-ca-dns"
    nixosConfigurations.generic-nixos-facter = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [

        ./configuration.nix
        disko.nixosModules.disko
        agenix.nixosModules.default
        nixos-facter-modules.nixosModules.facter
        {
          config.facter.reportPath =
            ## When reusing this config on a new machine delete facter.json since it has to be specific for the new VM !!!
            if builtins.pathExists ./facter.json then
              ./facter.json
            else
              throw "Have you forgotten to run nixos-anywhere with `--generate-hardware-config nixos-facter ./facter.json`?";
        }

        {
          ## First boot we'll get DHCP, after Initial deployment we'll be using static IPs with cloud-init
          networking.useDHCP = nixpkgs.lib.mkForce false;

          services.cloud-init = {
            enable = true;
            network.enable = true;
          };
        }

      ];
    };
  };
}
