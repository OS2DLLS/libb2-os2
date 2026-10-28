# libb2

C library providing BLAKE2b, BLAKE2s, BLAKE2bp, and BLAKE2sp. The CMake build
uses the portable reference implementation by default; it does not inherit
host CPU flags or runtime SIMD dispatch when cross-compiling.

## Native build and tests

The root `/data/Makefile` uses Qt's bundled BLAKE2 implementation for both the
native Linux Qt host build and the OS/2 Qt target (`INPUT_libb2=qt`). Therefore
the default pipeline does not build or install a separate native `libb2-host`
archive. It builds `libb2-os2` for OS/2 consumers; the OMF archive, header, and
pkg-config metadata are installed under `/data/os2emx`.

For a direct native build, use host mode and keep the build out of the source
tree. The four upstream tests are registered with CTest; run the test programs
directly in this shell because this environment's installed `ctest` executable
needs a separate Nix glibc runtime path:

```sh
OS2EMX_BUILD_MODE=host nix-shell /data/shell.nix
cmake -S /data/libb2 -B "$OS2EMX_BUILD_ROOT/libb2-native" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=ON
cmake --build "$OS2EMX_BUILD_ROOT/libb2-native" -j2
for test in blake2s-test blake2b-test blake2sp-test blake2bp-test; do
  "$OS2EMX_BUILD_ROOT/libb2-native/$test"
done

```

## OS/2 EMX cross-build

`/data/shell.nix` supplies the generic target compiler, sysroot, OMF archiver,
and build root through `OS2EMX_CC`, `OS2EMX_SYSROOT`, `OS2EMX_AR`, and
`OS2EMX_BUILD_ROOT`. The root pipeline builds `make libb2-os2`, which cross-builds and installs the
OMF target archive, header, and pkg-config file under `/data/os2emx`. QtBase
uses its bundled implementation on both host and target; the target libb2
package remains available to other OS/2 consumers. For a direct rebuild, pass
the project's toolchain file explicitly. The toolchain uses the shell-provided
variables, sets `-Zomf`, and
replaces CMake's
incompatible `qc`/ranlib archive rules with the verified `emxomfar` OMF
commands.

```sh
nix-shell /data/shell.nix
cmake -S /data/libb2 -B "$OS2EMX_BUILD_ROOT/libb2-os2" -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=/data/libb2/cmake/os2emx-toolchain.cmake \
  -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF
cmake --build "$OS2EMX_BUILD_ROOT/libb2-os2" -j2
cmake --install "$OS2EMX_BUILD_ROOT/libb2-os2"
```

Cross-build tests are disabled because the resulting OS/2 executables cannot
run on the Linux build host. Unless explicitly overridden, an OS/2 build uses
`$OS2EMX_PREFIX/` as its install prefix (currently `/data/os2emx/`), so
`cmake --install` writes directly there. To stage instead of installing into
the shared prefix, set `DESTDIR="$OS2EMX_BUILD_ROOT/libb2-os2-stage"` for the
install command. The OS/2 CMake generator installs the OMF archive as
`b2.lib`, plus `blake2.h` and `libb2.pc`; the native Linux build uses
`libb2.a`.

