{
  description = "Python 3.11, PyTorch (Blackwell Support), and CUDA 12.8";

  inputs = {
    # We must use unstable to access CUDA 12.8+ and PyTorch 2.7+ 
    # Older stable branches do not have the required binaries for the RTX 5080
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
            cudaVersion = "12.8"; # REQUIRED for RTX 50-series GPUs
          };
        };

        open3d = import ./nix/open3d.nix {
          inherit pkgs;
          pythonPackages = pkgs.python312Packages;
        };

        diffGaussianRasterizationMS = import ./nix/diff-gaussian-rasterization-ms.nix {
          inherit pkgs;
          cudaToolkit = pkgs.cudaPackages_12_8.cudatoolkit;
          pythonPackages = pkgs.python312Packages;
          
          srcPath = ./submodules/diff-gaussian-rasterization_ms;
        };

        diffGaussianRasterization = import ./nix/diff-gaussian-rasterization.nix {
          inherit pkgs;
          cudaToolkit = pkgs.cudaPackages_12_8.cudatoolkit;
          pythonPackages = pkgs.python312Packages;

          srcPath = ./submodules/diff-gaussian-rasterization;
        };

        pythonEnv = pkgs.python312.withPackages (ps: with ps; [
          torch-bin
          torchvision-bin
          torchaudio-bin
          numpy
          trimesh
          open3d
          scikit-image
          opencv-python
          plyfile
          tqdm
          diffGaussianRasterizationMS
          diffGaussianRasterization
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          name = "rtx5080-cuda12.8-py3.12-env";

          buildInputs = [
            pythonEnv
            pkgs.cudaPackages_12_8.cudatoolkit
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.mkl
          ];

          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            export LD_LIBRARY_PATH=/run/opengl-driver/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH

            echo "==================================================="
            echo "🚀 RTX 5080 / CUDA 12.8 & Python 3.12 loaded!"
            echo "==================================================="
            
            python -c "import torch; print(f'PyTorch Version: {torch.__version__}'); print(f'CUDA Available:  {torch.cuda.is_available()}')"
          '';
        };
      }
    );
}
