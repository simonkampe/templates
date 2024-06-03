{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  inputs.poetry = {
    url = "github:nix-community/poetry2nix?ref=1.39.1";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, poetry }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ poetry.overlay ];
        config.permittedInsecurePackages = [
        ];
      };

      python = pkgs.python3;

      overrides = poetry2nix.overrides.withDefaults (self: super: {
      });

      inherit (pkgs) poetry2nix;
    in rec
    {
      defaultPackage = packages.hello_world;

      packages.hello_world = (poetry2nix.mkPoetryApplication {
        projectDir = ./.;
        python = python;

        overrides = overrides;
      }).overrideAttrs(old: {
        dontWrapQtApps = true;
        enableParallelBuilding = true;
        
        propagatedBuildInputs = with pkgs; [ ] ++ old.propagatedBuildInputs;
      });

      packages.env = (poetry2nix.mkPoetryEnv {
        projectDir = ./.;
        python = python;

        overrides = overrides;
      }).overrideAttrs(old: {
        LD_LIBRARY_PATH = "${pkgs.zlib}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.libGL}/lib:${pkgs.glib.out}/lib";

        propagatedBuildInputs = with pkgs; [
          zlib
          libGL
          glib
        ];

        nativeBuildInputs = with pkgs; [
          graphviz
          python.pkgs.pydeps
          python.pkgs.poetry
        ] ++ old.nativeBuildInputs;
      });

      packages.hello_world-docker =
      let
        abw = self.defaultPackage.${system};
      in pkgs.dockerTools.buildLayeredImage {
        name = "Hellow world";
        tag = "0.1.0";
        created = builtins.substring 0 8 self.lastModifiedDate;

        contents = [
          hello_world
          pkgs.bash
        ];

        config = {
          Cmd = [ "${pkgs.bash}/bin/bash" ];
        };
      };

      devShells.default = packages.env;
    }
  );
}

