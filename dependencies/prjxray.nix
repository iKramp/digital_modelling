{ lib
, stdenv
, python3Packages
, prjxraySrc
}:

stdenv.mkDerivation {
  pname = "prjxray";
  version = "unstable-2022-07-08";

  src = prjxraySrc;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/python3/site-packages
    cp -r prjxray $out/lib/python3/site-packages/

    mkdir -p $out/bin
    for f in utils/*.py; do
      if [ -f "$f" ]; then
        install -Dm755 "$f" "$out/bin/$(basename "$f" .py)"
      fi
    done
  '';

  propagatedBuildInputs = with python3Packages; [
    bitarray
    intervaltree
    numpy
    pyyaml
    simplejson
  ];

  meta = {
    description = "Project X-Ray FPGA reverse engineering tools";
    homepage = "https://github.com/f4pga/prjxray";
    license = lib.licenses.bsd3;
  };
}
