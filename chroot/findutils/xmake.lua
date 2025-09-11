target("findutils-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.findutils")
        target:set("toolchain.findutils.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.findutils.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.findutils.find", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "find" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.findutils: ", package_info)
            print("toolchain.findutils.source_dir: ", target:get("toolchain.findutils.source_dir"))
            print("toolchain.cross_native.findutils.build_dir: ", target:get("toolchain.cross_native.findutils.build_dir"))
            print("toolchain.cross_native.findutils.find: ", target:get("toolchain.cross_native.findutils.find"))
        end
    end)

target("findutils-download")
    set_default(false)
    set_kind("phony")
    add_deps("findutils-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.findutils"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.findutils"), toolchain_env:get("toolchain.source_dir"))
    end)

target("findutils-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("findutils-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("findutils-env")
        if os.exists(file_env:get("toolchain.cross_native.findutils.find")) then 
            print("cross native findutils has already built: ", file_env:get("toolchain.cross_native.findutils.find"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
        }
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.findutils.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.findutils.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.findutils.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
