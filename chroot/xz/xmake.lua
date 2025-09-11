target("xz-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.xz")
        target:set("toolchain.xz.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.xz.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.xz.xz", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "xz" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.xz: ", package_info)
            print("toolchain.xz.source_dir: ", target:get("toolchain.xz.source_dir"))
            print("toolchain.cross_native.xz.build_dir: ", target:get("toolchain.cross_native.xz.build_dir"))
            print("toolchain.cross_native.xz.xz: ", target:get("toolchain.cross_native.xz.xz"))
        end
    end)

target("xz-download")
    set_default(false)
    set_kind("phony")
    add_deps("xz-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.xz"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.xz"), toolchain_env:get("toolchain.source_dir"))
    end)

target("xz-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("xz-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("xz-env")
        if os.exists(file_env:get("toolchain.cross_native.xz.xz")) then 
            print("cross native xz has already built: ", file_env:get("toolchain.cross_native.xz.xz"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "--enable-static"
        }
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.xz.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.xz.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.xz.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
