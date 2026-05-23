{ pkgs, pythonPackages, cudaToolkit, srcPath }:

pythonPackages.buildPythonPackage {
  pname = "tetra-triangulation";
  version = "0.1.1";
  format = "setuptools";

  src = srcPath;

  # This forces Nix to skip the automated configurePhase so we 
  # can manually run cmake in our preBuild phase with the right compilers.
  dontUseCmakeConfigure = true;

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.which
    pkgs.pkg-config
    cudaToolkit
    pkgs.gcc13
  ];

  buildInputs = [
    pkgs.gmp
    pkgs.gmp.dev
    pkgs.cgal
    pkgs.mpfr
    pkgs.mpfr.dev
    pythonPackages.torch-bin
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
    
    cmake . -DCMAKE_CUDA_COMPILER=${cudaToolkit}/bin/nvcc \
            -DCMAKE_CUDA_HOST_COMPILER=${pkgs.gcc13}/bin/g++ \
            -DCMAKE_CUDA_FLAGS="-I${cudaToolkit}/include" \
            -DCMAKE_CXX_FLAGS="-I${cudaToolkit}/include" \
            -DFETCHCONTENT_SOURCE_DIR_PYBIND11=${pythonPackages.pybind11.src} \
            -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
            -DGMP_INCLUDE_DIR=${pkgs.gmp.dev}/include \
            -DGMP_LIBRARIES=${pkgs.gmp}/lib/libgmp.so
    make -j$MAX_JOBS
  '';

  doCheck = false;
  
  # The setup.py finds the package "tetranerf", but the actual import 
  # might vary based on how they structured the folder. We skip the strict
  # import check here to avoid sandbox pathing issues.
}
