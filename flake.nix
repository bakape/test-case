{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, utils, nixpkgs, fenix, devshell }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ fenix.overlays.default devshell.overlays.default ];
        };
        inherit (pkgs) lib stdenv;
        rustPackageSet = with pkgs.fenix;
          combine [
            stable.cargo
            stable.clippy
            stable.rustc
            stable.rust-src
            stable.rustfmt
            stable.rust-analyzer
          ];
      in {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.devshell.mkShell {
          imports = [ "${devshell}/extra/language/rust.nix" ];
          packages = with pkgs; [
            rustPackageSet
            clang
            nixfmt-classic
            cargo-insta
          ];
          language.rust = {
            enableDefaultToolchain = false;
            packageSet = rustPackageSet;
          };
          env = with pkgs; [{
            name = "RUST_SRC_PATH";
            value =
              "${pkgs.fenix.stable.rust-src}/lib/rustlib/src/rust/library";
          }];
        };
      });
}
