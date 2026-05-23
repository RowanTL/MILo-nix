{ pkgs, pythonPackages }:

pythonPackages.buildPythonPackage {
  pname = "nvdiffrast";
  version = "unstable-2023"; # Version string for the specific commit
  format = "setuptools";

  src = pkgs.fetchFromGitHub {
    owner = "NVlabs";
    repo = "nvdiffrast";
    rev = "729261dc64c4241ea36efda84fbf532cc8b425b8";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  # Numpy is the only installation requirement defined in setup.py
  propagatedBuildInputs = [
    pythonPackages.numpy
  ];

  # We don't need any complex compiler flags here because the actual 
  # C++ compiling happens at runtime inside your devShell.
  doCheck = false;
  pythonImportsCheck = [ "nvdiffrast" ];
}
