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
    pkgs.autoPatchelfHook
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

  preBuild = ''
    export CUDA_HOME=${cudaToolkit}
    export TORCH_CUDA_ARCH_LIST="12.0"
    export MAX_JOBS=8
    export CC=${pkgs.gcc13}/bin/gcc
    export CXX=${pkgs.gcc13}/bin/g++

    # 1. TORCH_CXX_FLAGS is never applied in CMakeLists.txt — patch it in
    substituteInPlace CMakeLists.txt \
      --replace "find_package(Torch REQUIRED)" \
      'find_package(Torch REQUIRED)
set(CMAKE_CXX_FLAGS "''${CMAKE_CXX_FLAGS} ''${TORCH_CXX_FLAGS}")'

    # 2. CMakeLists references $CONDA_PREFIX which doesn't exist in Nix —
    #    replace it with the actual paths
    substituteInPlace CMakeLists.txt \
      --replace "''${CONDA_PREFIX}/lib" "${pkgs.gmp}/lib" \
      --replace "''${CONDA_PREFIX}/include" "${pkgs.gmp.dev}/include"

    cmake . -DCMAKE_CUDA_COMPILER=${cudaToolkit}/bin/nvcc \
            -DCMAKE_CUDA_HOST_COMPILER=${pkgs.gcc13}/bin/g++ \
            -DCMAKE_PREFIX_PATH="${pythonPackages.torch-bin}/${pythonPackages.python.sitePackages}/torch" \
            -DCMAKE_CUDA_FLAGS="-I${cudaToolkit}/include" \
            -DCMAKE_CXX_FLAGS="-I${cudaToolkit}/include" \
            -DFETCHCONTENT_SOURCE_DIR_PYBIND11=${pythonPackages.pybind11.src} \
            -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
            -DGMP_INCLUDE_DIR=${pkgs.gmp.dev}/include \
            -DGMP_LIBRARIES=${pkgs.gmp}/lib/libgmp.so
    make -j$MAX_JOBS
  '';

  # Rescue the compiled .so file!
  # setuptools ignores the binary since it isn't declared in package_data.
  # We find the compiled extension and force-copy it into the output site-packages.
  postInstall = ''
    echo "Rescuing compiled C++ extension..."
    find . -name "*tetranerf_cpp_extension*.so" -exec cp {} $out/lib/python${pythonPackages.python.pythonVersion}/site-packages/tetranerf/utils/extension/ \;
  '';

  # Tell autoPatchelfHook to ignore PyTorch internals (they load dynamically at runtime)
  autoPatchelfIgnoreMissingDeps = [
    "libtorch_cpu.so"
    "libtorch.so"
    "libc10.so"
    "libcudart.so.12"
    "libc10_cuda.so"
    "libtorch_cuda.so"
  ];

  doCheck = false;
  
  # The setup.py finds the package "tetranerf", but the actual import 
  # might vary based on how they structured the folder. We skip the strict
  # import check here to avoid sandbox pathing issues.
}
