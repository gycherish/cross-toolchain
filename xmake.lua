set_project("cross-toolchain")
set_xmakever("2.9.3")
set_version("0.1.0")

set_warnings("all", "error")
set_allowedplats("linux")

option("Libc")
    set_default("musl")
    set_showmenu(true)
    set_values("musl", "glibc", "mingw")
    set_description("Set libc type")

option("Arch")
    set_default("x86_64")
    set_showmenu(true)
    set_values("i686", "x86_64", "aarch64", "loongarch64")
    set_description("Set target architecture")

option("Vendor")
    set_default("xmake")
    set_showmenu(true)
    set_description("Set vendor for target triplet")

option("BuildType")
    set_default("cross")
    set_showmenu(true)
    set_values("native", "cross", "cross-native")
    set_description("Set build type for toolchain")

includes("binutils")
includes("config")
includes("gcc")
includes("gdb")
includes("glibc")
includes("gmp")
includes("isl")
includes("jemalloc")
includes("linux")
includes("mingw")
includes("mpc")
includes("mpfr")
includes("musl")

target("check-cfg")
    set_default(true)
    set_kind("phony")
    on_build(function (target)
        local libc = get_config("Libc")
        local arch = get_config("Arch")
        if libc == "mingw" then
            if arch ~= "i686" and arch ~= "x86_64" then
                raise("Invalid arch for mingw: %s", arch)
            end
        end
    end)

target("toolchain-env")
    set_default(false)
    set_kind("phony")
    add_deps("check-cfg")
    on_build(function (target)
        target:set("toolchain.source_dir", "$(projectdir)/source")
        target:set("toolchain.patch_dir", "$(projectdir)/patches")
        target:set("toolchain.exe.suffix", "")
        if get_config("Libc") == "musl" then
            target:set("toolchain.cross.target", "$(Arch)-$(Vendor)-linux-musl")
        elseif get_config("Libc") == "mingw" then
            target:set("toolchain.cross.target", "$(Arch)-w64-mingw32")
            target:set("toolchain.exe.suffix", ".exe")
        else
            target:set("toolchain.cross.target", "$(Arch)-$(Vendor)-linux-gnu")
        end
        target:set("toolchain.native.out_dir", "$(projectdir)/out/native")
        target:set("toolchain.native.prefix", path.join(target:get("toolchain.native.out_dir"), "install"))
        target:set("toolchain.native.build_dir", path.join(target:get("toolchain.native.out_dir"), "build"))
        target:set("toolchain.cross.package_dir", "$(projectdir)/package/cross")
        target:set("toolchain.cross.out_dir", "$(projectdir)/out/cross")
        target:set("toolchain.cross.prefix", path.join(target:get("toolchain.cross.out_dir"), target:get("toolchain.cross.target")))
        target:set("toolchain.cross.build_dir", target:get("toolchain.cross.prefix") .. "-build")
        target:set("toolchain.cross_native.package_dir", "$(projectdir)/package/cross-native")
        target:set("toolchain.cross_native.out_dir", "$(projectdir)/out/cross-native")
        target:set("toolchain.cross_native.prefix", path.join(target:get("toolchain.cross_native.out_dir"), target:get("toolchain.cross.target")))
        target:set("toolchain.cross_native.build_dir", target:get("toolchain.cross_native.prefix") .. "-build")

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source_dir: ", target:get("toolchain.source_dir"))
            print("toolchain.patch_dir: ", target:get("toolchain.patch_dir"))
            print("toolchain.native.out_dir: ", target:get("toolchain.native.out_dir"))
            print("toolchain.native.prefix: ", target:get("toolchain.native.prefix"))
            print("toolchain.native.build_dir: ", target:get("toolchain.native.build_dir"))
            print("toolchain.exe.suffix: ", target:get("toolchain.exe.suffix"))
            print("toolchain.cross.package_dir: ", target:get("toolchain.cross.package_dir"))
            print("toolchain.cross.out_dir: ", target:get("toolchain.cross.out_dir"))
            print("toolchain.cross.prefix: ", target:get("toolchain.cross.prefix"))
            print("toolchain.cross.build_dir: ", target:get("toolchain.cross.build_dir"))
            print("toolchain.cross.target: ", target:get("toolchain.cross.target"))
            print("toolchain.cross_native.package_dir: ", target:get("toolchain.cross_native.package_dir"))
            print("toolchain.cross_native.out_dir: ", target:get("toolchain.cross_native.out_dir"))
            print("toolchain.cross_native.prefix: ", target:get("toolchain.cross_native.prefix"))
            print("toolchain.cross_native.build_dir: ", target:get("toolchain.cross_native.build_dir"))
        end
    end)

target("show-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    add_deps("binutils-env")
    add_deps("config-env")
    add_deps("gcc-env")
    add_deps("glibc-env")
    add_deps("gmp-env")
    add_deps("isl-env")
    add_deps("jemalloc-env")
    add_deps("linux-env")
    add_deps("mingw-env")
    add_deps("mpc-env")
    add_deps("mpfr-env")
    add_deps("musl-env")
    on_build(function (target) 
    end)

target("native-toolchain")
    set_kind("phony")
    add_deps("binutils-native-build")
    add_deps("gcc-native-build")
    if get_config("BuildType") ~= "native" then
        set_enabled(false)
    end

target("cross-toolchain")
    set_kind("phony")
    add_deps("gcc-cross-package")
    if get_config("BuildType") ~= "cross" then
        set_enabled(false)
    end

target("cross-native-toolchain")
    set_kind("phony")
    add_deps("gcc-cross-native-package")
    if get_config("BuildType") ~= "cross-native" then
        set_enabled(false)
    end
