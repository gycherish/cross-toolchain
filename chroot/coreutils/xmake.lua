target("coreutils-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.coreutils")
        target:set("toolchain.coreutils.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.coreutils.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.coreutils.ls", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "ls" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.coreutils: ", package_info)
            print("toolchain.coreutils.source_dir: ", target:get("toolchain.coreutils.source_dir"))
            print("toolchain.cross_native.coreutils.build_dir: ", target:get("toolchain.cross_native.coreutils.build_dir"))
            print("toolchain.cross_native.coreutils.ls: ", target:get("toolchain.cross_native.coreutils.ls"))
        end
    end)

target("coreutils-download")
    set_default(false)
    set_kind("phony")
    add_deps("coreutils-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.coreutils"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.coreutils"), toolchain_env:get("toolchain.source_dir"))
    end)

target("coreutils-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("coreutils-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local coreutils_env = project.target("coreutils-env")
        if os.exists(coreutils_env:get("toolchain.cross_native.coreutils.ls")) then 
            print("cross native coreutils has already built: ", coreutils_env:get("toolchain.cross_native.coreutils.ls"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target")
        }
        os.setenv("FORCE_UNSAFE_CONFIGURE", "1")
        os.vrun("mkdir -p " .. coreutils_env:get("toolchain.cross_native.coreutils.build_dir"))
        os.cd(coreutils_env:get("toolchain.cross_native.coreutils.build_dir"))
        os.vrunv(path.join(coreutils_env:get("toolchain.coreutils.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
