{ pkgs, pythonPackages }:

pythonPackages.buildPythonPackage {
  pname = "open3d";
  version = "0.19.0";
  format = "wheel";

  # Notice the `cp312` in the filename for Python 3.12
  src = pkgs.fetchurl {
    url = "https://files.pythonhosted.org/packages/2b/95/3723e5ade77c234a1650db11cbe59fe25c4f5af6c224f8ea22ff088bb36a/open3d-0.19.0-cp312-cp312-manylinux_2_31_x86_64.whl"; 
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    libGL
    glib
    zlib
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    libusb1
  ];

  propagatedBuildInputs = with pythonPackages; [
    numpy
    matplotlib
    pandas
    scipy
    pyyaml
    tqdm
    scikit-learn
    ipywidgets
    addict
    werkzeug
    dash
    configargparse
    nbformat
  ];

  doCheck = false;
  pythonImportsCheck = [ "open3d" ];
}
