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

    # home-manager, used for managing user configuration - https://github.com/nix-community/home-manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      #url = "github:nix-community/home-manager"; # this leads to version mismatch
      # The `follows` keyword in inputs is used for inheritance.
      # Here, `inputs.nixpkgs` of home-manager is kept consistent with the `inputs.nixpkgs` of the current flake,
      # to avoid problems caused by different versions of nixpkgs dependencies.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    ## https://flake.parts/index.html
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    ## https://github.com/nix-systems/nix-systems
    systems.url = "github:nix-systems/default";

    # impermanence.url = "github:nix-community/impermanence";

    ## https://nix-community.github.io/haumea/
    ## Manually importing files can be tedious, especially when there are many of them.
    ## Haumea takes care of all of that by automatically importing the files into an attribute set.
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
    ## Host `github-cowboy` and subsequent connection settings are defined in programs.ssh.extraConfig
    ## Test conn with `ssh git@github-cowboy`
    ## Update only this input with: `nix flake lock --update-input mysecrets`
    # mysecrets = {
    #   url = "git+ssh://git@github-cowboy/TheCowboyAI/inception-pki-templates-secrets.git?shallow=1";
    #   flake = false;
    # };

  };

    ## Develop the configuration localy with: nixos-rebuild --flake .#realm build
    ## 1. Get the VM ISO or PXE image from https://github.com/nix-community/nixos-images - the official starter images don't work.
    ## 2. Create a new VM in your hypervisor using the above image and boot the machine.
    ## Make sure that there is no old facter.json file in your repo.
    ## 3. Initial deployment on new VM using ssh password printed on the console:
    ##      nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-facter ./facter.json --flake .#realm --target-host root@DHCP_VM_IP
    ##      nix run github:nix-community/nixos-anywhere -- --generate-hardware-config nixos-facter ./facter.json --flake .#realm --target-host root@10.230.10.29
    ## 4. Updating the deployed VM using ssh key provided by inception:
    ##      nixos-rebuild switch --flake .#realm --use-remote-sudo --target-host "cowboy@cboy-realm"
    ## To do a dist upgrade
    ##      nixos-rebuild switch --recreate-lock-file --flake .#realm --use-remote-sudo --target-host "cowboy@cboy-realm"
    ## nix flake update --recreate-lock-file
    ## nix flake update --update-input home-manager
    ## Get the previous boot: journalctl --boot -1

  outputs = { self, disko, nixpkgs, nixos-facter-modules, agenix, flake-parts, systems, home-manager, ... }@inputs: {

  # { let
  #   system = "x86_64-linux";
  #   pkgs = import nixpkgs {
  #     inherit system;
  #     config.allowUnfree = true;
  #   };
  #   lib = nixpkgs.lib;
  # in {

    nixosConfigurations = {
      realm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          # home-manager.nixosModules.home-manager {
          #   home-manager.useGlobalPkgs = true;
          #   home-manager.useUserPackages = true;
          #   # home-manager.users.cowboy = {
          #   #   imports = [ ./hosts/realm/home.nix ];
          #   # };
          #   #home-manager.users.cowboy = import ./homes/cowboy.nix {inherit pkgs;};
          #   home-manager.users.cowboy = import ./homes/cowboy.nix;
          #   #home-manager.extraSpecialArgs = {inherit pkgs; };
          # }

          ./hosts/realm/configuration.nix

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
  };
}
