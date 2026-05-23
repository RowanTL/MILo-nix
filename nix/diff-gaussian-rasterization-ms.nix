{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage {
  pname = "diff-gaussian-rasterization-ms";
  version = "0.0.1"; # You can bump this as needed
  format = "setuptools";

  # The source directory copied into the Nix sandbox
  src = srcPath;

  nativeBuildInputs = [
    pkgs.ninja
    pkgs.which
    cudaToolkit
  ];

  buildInputs = [
    pythonPackages.pytorch-bin
    pkgs.stdenv.cc.cc.lib
  ];

  # Set the environment variables right before the build phase
  preBuild = ''
    export CUDA_HOME=${cudaToolkit}
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=8
  '';

  # Disable tests during the Nix build phase since this is a hardware-dependent 
  # rendering extension. It's safer to test it interactively in the devShell.
  doCheck = false;
  
  # Ensure the extension built correctly and can be imported
  pythonImportsCheck = [ "diff_gaussian_rasterization_ms" ];
}
