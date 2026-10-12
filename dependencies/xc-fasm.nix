{ python3Packages, xcFasmSrc }:

python3Packages.buildPythonPackage rec {
  pname = "f4pga-xc-fasm";
  version = "0.0.1";

  src = xcFasmSrc;
  fasm = python3Packages.callPackage ./fasm.nix {};

  dontConfigure = true;
  dontBuild = true;
  format = "other";

  installPhase = ''
    runHook preInstall

    install -d "$out/${python3Packages.python.sitePackages}"
    cp -r xc_fasm "$out/${python3Packages.python.sitePackages}/"

    mkdir -p "$out/bin"
    for f in utils/*.py; do
      if [ -f "$f" ]; then
        install -Dm755 "$f" "$out/bin/$(basename "$f" .py)"
      fi
    done

    runHook postInstall
  '';

  postInstall = ''
    makeWrapper ${python3Packages.python.interpreter} $out/bin/xcfasm \
      --add-flags "-m" \
      --add-flags "xc_fasm.xc_fasm"
  '';

  dependencies = with python3Packages; [
    bitarray
    intervaltree
    numpy
    pyyaml
    simplejson
    fasm
  ];

  pythonImportsCheck = [ "xc_fasm" ];
}
