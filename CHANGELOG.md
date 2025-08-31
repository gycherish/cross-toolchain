# Changelog

## [Unreleased]

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
