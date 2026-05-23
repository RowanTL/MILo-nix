{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage rec {
  pname = "tetra-triangulation";
  version = "0.1.1";
  format = "setuptools";

  src = srcPath;

  nativeBuildInputs = [
    pkgs.cmake # Replaces conda install cmake
    pkgs.ninja
    pkgs.which
    cudaToolkit
    pkgs.gcc13
  ];

  buildInputs = [
    pkgs.gmp   # Replaces conda install gmp
    pkgs.cgal  # Replaces conda install cgal
    pythonPackages.pytorch-bin
    pkgs.gcc13.cc.lib
  ];

  propagatedBuildInputs = [
    pythonPackages.trimesh # Required by setup.py
  ];

  # We use the preBuild phase to replicate the author's custom compile script
  preBuild = ''
    export CUDA_HOME=${cudaToolkit}
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=8
    
    export CC=${pkgs.gcc13}/bin/gcc
    export CXX=${pkgs.gcc13}/bin/g++

    echo "==================================================="
    echo "🔨 Running manual CMake & Make for Tetra Triangulation"
    echo "==================================================="
    
    # Run cmake and make in the source directory exactly like the script does
    cmake .
    make -j$MAX_JOBS
  '';

  doCheck = false;
  
  # The setup.py finds the package "tetranerf", but the actual import 
  # might vary based on how they structured the folder. We skip the strict
  # import check here to avoid sandbox pathing issues.
}
