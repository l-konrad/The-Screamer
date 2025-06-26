# NuttX Meson project template

This project provides common base for NuttX projects where the applications are
managed by Meson build system. It is intended to be merged to the new projects
to introduce the common build infrastructure and testing. This description
should be changed  to the description of your project. Do NOT forget to modify
it together with the title of this file, board info and other resources
mentioned in this readme file.

The board support package is implemented for [RISC-V
QEMU](https://nuttx.apache.org/docs/latest/platforms/risc-v/qemu-rv/boards/rv-virt/index.html).
The template is intended to be the initial code base for new Meson build system
managed embedded NuttX projects.

* [📃 Sources](https://gitlab.com/Cynerd/nuttx-meson-template)
* [⁉️ Issue tracker](https://gitlab.com/Cynerd/nuttx-meson-template/-/issues)


## Build environment and dependencies

The build environment, that is all necessary software required to build
firmware, is provided using Nix. To use it you have to install it, please refer
to the [Nix's documentation for that](https://nixos.org/download.html). Also
only Linux is supported and tested. Windows build of NuttX does not seem to work
and is not supported by this project template.

Once you have Nix you can use it to enter development environment. Navigate to
the project's directory and run `nix develop`.

You can also use any other source for the build dependencies as documented by
NuttX documentation if you do not want to use Nix.

## Building

Make sure that submodules are checked out before you attempt build:

```console
$ git submodule update --init --recursive
```

To build firmware you can simply invoke `make`. The build takes considerable
amount of time and thus it is beneficial to spawn multiple jobs in parallel
which can be done for example this way:

```console
$ make -j$(($(nproc) * 2)) -l$(nproc)
```

This configures and compiles the firmware. The next step is commonly upload to
the board but in case of this project setup it is Qemu. You can run NuttX in
Qemu with:

```console
$ make run
```

## NuttX configuration

NuttX provides KConfig based configuration and as well as this project. To run
Kconfig's Menuconfig for this project you can call `make menuconfig`. To run
Kconfig's Menuconfig for NuttX run `make nuttx/menuconfig`. The `nuttx/` prefix
can be used for any Make target that is normally available in NuttX.

## Building for the PC

To compile this project for the PC you have to use standard Meson command:

```console
$ meson setup builddir
$ meson compile -C builddir
```

## Release

The project can be released trough Gitlab CI. The release is triggered on Git
tag. The tag has to have form `vX.Y.Z` where `X` is major, `Y` is minor and `Z`
is fixup version number. This matches Semantic Versioning.

The version has to be also recorded in `CHANGELOG.md` as the latest (the first
in the document) version.

This workflow is simplified by `release.sh` file.
