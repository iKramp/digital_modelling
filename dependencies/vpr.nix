{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, boost
, eigen
, libxml2
, libelf
, zlib
, bison
, flex
, perl
, python3
, pkgs
}:

stdenv.mkDerivation rec {
  pname = "vpr";
  version = "8.0.0-5699";

  src = fetchFromGitHub {
    owner = "verilog-to-routing";
    repo = "vtr-verilog-to-routing";

    rev = "25e723a24aa0ae7a0061cd89dd84b1fb62afcc09";
    hash = "sha256-q3J89TiwrqsUHs0/H4cBMMDx2Xya8uiXndsUPti5DkA=";
  };

  capnpJavaSchema = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/capnproto/capnproto-java/master/compiler/src/main/schema/capnp/java.capnp";
    hash = "sha256-q8SNhZ/6Bqwmx9/mAgN0+w7l76STZwerw1vawiM676s=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    bison
    flex
    perl
    python3
  ];

  buildInputs = [
    boost
    eigen
    libxml2
    libelf
    zlib
  ];

  cmakeFlags = [
    "-DVTR_ENABLE_TESTING=OFF"
    "-DVTR_ENABLE_SANITIZERS=OFF"
    "-DVTR_ENABLE_GRAPHICS=OFF"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  postPatch = ''
  # librtlnumber uses uint8_t without including its definition.
  substituteInPlace libs/librtlnumber/src/include/rtl_utils.hpp \
    --replace-fail \
      '#include <string.h>' \
      '#include <string.h>
#include <cstdint>'

  # Bundled Catch2 uses uint8_t without including <cstdint>.
  substituteInPlace libs/EXTERNAL/libcatch2/src/catch2/catch_test_case_info.hpp \
    --replace-fail \
      '#include <' \
      '#include <cstdint>
#include <'

  substituteInPlace libs/EXTERNAL/libcatch2/src/catch2/catch_test_case_info.cpp \
    --replace-fail \
      '#include <algorithm>' \
      '#include <algorithm>
#include <cstdint>'

  substituteInPlace libs/EXTERNAL/libcatch2/src/catch2/internal/catch_xmlwriter.cpp \
    --replace-fail \
      '#include <iomanip>' \
      '#include <iomanip>
#include <cstdint>'


# Replace network download of capnp-java schema with the Nix-fetched file.
  substituteInPlace libs/libvtrcapnproto/CMakeLists.txt \
    --replace-fail \
    'COMMAND ''${WGET}
            https://raw.githubusercontent.com/capnproto/capnproto-java/master/compiler/src/main/schema/capnp/java.capnp
            -O ''${JAVA_SCHEMA}' \
      'COMMAND ''${CMAKE_COMMAND} -E copy ${capnpJavaSchema} ''${JAVA_SCHEMA}'

  cat libs/EXTERNAL/libinterchange/cmake/cxx_static/CMakeLists.txt
  substituteInPlace libs/EXTERNAL/libinterchange/cmake/cxx_static/CMakeLists.txt \
    --replace-fail \
      'COMMAND ''${WGET}
        https://raw.githubusercontent.com/capnproto/capnproto-java/master/compiler/src/main/schema/capnp/java.capnp
        -O ''${JAVA_SCHEMA}' \
      'COMMAND ''${CMAKE_COMMAND} -E copy ${capnpJavaSchema} ''${JAVA_SCHEMA}'

      substituteInPlace libs/libvtrcapnproto/CMakeLists.txt \
  --replace-fail \
    'find_program(WGET wget REQUIRED)' \
    '# WGET disabled: java.capnp is provided by Nix'

substituteInPlace libs/EXTERNAL/libinterchange/cmake/cxx_static/CMakeLists.txt \
  --replace-fail \
    'find_program(WGET wget REQUIRED)' \
    '# WGET disabled: java.capnp is provided by Nix'
'';

  postInstall = ''
    mkdir -p $out/bin
    cp vpr/vpr $out/bin/
  '';

  meta = {
    description = "VPR FPGA placement and routing tool";
    homepage = "https://github.com/verilog-to-routing/vtr-verilog-to-routing";
    license = lib.licenses.mit;
    mainProgram = "vpr";
  };
}
