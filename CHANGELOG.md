# Changelog

## [Unreleased]

## [v0.2.0] - 2026-10-14

### Changed

- Update gcc to 16.2.0, binutils to 2.47, gdb to 18.1, mingw-w64 to 14.0.0, glibc to 2.44, musl to 1.2.6, linux headers to 7.2.10, mpfr to 4.2.2, isl to 0.28, gettext to 1.0, jemalloc to 5.4.0 (instead of master)
- Use the release tarballs of gcc, binutils, mingw-w64 and jemalloc instead of git checkouts: they carry the generated autotools files, so nothing has to be regenerated on the build machine
- Build gdb from its own release tarball, for the native and cross native toolchains too, rather than from the binutils tree, whose gdb is an unreleased snapshot, and strip it on install
- Limit `make` to the number of CPUs instead of unlimited parallel jobs

### Fixed

- i686 MinGW: link executables large address aware by default, so `cc1plus.exe` of the cross native toolchain no longer runs out of memory at 2 GB
- i686 MinGW: make `max_align_t` and the default `operator new` alignment 8 bytes, matching what `malloc` guarantees on 32-bit Windows (msvcrt and ucrt alike), instead of depending on which `stddef.h` is included first
- Patches of a source tree without its own `.git` were silently skipped by `git apply`; such trees are now patched with `patch`, which fails loudly
- gmp 6.3.0 failed to configure with gcc 15 or later, whose default is C23
- jemalloc looked for its `configure` in the wrong directory

### Removed

- Patches for binutils and gdb that are part of the new releases

## [v0.1.0] - 2025-08-31

### Added

First release version to supported these targets:

- i686-w64-mingw
- i686-linux-gnu
- i686-linux-musl
- x86_64-w64-mingw
- x86_64-linux-gnu
- x86_64-linux-musl
- aarch64-linux-gnu
- aarch64-linux-musl
- loongarch64-linux-gnu
- loongarch64-linux-musl

### Fixed

- Fix bad iscsidsc.h in Mingw
- Fix libstdc++ does not support the -fPIC compile option
- Disable gprofng for Musl to fix build error
