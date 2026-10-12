{ stdenv
, coreutils
, pkg-config
, yosys
, yosysPluginsSrc
, python3
, boost
, readline
, zlib
}:

stdenv.mkDerivation {
  pname = "yosys-f4pga-plugins";
  version = "1.20230906";

  src = yosysPluginsSrc;

  nativeBuildInputs = [
    coreutils
    pkg-config
  ];

  buildInputs = [
    yosys
    python3
    boost
    readline
    zlib
  ];

  dontConfigure = true;

  postPatch = ''
    patchShebangs .

    grep -rlZ '/usr/bin/env' . \
      | xargs -0 -r sed -i \
          's|/usr/bin/env|${coreutils}/bin/env|g'
  '';

  buildPhase = ''
    runHook preBuild

    export CPLUS_INCLUDE_PATH="${yosys}/include:$CPLUS_INCLUDE_PATH"
    export LIBRARY_PATH="${boost}/lib:${readline}/lib:${zlib}/lib:$LIBRARY_PATH"

    for plugin in \
      xdc \
      fasm \
      params \
      sdc \
      design_introspection
    do
      make -C "$plugin-plugin" "$plugin.so" YOSYS_PATH=${yosys}
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for plugin in \
      xdc \
      fasm \
      params \
      sdc \
      design_introspection
    do
      install -Dm755 \
        "$plugin-plugin/build/$plugin.so" \
        "$out/lib/yosys/plugins/$plugin.so"
    done

    runHook postInstall
  '';
}
