set_project("cross-toolchain")
set_xmakever("2.9.3")
set_version("0.1.0")

set_warnings("all", "error")
set_allowedplats("linux")

option("Libc")
    set_default("musl")
    set_showmenu(true)
    set_values("musl", "glibc")
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

includes("binutils")
includes("config")
includes("gcc")
includes("gdb")
includes("glibc")
includes("gmp")
includes("linux")
includes("mpfr")
includes("musl")

target("toolchain-env")
    set_default(false)
    set_kind("phony")
    on_build(function (target)
        target:set("toolchain.source_dir", "$(projectdir)/source")
        target:set("toolchain.package_dir", "$(projectdir)/package")
        target:set("toolchain.out_dir", "$(projectdir)/out")
        if get_config("Libc") == "musl" then
            target:set("toolchain.target", "$(Arch)-$(Vendor)-linux-musl")
        else
            target:set("toolchain.target", "$(Arch)-$(Vendor)-linux-gnu")
        end
        target:set("toolchain.prefix", path.join(target:get("toolchain.out_dir"), target:get("toolchain.target")))
        target:set("toolchain.build_dir", target:get("toolchain.prefix") .. "-build")
        target:set("toolchain.patch_dir", "$(projectdir)/patches")

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source_dir: ", target:get("toolchain.source_dir"))
            print("toolchain.package_dir: ", target:get("toolchain.package_dir"))
            print("toolchain.build_dir: ", target:get("toolchain.build_dir"))
            print("toolchain.out_dir: ", target:get("toolchain.out_dir"))
            print("toolchain.target: ", target:get("toolchain.target"))
            print("toolchain.prefix: ", target:get("toolchain.prefix"))
            print("toolchain.patch_dir: ", target:get("toolchain.patch_dir"))
        end
    end)

target("toolchain")
    set_default(true)
    set_kind("phony")
    add_deps("gcc-package")
