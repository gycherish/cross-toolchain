target("patch-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.patch")
        target:set("toolchain.patch.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.patch.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.patch.patch", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "patch" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.patch: ", package_info)
            print("toolchain.patch.source_dir: ", target:get("toolchain.patch.source_dir"))
            print("toolchain.cross_native.patch.build_dir: ", target:get("toolchain.cross_native.patch.build_dir"))
            print("toolchain.cross_native.patch.patch: ", target:get("toolchain.cross_native.patch.patch"))
        end
    end)

target("patch-download")
    set_default(false)
    set_kind("phony")
    add_deps("patch-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.patch"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.patch"), toolchain_env:get("toolchain.source_dir"))
    end)

target("patch-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("patch-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("patch-env")
        if os.exists(file_env:get("toolchain.cross_native.patch.patch")) then 
            print("cross native patch has already built: ", file_env:get("toolchain.cross_native.patch.patch"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
        }
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.patch.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.patch.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.patch.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
