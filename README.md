# libb2

C library providing BLAKE2b, BLAKE2s, BLAKE2bp, and BLAKE2sp. The CMake build
uses the portable reference implementation by default; it does not inherit
host CPU flags or runtime SIMD dispatch when cross-compiling.

## Native build and tests

Build outside the source tree. The four upstream known-answer tests are
registered with CTest. Inside this cross-build shell, run the test programs
directly (the installed `ctest` executable needs the Nix glibc runtime path):

```sh
nix-shell /data/shell.nix --run '
  cmake -S /data/libb2 -B "$OS2EMX_BUILD_ROOT/libb2-native" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=ON
  cmake --build "$OS2EMX_BUILD_ROOT/libb2-native" -j2
  for test in blake2s-test blake2b-test blake2sp-test blake2bp-test; do
    "$OS2EMX_BUILD_ROOT/libb2-native/$test"
  done
'
```

## OS/2 EMX cross-build

`/data/shell.nix` supplies the target compiler, sysroot, OMF archiver, and
build root through `OS2EMX_CC`, `OS2EMX_SYSROOT`, `OS2EMX_AR`, and
`OS2EMX_BUILD_ROOT`. Its current `OS2EMX_CMAKE_TOOLCHAIN_FILE` points to a
missing libolm-specific path, so override that variable with this project's
toolchain file. The file uses the shell-provided environment variables, sets
`-Zomf`, and replaces CMake's incompatible `qc`/`ranlib` archive rules with
the verified `emxomfar` OMF commands.

```sh
nix-shell /data/shell.nix --run '
  export OS2EMX_CMAKE_TOOLCHAIN_FILE=/data/libb2/cmake/os2emx-toolchain.cmake
  cmake -S /data/libb2 -B "$OS2EMX_BUILD_ROOT/libb2-os2" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$OS2EMX_CMAKE_TOOLCHAIN_FILE" \
    -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF
  cmake --build "$OS2EMX_BUILD_ROOT/libb2-os2" -j2
  cmake --install "$OS2EMX_BUILD_ROOT/libb2-os2"
'
```

Cross-build tests are disabled because the resulting OS/2 executables cannot
run on the Linux build host. Unless explicitly overridden, an OS/2 build uses
`$OS2EMX_PREFIX/` as its install prefix (currently `/data/os2emx/`), so
`cmake --install` writes directly there. To stage instead of installing into
the shared prefix, set `DESTDIR="$OS2EMX_BUILD_ROOT/libb2-os2-stage"` for the
install command. The build installs `b2.a`, `blake2.h`, and `libb2.pc`.

The original Autotools files remain available for existing consumers.

Contact: contact@blake2.net
