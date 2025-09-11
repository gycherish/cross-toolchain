target("diffutils-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.diffutils")
        target:set("toolchain.diffutils.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.diffutils.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.diffutils.diff", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "diff" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.diffutils: ", package_info)
            print("toolchain.diffutils.source_dir: ", target:get("toolchain.diffutils.source_dir"))
            print("toolchain.cross_native.diffutils.build_dir: ", target:get("toolchain.cross_native.diffutils.build_dir"))
            print("toolchain.cross_native.diffutils.diff: ", target:get("toolchain.cross_native.diffutils.diff"))
        end
    end)

target("diffutils-download")
    set_default(false)
    set_kind("phony")
    add_deps("diffutils-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.diffutils"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.diffutils"), toolchain_env:get("toolchain.source_dir"))
    end)

target("diffutils-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("diffutils-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local diffutils_env = project.target("diffutils-env")
        if os.exists(diffutils_env:get("toolchain.cross_native.diffutils.diff")) then 
            print("cross native diffutils has already built: ", diffutils_env:get("toolchain.cross_native.diffutils.diff"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target")
        }
        os.vrun("mkdir -p " .. diffutils_env:get("toolchain.cross_native.diffutils.build_dir"))
        os.cd(diffutils_env:get("toolchain.cross_native.diffutils.build_dir"))
        os.vrunv(path.join(diffutils_env:get("toolchain.diffutils.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
