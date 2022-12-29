{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        whisperCpp = {
          src = builtins.fetchGit
            {
              url = "https://github.com/ggerganov/whisper.cpp";
              rev = "124c718c73f915f3e4235ae2af8841356e76177d";
            };

          # base-en = builtins.fetchurl
          #   {
          #     url = "https://huggingface.co/datasets/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
          #     sha256 = "sha256:00nhqqvgwyl9zgyy7vk9i3n017q2wlncp5p7ymsk0cpkdp47jdx0";
          #   };
        };

        craneLib = crane.lib.${system};
        pkgs = import nixpkgs {
          inherit system;
        };

        commonArgs = {
          preBuild = "cp -rs --no-preserve=mode,ownership ${whisperCpp.src} ./sys/whisper.cpp";

          # I have had issues with cleanCargoSource removing sys/wrapper.h
          # src = craneLib.cleanCargoSource ./.;
          src = ./.;

          nativeBuildInputs = with pkgs; [
            llvm
            clang
            llvmPackages.libclang
            rust-bindgen
          ];

          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

          # WHISPER_MODEL_BASE_EN = "${whisperCpp.base-en}";
        };

      in
      {
        packages.default = craneLib.buildPackage (commonArgs // { });
        devShells.default =
          pkgs.mkShell (commonArgs // { });
      }
    );
}
