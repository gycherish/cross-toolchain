# Cross Toolchain
本项目基于 [XMake](https://xmake.io/) 一键构建交叉编译工具链。请使用较新的 Linux 发行版来基于本项目构建相应的工具链。

## 安装依赖
以 [Rocky Linux](https://rockylinux.org/) 8.6 为例，这也是本项目的测试环境，使用最小化安装后需要安装以下依赖项：
```bash
sudo dnf install -y gcc gcc-c++ autoconf make bison flex python3 curl wget git tar bzip2 rsync
sudo dnf install -y texinfo --enablerepo=powertools
```

由于本项目基于 XMake 构建，还需要安装 XMake，可参考 XMake 官方文档进行安装。对于其他 Linux 发行版，请根据上述命令自己调整并安装，理论上本项目可以在其他 Linux 发行版上编译。

## 配置
项目提供以下配置项：
- --Libc: 指定使用的 C 运行时库，默认 musl，目标平台是 Windows 平台时请选择 mingw，Linux 平台可以选择 musl 和 glibc
- --Arch：指定支持的 CPU 架构，默认 x86_64，目前支持 i686、x86_64、aarch64、loongarch64
- --Vendor: 指定制造商名称，这个将作为交叉工具链的 [Target Triplet](https://wiki.osdev.org/Target_Triplet) 中的 vendor，默认 xmake
- --BuildType: 指定[构建类型](https://crosstool-ng.github.io/docs/toolchain-types/)，默认 cross，目前支持 native、cross、cross-native

忽略 Vendor 配置，根据 Libc 和 Arch 配置项，本项目支持以下目标平台：
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

目前项目统一使用 [GCC](https://gcc.gnu.org/) 作为编译器套件，[Binutils](https://www.gnu.org/software/binutils/) 作为链接器，后续可能会考虑支持 [LLVM](https://llvm.org/)。

## 构建
以构建使用 Musl Libc 为 C 运行时库，目标平台为 Linux，CPU 架构为 X86_64 为例，构建命令如下：
```bash
xmake f --Libc=musl --Arch=x86_64 --BuildType=cross-native
xmake -yvD
```

假设使用的 gcc 版本为 15.2.0，则以上命令执行完后将在项目根目录下生成最终的工具链：
- package/cross/x86_64-xmake-linux-musl-gcc15.2.0.tar.gz: 运行在宿主平台，能够生成目标平台为 x86_64-xmake-linux 的二进制的交叉工具链
- package/cross-native/x86_64-xmake-linux-musl-gcc15.2.0.tar.gz: 运行在 x86_64-xmake-linux 平台，能够生成目标平台为 x86_64-xmake-linux 二进制的本地工具链

## 使用
以使用 XMake 作为构建系统说明使用方法。

### 使用交叉工具链
将上文的交叉工具链解压到指定目录，如 /opt/toolchain/cross/x86_64-xmake-linux-musl-gcc15.2.0，则可以使用以下命令编译项目代码：
```bash
xmake f -p linux --toolchain=cross --sdk=/opt/toolchain/cross/x86_64-xmake-linux-musl-gcc15.2.0 -yvD
```

### 使用本地工具链
由于 Musl Libc 使用了静态链接，理论上上文中的本地工具链可以拷贝到任何 CPU 架构是 X86_64 的 [Linux](https://wiki.musl-libc.org/supported-platforms) 平台上运行，假设其解压后的目录为 /opt/toolchain/native/x86_64-xmake-linux-musl-gcc15.2.0，则只需要将其加入 PATH 环境变量中即可像使用系统自带的工具链那样去使用了：
```bash
export PATH=/opt/toolchain/native/x86_64-xmake-linux-musl-gcc15.2.0/bin:$PATH
```

### 性能优化
由于 Musl Libc 的内存分配器的性能一般，本项目使用 [Jemalloc](https://jemalloc.net/) 替换掉了 Musl Libc 的内存分配器，上层用户无需显式链接 Jemalloc 便可无感使用 Jemalloc。
