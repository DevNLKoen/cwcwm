{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    wlroots-src = {
      url = "github:swaywm/wlroots";
      flake = false;
    };
  };

  outputs = {
    self,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];

      flake = {
        nixosModules.cwc = import ./nix/nixos-module.nix self;
      };

      perSystem = {
        config,
        pkgs,
        inputs,
        ...
      }: let
        inherit
          (pkgs)
          callPackage
          ;
        cwc = callPackage ./nix/default.nix {};
        shellOverride = old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [];
          buildInputs = old.buildInputs ++ [];
        };
        wlroots_0_20 = pkgs.wlroots_0_20.overrideAttrs (old: {
          src = inputs.wlroots-src;
          version = "0.20.0-git-${inputs.wlroots-src.shortRev or "dirty"}";
        });
      in {
        packages.default = cwc;
        overlayAttrs = {
          inherit (config.packages) cwc wlroots_0_20;
        };
        packages = {
          inherit cwc wlroots_0_20;
        };
        devShells.default = cwc.overrideAttrs shellOverride;
        formatter = pkgs.alejandra;
      };
      systems = ["x86_64-linux"];
    };
}
