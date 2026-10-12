{ stdenvNoCC
, lib
, pythonEnv
, f4pgaSrc
, archDefsBase
, archDefsDevice100t
, archDefsDevice50t
, vpr
, xcFasm
, xdcPlugin
, prjxrayDb
, which
, yosys
, coreutils
, bash
}:

stdenvNoCC.mkDerivation rec {
  pname = "f4pga-xc7";
  version = "2022-09-07";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/xc7 $out/bin $out/etc/profile.d $out/lib

    # These are the same two XC7 artifacts used by LogiSmith/toolchain-setup.
    tar -xJf ${archDefsBase} -C $out/xc7
    tar -xJf ${archDefsDevice100t} -C $out/xc7
    tar -xJf ${archDefsDevice50t} -C $out/xc7

    # Keep the VPR/FASM binaries inside the F4PGA prefix, matching the layout
    # expected by F4PGA's Python wrappers.
    ln -s ${vpr}/bin/vpr $out/bin/vpr
    ln -s ${vpr}/bin/genfasm $out/bin/genfasm
    ln -s ${xcFasm}/bin/xcfasm $out/bin/xcfasm

    # F4PGA's write_bitstream wrapper asks prjxray-config for the database root.
    cat > $out/bin/prjxray-config <<'SH'
#!${stdenvNoCC.shell}
printf '%s\n' '${prjxrayDb}'
SH
    chmod +x $out/bin/prjxray-config

    # Anvil still sources conda.sh and runs `conda activate xc7`.  This is only
    # a compatibility shim: no Conda environment is installed or modified.
    cat > $out/etc/profile.d/conda.sh <<'SH'
export CONDA_DEFAULT_ENV=xc7
export CONDA_PREFIX='@prefix@'
export PATH="@prefix@/bin:$PATH"
conda() {
  case "''${1:-}" in
    activate)
      export CONDA_DEFAULT_ENV="''${2:-xc7}"
      return 0
      ;;
    *)
      return 0
      ;;
  esac
}
SH
    substituteInPlace $out/etc/profile.d/conda.sh \
      --replace-fail '@prefix@' '$out'

    # Keep the F4PGA Python package in the Nix store rather than a writable
    # Conda environment. The exact source revision is supplied by the flake.
    cp -r ${f4pgaSrc}/f4pga $out/lib/f4pga

    substituteInPlace $out/lib/f4pga/wrappers/tcl/xc7.f4pga.tcl \
  --replace-fail 'plugin -i xdc' \
    'plugin -i ${xdcPlugin}/lib/yosys/plugins/xdc.so' \
  --replace-fail 'plugin -i fasm' \
    'plugin -i ${xdcPlugin}/lib/yosys/plugins/fasm.so' \
  --replace-fail 'plugin -i params' \
    'plugin -i ${xdcPlugin}/lib/yosys/plugins/params.so' \
  --replace-fail 'plugin -i sdc' \
    'plugin -i ${xdcPlugin}/lib/yosys/plugins/sdc.so' \
  --replace-fail 'plugin -i design_introspection' \
    'plugin -i ${xdcPlugin}/lib/yosys/plugins/design_introspection.so'

    substituteInPlace $out/lib/f4pga/wrappers/sh/__init__.py \
  --replace-fail 'executable="/bin/bash"' 'executable="${bash}/bin/bash"'

    for tool in synth pack place route write_fasm write_bitstream; do
      cat > "$out/bin/symbiflow_$tool" <<EOF2
#!${stdenvNoCC.shell}
export PATH="${pythonEnv}/bin:${yosys}/bin:${which}/bin:${coreutils}/bin:$out/bin:\$PATH"
export PYTHONPATH="$out/lib''${PYTHONPATH:+:\$PYTHONPATH}"
export F4PGA_INSTALL_DIR='$out'
export FPGA_FAM=xc7
exec '${pythonEnv}/bin/python' -c 'from f4pga.wrappers.sh import $tool as _tool; _tool()' "\$@"
EOF2
      chmod +x "$out/bin/symbiflow_$tool"
    done
  '';

  meta = {
    description = "Pinned F4PGA XC7 architecture data and wrappers for Anvil";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
