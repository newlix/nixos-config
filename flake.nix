{
  description = "newlix NixOS & nix-darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, zen-browser, ... } @ inputs: {

    # ── NixOS (lab) ────────────────────────────────────────────────────────
    nixosConfigurations.lab = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.nixosModules.home-manager
        ./hosts/lab/hardware-configuration.nix
        ./hosts/lab/configuration.nix
      ];
    };

    # ── macOS (mac) ────────────────────────────────────────────────────────
    darwinConfigurations.mac = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; };
      modules = [
        home-manager.darwinModules.home-manager
        ./hosts/mac/configuration.nix
      ];
    };
  };
}
