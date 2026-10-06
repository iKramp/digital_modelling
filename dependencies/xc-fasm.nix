{ python3Packages, xcFasmSrc }:

python3Packages.buildPythonPackage rec {
  pname = "f4pga-xc-fasm";
  version = "unstable-2022-...";

  src = xcFasmSrc;

  pyproject = false;
  dontBuild = true;
  doCheck = false;

  installPhase = ''
    mkdir -p "$out/${python3Packages.python.sitePackages}"
    cp -r xc_fasm "$out/${python3Packages.python.sitePackages}/"

    mkdir -p "$out/bin"
    for f in utils/*.py; do
      if [ -f "$f" ]; then
        install -Dm755 "$f" "$out/bin/$(basename "$f" .py)"
      fi
    done
  '';

  propagatedBuildInputs = with python3Packages; [
    # put the actual runtime dependencies here
  ];
}
