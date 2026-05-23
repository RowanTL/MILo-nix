{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage {
  pname = "fused-ssim";
  version = "0.0.1";
  format = "setuptools";

  src = srcPath;

  nativeBuildInputs = [
    pkgs.ninja
    pkgs.which
    cudaToolkit
    pkgs.gcc13
  ];

  buildInputs = [
    pythonPackages.torch-bin
    pkgs.gcc13.cc.lib
  ];

  preBuild = ''
    export CUDA_HOME=${cudaToolkit}
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=8
    
    export CC=${pkgs.gcc13}/bin/gcc
    export CXX=${pkgs.gcc13}/bin/g++
  '';

  doCheck = false;
  
  # Note: The setup.py specifies the package name as fused_ssim 
  pythonImportsCheck = [ "fused_ssim" ];
}
