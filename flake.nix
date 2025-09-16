{
  description = "Homelab NixOS configuration";

  inputs = {
    sops-nix.url = "github:Mic92/sops-nix";
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # This merges the libraries from `nixpkgs` and `home-manager` using the `//` operator.
    # If there are any overlapping keys, the set on the right side (`home-manager.lib`) will override the keys from the set on the left side (`nixpkgs.lib`).
    lib = nixpkgs.lib // home-manager.lib;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    inherit lib;
    formatter = forEachSystem (pkgs: pkgs.nixpkgs-fmt);
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    overlays = import ./overlays {inherit inputs;};
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    nixosConfigurations = {
      atlas = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/atlas];
      };

      daedalus = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/daedalus];
      };

      hermes = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/hermes];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "amaddox@atlas" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/home.nix
        ];
      };
    };
  };
}
