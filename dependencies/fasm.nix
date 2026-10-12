{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonPackage rec {
  pname = "fasm";
  version = "0.0.2.post100";

  src = fetchFromGitHub {
    owner = "chipsalliance";
    repo = "fasm";
    rev = "master";
    hash = "sha256-VzTwkEfczgpCO3WY2d7DseLcvMARmZU0mUr/oQBXcSo=";
  };

  format = "other";

  dontConfigure = true;
  dontBuild = true;

  propagatedBuildInputs = with python3Packages; [
    textx
  ];

  installPhase = ''
    runHook preInstall

    install -d "$out/${python3Packages.python.sitePackages}/fasm"
    cp -r fasm/. "$out/${python3Packages.python.sitePackages}/fasm/"

    runHook postInstall
  '';

  pythonImportsCheck = [ "fasm" ];

  doCheck = false;

  meta = {
    description = "FPGA Assembly parser and generator";
    homepage = "https://github.com/chipsalliance/fasm";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
}
