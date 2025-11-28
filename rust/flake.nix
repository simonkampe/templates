{
  description = "A template for a rust project";

  inputs = {
    nixpkgs.url      = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = rust;
          rustc = rust;
        };

        cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

      in rec
      {
        packages.defaultPackage = rustPlatform.buildRustPackage {
          pname = cargoToml.package.name;
          version = cargoToml.package.version;
          
          src = self;
          
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
          
          buildInputs = with pkgs; [
          ];
          
          nativeBuildInputs = with pkgs; [
            openssl
            pkg-config
          ];
        };

        # Build docker image with nix build .#docker
        packages.docker =
        let
          defaultPackage = self.defaultPackage.${system};
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

        devShells.default = pkgs.mkShell {
          RUST_BACKTRACE="full";

          name = "${cargoToml.package.name}-dev"

          packages = with pkgs; [
            # Tools
            (rust.override { extensions = ["rust-src" "rustfmt" "clippy"]; })
            rust-analyzer
            clippy
          ] ++ packages.defaultPackage.buildInputs ++ packages.defaultPackage.nativeBuildInputs;
        };
      }
    );
}
