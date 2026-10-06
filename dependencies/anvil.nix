{ lib
, stdenvNoCC
, makeWrapper
, python3
, fetchFromGitHub
, f4pga
, f4pgaExamples
, openfpgaloader
}:

stdenvNoCC.mkDerivation {
  pname = "anvil";
  version = "unstable-2026-10-05";

  src = fetchFromGitHub {
    owner = "LogiSmith";
    repo = "Anvil";
    rev = "main";
    hash = "sha256-6Jyfr+LeH4v33PJrykCR+SpvZDbUuggEjRirtGrXq4A=";
  };

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace anvil.py \
      --replace-fail \
        'CONDA_SH       = os.path.expanduser("~/miniconda3/etc/profile.d/conda.sh")' \
        'CONDA_SH       = "${f4pga}/etc/profile.d/conda.sh"' \
      --replace-fail \
        'F4PGA_INSTALL  = os.path.expanduser("~/opt/f4pga")' \
        'F4PGA_INSTALL  = "${f4pga}"' \
      --replace-fail \
        'F4PGA_EXAMPLES = os.path.expanduser("~/f4pga-examples")' \
        'F4PGA_EXAMPLES = "${f4pgaExamples}"' \
      --replace-fail \
        'OPENFPGALOADER = "/usr/local/bin/openFPGALoader"' \
        'OPENFPGALOADER = "${openfpgaloader}/bin/openFPGALoader"'
  '';

  installPhase = ''
    mkdir -p $out/share/anvil
    cp -r . $out/share/anvil

    makeWrapper ${python3}/bin/python3 $out/bin/anvil \
      --add-flags "$out/share/anvil/anvil.py" \
      --run 'export HOME="''${ANVIL_HOME:-$HOME}"'
  '';

  meta = {
    description = "Open-source FPGA CLI for the F4PGA toolchain and RISC-V SoCs";
    homepage = "https://github.com/LogiSmith/Anvil";
    license = lib.licenses.mit;
    mainProgram = "anvil";
  };
}
