# Cross Toolchain
本项目基于 [XMake](https://xmake.io/) 一键构建交叉编译工具链。

## 背景
本人是一名 C++ 程序员，所在的项目组的 C++ 项目需要能够编译运行在 Windows 和 Linux 平台，其中 Windows 平台最低需要支持到 Windows XP/Windows Server 2003，Linux 平台最低需要支持到 Redhat4，而这些平台自带的工具链版本都非常低，并且升级工具链又几乎不可能完成，所有这些导致了我们的项目必须使用较低的 C++ 标准，这给我们的开发带来了诸多麻烦，例如：无法获得最新的 C++ 标准带来的开发效率、性能等方面的优势。为了解决这个问题，同时也为了自身能随时用上更新的工具链，故而开发了本项目。

## 目标
基于上述背景，本项目的目标如下：
- 能够使用最新的工具链、最新的 C++ 标准开发项目
- 编译的程序能够运行在较低版本的 Windows 和 Linux 平台
- 同时支持多种 CPU 架构

## 现有方案
目前 Windows 官方能够编译生成运行在 Windows XP 的最高版本工具链为 Visual Studio 2017 自带的 v141 工具链，该工具链最高只能支持到 C++14 标准，后续的 Visual Studio 都不再支持 Windows XP，因此基于官方的工具链的方案无法满足需求。好在市面上有基于 GCC 或 LLVM 的 [MinGW-w64](https://www.mingw-w64.org/) 工具链可供使用，具体内容可参考官方文档。

对于 Linux 平台，目前市面上没有现成的方案。

## 项目方案
对于 Windows 平台，也是采用 MinGW-w64 工具链，只不过本项目没有采用官方预编译的二进制，而是将构建 MinGW-w64 交叉工具链和本地工具链的步骤融入项目之中。

对于 Linux 平台，本项目基于 [Musl Libc](https://musl.libc.org/) 构建了一套静态链接的交叉工具链和本地工具链，同时为了提高内存分配的性能，将 [Jemalloc](https://jemalloc.net/) 引入工具链的默认链接项中，上层用户可以无感使用 Jemalloc。

同时，考虑到其他需求，比如想自己构建一个 Linux 发行版，如 [Linux From Scratch](https://www.linuxfromscratch.org/)，对于 Linux 平台，本项目也提供了基于 [Glibc](https://www.gnu.org/software/libc/) 的交叉工具链和本地工具链的构建。


## 使用方法
本项目运行在 Linux 环境，请使用较新的 Linux 发行版来基于本项目构建相应的工具链。

### 安装依赖项
以 [Rocky Linux](https://rockylinux.org/) 8.6 为例，这也是本项目的测试环境，使用最小化安装后需要安装以下依赖项：
```bash
sudo dnf install -y gcc gcc-c++ autoconf make bison flex curl wget git tar rsync
sudo dnf install -y texinfo --enablerepo=powertools
```

由于本项目基于 XMake 构建，还需要安装 XMake，可参考官方文档进行安装。对于其他 Linux 发行版，请根据上述命令自己调整并安装，理论上本项目可以在其他 Linux 发行版上编译。


### 配置
项目提供以下配置项：
- --Libc: 指定使用的 C 运行时库，默认 musl，目标平台是 Windows 平台时请选择 mingw，Linux 平台可以选择 musl 和 glibc
- --Arch：指定支持的 CPU 架构，默认 x86_64，目前支持 i686(x86)、x86_64(x64|amd64)、aarch64、loongarch64
- --Vendor: 指定制造商名称，这个将作为交叉工具链的 [Target Triplet](https://wiki.osdev.org/Target_Triplet) 中的 vendor
- --BuildType: 指定[构建类型](https://crosstool-ng.github.io/docs/toolchain-types/)，默认 cross，目前支持 native、cross、cross-native

目前项目统一使用 [GCC](https://gcc.gnu.org/) 作为编译器套件，[Binutils](https://www.gnu.org/software/binutils/) 作为链接器，后续可能会考虑支持 [LLVM](https://llvm.org/)。

### 构建
以构建使用 Musl Libc 为 C 运行时库，目标平台为 Linux，CPU 架构为 X86_64 为例，构建命令如下：
```bash
xmake f --Libc=musl --Arch=x86_64 --BuildType=cross-native
xmake -yvD
```

以上命令执行完后将在项目根目录下生成最终的工具链：
- package/cross/x86_64-xmake-linux-musl.tar.gz: 运行在宿主平台，能够生成目标平台二进制的交叉工具链
- package/cross-native/x86_64-xmake-linux-musl.tar.gz: 运行在目标平台，能够生成目标平台二进制的本地工具链

### 使用
以使用 XMake 作为构建系统说明使用方法。

#### 使用交叉工具链
将上文的交叉工具链解压到指定目录，如 /opt/toolchain/cross/x86_64-xmake-linux-musl，则可以使用以下命令编译项目代码：
```bash
xmake f -p linux --toolchain=cross --sdk=/opt/toolchain/cross/x86_64-xmake-linux-musl -yvD
```

#### 使用本地工具链
由于 Musl Libc 使用了静态链接，理论上上文中的本地工具链可以拷贝到任何 CPU 架构是 X86_64 的 [Linux](https://wiki.musl-libc.org/supported-platforms) 平台上运行，假设其解压后的目录为 /opt/toolchain/native/x86_64-xmake-linux-musl，则只需要将其加入 PATH 环境变量中即可像使用系统自带的工具链那样去使用了：
```bash
export PATH=/opt/toolchain/native/x86_64-xmake-linux-musl/bin:$PATH
```

