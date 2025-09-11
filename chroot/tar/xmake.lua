target("tar-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.tar")
        target:set("toolchain.tar.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.tar.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.tar.tar", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "tar" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.tar: ", package_info)
            print("toolchain.tar.source_dir: ", target:get("toolchain.tar.source_dir"))
            print("toolchain.cross_native.tar.build_dir: ", target:get("toolchain.cross_native.tar.build_dir"))
            print("toolchain.cross_native.tar.tar: ", target:get("toolchain.cross_native.tar.tar"))
        end
    end)

target("tar-download")
    set_default(false)
    set_kind("phony")
    add_deps("tar-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.tar"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.tar"), toolchain_env:get("toolchain.source_dir"))
    end)

target("tar-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("tar-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("tar-env")
        if os.exists(file_env:get("toolchain.cross_native.tar.tar")) then 
            print("cross native tar has already built: ", file_env:get("toolchain.cross_native.tar.tar"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
        }
        os.setenv("FORCE_UNSAFE_CONFIGURE", "1")
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.tar.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.tar.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.tar.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
