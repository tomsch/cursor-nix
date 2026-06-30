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
        cursor-cli = pkgs.callPackage ./package-cli.nix {};
      };

      overlays.default = final: prev: {
        cursor = final.callPackage ./package.nix {};
        cursor-cli = final.callPackage ./package-cli.nix {};
      };
    };
}
