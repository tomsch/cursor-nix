{
  description = "Cursor - AI-first code editor";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      packages.${system} = {
        default = pkgs.callPackage ./package.nix {};
        cursor = self.packages.${system}.default;
      };

      overlays.default = final: prev: {
        cursor = final.callPackage ./package.nix {};
      };
    };
}
