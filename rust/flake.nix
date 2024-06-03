{
  description = "A template for a rust project";

  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      in rec
      {
        packages.hello_world = pkgs.rustPlatform.buildRustPackage {
          pname = "hello_world";
          version = "0.0.0";
          
          src = self;
          
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
          
          buildInputs = with pkgs; [
          ];
          
          nativeBuildInputs = with pkgs; [
            rust
            openssl
            pkg-config
          ];
        };
        defaultPackage = packages.hello_world;

        # Build docker image with nix build .#docker
        packages.docker =
        let
          hello_world = self.defaultPackage.${system};
        in pkgs.dockerTools.buildLayeredImage {
          name = hello_world.name;
          tag = hello_world.version;

          contents = [
            hello_world # Even if we use the binary in the mount, we still need all the deps.
          ];

          config = {
            Entrypoint = [ "hello_world" ];
            Cmd = [ ];
            WorkingDir = "/";
          };
        };

        devShell = pkgs.mkShell {
          RUST_BACKTRACE="full";

          nativeBuildInputs = with pkgs; [
            # Tools
            rust
            rust-analyzer
            clippy

            # Build deps
            openssl
            pkg-config
          ];
        };
      }
    );
}
