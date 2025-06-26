{
  stdenv,
  lib,
  pkgsCross,
  bash,
  gnumake,
  kconfig-frontends,
  genromfs,
  xxd,
  unzip,
  meson,
  ninja,
  util-linux,
  jq,
  fq,
  src,
  name,
}: let
  inherit (builtins) toString;
  inherit (lib) platforms;
in
  stdenv.mkDerivation {
    pname = "${name}";
    inherit (src) src version GIT_REV;

    nativeBuildInputs = [
      # NuttX build dependencies
      pkgsCross.riscv32-embedded.buildPackages.gcc
      bash
      gnumake
      kconfig-frontends
      genromfs
      xxd
      unzip

      # Meson integration
      meson
      ninja
      util-linux
      jq
      fq
    ];
    dontUseNinjaBuild = true;
    dontPatchELF = true;
    enableParallelBuilding = true;

    postUnpack = ''
      patchShebangs --build $sourceRoot
      find $sourceRoot/nuttx -type f |
        xargs touch -md "$(date -d '@${toString src.lastModified}')"
    '';
    configurePhase = ''
      make olddefconfig
      make nuttx/.config
    '';
    installPhase = ''
      mkdir -p $out
      cp nuttx/core/nuttx $out/nuttx.elf
      cp nuttx/core/nuttx.map $out/
      cp nuttx/core/System.map $out/
      cp nuttx/core/.config $out/
    '';

    doCheck = false;
    meta.platforms = platforms.linux;
  }
