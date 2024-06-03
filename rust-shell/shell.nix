{ pkgs ? import <nixpkgs> {
    overlays = [
      (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
    ];
  }
}:
let
  rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;
in pkgs.mkShell {
  LD_LIBRARY_PATH="/run/opengl-driver/lib/:${pkgs.libGL}/lib/:${pkgs.libGLU}/lib/:${pkgs.vulkan-headers}:${pkgs.vulkan-loader}/lib/";
  RUST_BACKTRACE="full";

  nativeBuildInputs = with pkgs; [
    pkg-config
    rust
    rust-analyzer

    # Build deps
    zlib
    openssl
    pkg-config
    cmake

    # GUI
    fontconfig
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    vulkan-headers
    vulkan-loader
  ];
}
