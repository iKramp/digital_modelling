{
  lib,
  stdenv,
  cmake,
  python3Packages,
  abseil-cpp,
  gflags,
  yaml-cpp,
  fetchFromGitHub
}:

python3Packages.buildPythonPackage {
  pname = "prjxray";
  version = "unstable-2022-07-08";

  src = fetchFromGitHub {
    owner = "f4pga";
    repo = "prjxray";
    rev = "c9f02d8576042325425824647ab5555b1bc77833";
    hash = "sha256-cuqjVLTy9JZxuoD8vPsRfSFCv/HhhSdburx1a9EJajM=";
    fetchSubmodules = true;
  };
  format = "other";

  nativeBuildInputs = [ cmake ];

  buildInputs = [
    abseil-cpp
    gflags
    yaml-cpp
  ];

  dontConfigure = true;

  buildPhase = ''
  runHook preBuild
  
  cmake -S . -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DPRJXRAY_BUILD_TESTING=OFF \
    -DBUILD_TESTING=OFF
  
  cmake --build build --target xc7frames2bit \
    -j$NIX_BUILD_CORES
  
  runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -d "$out/${python3Packages.python.sitePackages}"
    cp -r prjxray "$out/${python3Packages.python.sitePackages}/"

    install -d "$out/bin" 
    install -m755 build/tools/xc7frames2bit "$out/bin/xc7frames2bit"

    for f in utils/*.py; do 
      if [ -f "f" ]; then 
        install −Dm755 "$f" "$out/bin/$(basename "$f" .py)" 
      fi 
    done

    runHook postInstall '';

  propagatedBuildInputs = with python3Packages; [
    bitarray
    intervaltree
    numpy
    pyyaml
    simplejson
  ];

  pythonImportsCheck = [ "prjxray" ];

  meta = {
    description = "Project X-Ray FPGA reverse engineering tools";
    homepage = "https://github.com/f4pga/prjxray";
    license = lib.licenses.bsd3;
  };
}
