{
  description = ''
    A flake to install and configure the SDDM Sugar Candy theme on NixOS
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    lib = nixpkgs.lib;
    genSystems = lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];
    pkgsFor = genSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [ self.overlays.sddm-sugar-candy ];
      }
    );
  in {
    packages = genSystems (system:
      (self.overlays.default pkgsFor.${system} pkgsFor.${system})
      // { default = self.packages.${system}.sddm-sugar-candy; }
    );
    overlays = (import ./nix/overlays.nix { })
    // { default = self.overlays.sddm-sugar-candy ; };
  };
}
