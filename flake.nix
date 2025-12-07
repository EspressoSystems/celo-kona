{
  description = "celo-kona dev env (Rust 1.88 + test tooling)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Rust 1.88 toolchain to match rust-toolchain.toml / workspace metadata
        rustToolchain = pkgs.rust-bin.stable."1.88.0".minimal.override {
          extensions = [
            "clippy"
            "rustfmt"
            "llvm-tools-preview"
            "rust-src"
          ];
        };
      in
      with pkgs; {
        devShell = mkShell {
          buildInputs = [
            rustToolchain

            # Test & workspace tools (see Justfile)
            cargo-nextest
            cargo-hack
            just

            # Common system libraries / tooling
            pkg-config
            openssl
            rocksdb
            curl
            git
          ] ++ lib.optionals stdenv.isDarwin [
            darwin.apple_sdk.frameworks.Security
          ];

          shellHook = ''
            export RUST_BACKTRACE=full
            export PATH="$PATH:$(pwd)/target/debug:$(pwd)/target/release"
          '';
        };
      }
    );
}
