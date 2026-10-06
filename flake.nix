{
  description = "FPGA development environment for Nexys A7-100T";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";

    # Pinned to the versions used by LogiSmith/toolchain-setup.
    f4pga-src = {
      url = "github:chipsalliance/f4pga/e1cd038f06c7161b27afd0073fb507da2b8e5a9e";
      flake = false;
    };
    f4pga-examples = {
      url = "github:chipsalliance/f4pga-examples/13f11197b33dae1cde3bf146f317d63f0134eacf";
      flake = false;
    };
    prjxray-db = {
      url = "github:f4pga/prjxray-db/0a0adde";
      flake = false;
    };
    xc-fasm-src = {
      url = "github:chipsalliance/f4pga-xc-fasm/25dc605c9c0896204f0c3425b52a332034cf5e5c";
      flake = false;
    };
    prjxray-src = {
      url = "github:f4pga/prjxray/ae546d6b7648bf4df9cf63f0b25b2028b5623c43";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        pythonVersion = pkgs.python311;
        pythonPackages = pkgs.python311Packages;

        pythonEnv = pythonVersion.withPackages (ps: with ps; [
          colorama
          bitarray
          intervaltree
          lxml
          numpy
          pyyaml
          simplejson
          ordered-set
          parse
          progressbar2
          pyjson5
          python-constraint
          scipy
          sympy
          textx
          prjxray
        ]);

        prjxray = pkgs.callPackage ./dependencies/prjxray.nix { 
          python3Packages = pythonPackages;
          prjxraySrc = inputs.prjxray-src;
        };

        xcFasm = pkgs.callPackage ./dependencies/xc-fasm.nix {
          python3Packages = pythonPackages;
          xcFasmSrc = inputs.xc-fasm-src;
        };

        vpr = pkgs.callPackage ./dependencies/vpr.nix {
          python3 = pythonVersion;
        };

        archDefsBase = pkgs.fetchurl {
          url = "https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/20220907-210059/symbiflow-arch-defs-install-xc7-66a976d.tar.xz";
          hash = "sha256-j6GqnPwDPJ/vWcKsGdT/GFaKZryM4Vwzhc2ewdGQEnQ=";
        };
        archDefsDevice100t = pkgs.fetchurl {
          url = "https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/20220907-210059/symbiflow-arch-defs-xc7a100t_test-66a976d.tar.xz";
          hash = "sha256-SbNV6KRC5GZSx7CJwj3AINS6u4AJ2PRJTgnXLjey5e8=";
        };
        archDefsDevice50t = pkgs.fetchurl {
          url = "https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/20220907-210059/symbiflow-arch-defs-xc7a50t_test-66a976d.tar.xz";
          hash = "sha256-gZ6dVMkYKGlWIBREv3i0gq6UsyAukAw99ZPQEsFY108=";
        };

        archDefsDeviceExtracted100t = pkgs.runCommand "arch-defs-device-extracted" {
          buildInputs = [ pkgs.xz ];
        } ''
          mkdir -p $out
          tar -xJf ${archDefsDevice100t} -C $out
        '';
        archDefsDeviceExtracted50t = pkgs.runCommand "arch-defs-device-extracted" {
          buildInputs = [ pkgs.xz ];
        } ''
          mkdir -p $out
          tar -xJf ${archDefsDevice50t} -C $out
        '';

        # merge. share/f4pha/arch/ is common. Link or copy inside
        archDefsDeviceExtracted = pkgs.runCommand "arch-defs-device-extracted" {
          buildInputs = [ pkgs.coreutils ];
        } ''
          mkdir -p $out/share/f4pga/arch
          cp -r ${archDefsDeviceExtracted100t}/share/f4pga/arch/xc7a100t_test $out/share/f4pga/arch/
          cp -r ${archDefsDeviceExtracted50t}/share/f4pga/arch/xc7a50t_test $out/share/f4pga/arch/
        '';

        f4pga = pkgs.callPackage ./dependencies/f4pga.nix {
          inherit pythonEnv vpr xcFasm archDefsBase archDefsDevice100t archDefsDevice50t;
          f4pgaSrc = inputs.f4pga-src;
          prjxrayDb = inputs.prjxray-db;
        };

        anvil = pkgs.callPackage ./dependencies/anvil.nix {
          inherit f4pga;
          f4pgaExamples = inputs.f4pga-examples;
          openfpgaloader = pkgs.openfpgaloader;
        };

      in {
        packages = {
          inherit anvil f4pga vpr prjxray xcFasm;
          default = anvil;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            anvil
            f4pga
            openfpgaloader
            haskellPackages.sv2v
            yosys

            pkgsCross.riscv64-embedded.stdenv.cc
            verilog
          ];

          shellHook = ''
            # expects riscv64-unknown-elf-g++ to be in PATH, but the cross compiler is named riscv64-none-elf-g++
            mkdir -p "$TMPDIR/riscv-bin"
            ln -sf ${pkgs.pkgsCross.riscv64-embedded.stdenv.cc}/bin/riscv64-none-elf-g++ \
              "$TMPDIR/riscv-bin/riscv64-unknown-elf-g++"
            ln -sf ${pkgs.pkgsCross.riscv64-embedded.stdenv.cc}/bin/riscv64-none-elf-objcopy \
              "$TMPDIR/riscv-bin/riscv64-unknown-elf-objcopy"
            export PATH="$TMPDIR/riscv-bin:$PATH"


            # Keep any HOME-based fallback state in a disposable directory.
            export ANVIL_HOME="''${TMPDIR:-/tmp}/anvil-home-''${USER:-user}"
            mkdir -p "$ANVIL_HOME"

            mkdir -p "$ANVIL_HOME/opt/f4pga/xc7/share/f4pga/arch"
            # tar -xJf "${archDefsBase}" -C "$ANVIL_HOME/opt/f4pga/xc7"
            ln -s "${archDefsDeviceExtracted}" "$ANVIL_HOME/opt/f4pga/xc7/share/f4pga/arch/xc7a100t_test"

            echo "Anvil/F4PGA shell: Nexys-A7-100T (xc7a100t_test)"
            echo "  ANVIL_HOME=$ANVIL_HOME"
            exec zsh
          '';
        };
      });
}
