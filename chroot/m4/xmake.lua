target("m4-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.m4")
        target:set("toolchain.m4.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.m4.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.m4.m4", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "m4" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.m4: ", package_info)
            print("toolchain.m4.source_dir: ", target:get("toolchain.m4.source_dir"))
            print("toolchain.cross_native.m4.build_dir: ", target:get("toolchain.cross_native.m4.build_dir"))
            print("toolchain.cross_native.m4.m4: ", target:get("toolchain.cross_native.m4.m4"))
        end
    end)

target("m4-download")
    set_default(false)
    set_kind("phony")
    add_deps("m4-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.m4"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.m4"), toolchain_env:get("toolchain.source_dir"))
    end)

target("m4-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("m4-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local bash_env = project.target("m4-env")
        if os.exists(bash_env:get("toolchain.cross_native.m4.m4")) then 
            print("cross native m4 has already built: ", bash_env:get("toolchain.cross_native.m4.m4"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target")
        }
        os.vrun("mkdir -p " .. bash_env:get("toolchain.cross_native.m4.build_dir"))
        os.cd(bash_env:get("toolchain.cross_native.m4.build_dir"))
        os.vrunv(path.join(bash_env:get("toolchain.m4.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
