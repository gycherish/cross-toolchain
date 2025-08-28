[中文版](./README-zh.md)

# Cross Toolchain
This project is based on [XMake](https://xmake.io/) for one-click building of cross-compilation toolchains. Please use a recent Linux distribution to build the toolchain with this project.

## Install Dependencies
For example, using [Rocky Linux](https://rockylinux.org/) 8.6, which is also the test environment for this project. After a minimal installation, install the following dependencies:
```bash
sudo dnf install -y gcc gcc-c++ autoconf make bison flex python3 curl wget git tar bzip2 rsync
sudo dnf install -y texinfo --enablerepo=powertools
```

Since this project is built with XMake, you also need to install XMake. Refer to the official XMake documentation for installation instructions. For other Linux distributions, please adjust and install the above packages as needed. In theory, this project can be compiled on other Linux distributions.

## Configuration
The project provides the following configuration options:
- --Libc: Specify the C runtime library to use. Default is musl. For Windows targets, please select mingw. For Linux targets, you can choose musl or glibc.
- --Arch: Specify the supported CPU architecture. Default is x86_64. Currently supports i686, x86_64, aarch64, loongarch64.
- --Vendor: Specify the vendor name, which will be used as the vendor part of the [Target Triplet](https://wiki.osdev.org/Target_Triplet) for the cross toolchain.
- --BuildType: Specify the [build type](https://crosstool-ng.github.io/docs/toolchain-types/). Default is cross. Currently supports native, cross, cross-native.

Ignoring the Vendor configuration, based on the Libc and Arch configuration items, this project supports the following target platforms:
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

Currently, the project uses [GCC](https://gcc.gnu.org/) as the compiler suite and [Binutils](https://www.gnu.org/software/binutils/) as the linker. Support for [LLVM](https://llvm.org/) may be considered in the future.

## Build
To build a toolchain using Musl Libc as the C runtime library, targeting Linux and the X86_64 CPU architecture, use the following commands:
```bash
xmake f --Libc=musl --Arch=x86_64 --BuildType=cross-native
xmake -yvD
```

Assuming the gcc version is 14.2.0, after executing the above commands, the final toolchain will be generated in the project root directory:
- package/cross/x86_64-xmake-linux-musl-gcc14.2.0.tar.gz: Runs on the host platform and can generate binaries for the x86_64-xmake-linux target platform as a cross toolchain.
- package/cross-native/x86_64-xmake-linux-musl-gcc14.2.0.tar.gz: Runs on the x86_64-xmake-linux platform and can generate binaries for the x86_64-xmake-linux target as a native toolchain.

## Usage
Instructions for using XMake as the build system.

### Using the Cross Toolchain
Extract the cross toolchain mentioned above to a specified directory, such as /opt/toolchain/cross/x86_64-xmake-linux-musl-gcc14.2.0, then use the following command to compile your project:
```bash
xmake f -p linux --toolchain=cross --sdk=/opt/toolchain/cross/x86_64-xmake-linux-musl-gcc14.2.0 -yvD
```

### Using the Native Toolchain
Since Musl Libc uses static linking, in theory, the native toolchain mentioned above can be copied to any [Linux](https://wiki.musl-libc.org/supported-platforms) platform with the X86_64 CPU architecture. Assuming its extracted directory is /opt/toolchain/native/x86_64-xmake-linux-musl-gcc14.2.0, simply add it to your PATH environment variable to use it like the system's built-in toolchain:
```bash
export PATH=/opt/toolchain/native/x86_64-xmake-linux-musl-gcc14.2.0/bin:$PATH
```

### Performance Optimization
Since Musl Libc's memory allocator performance is average, this project replaced the memory allocator of Musl Libc with [Jemalloc](https://jemalloc.net/). Users can use Jemalloc without explicitly linking it.
