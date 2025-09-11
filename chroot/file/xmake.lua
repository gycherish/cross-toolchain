target("file-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.file")
        target:set("toolchain.file.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.file.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.file.file", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "file" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.file: ", package_info)
            print("toolchain.file.source_dir: ", target:get("toolchain.file.source_dir"))
            print("toolchain.cross_native.file.build_dir: ", target:get("toolchain.cross_native.file.build_dir"))
            print("toolchain.cross_native.file.file: ", target:get("toolchain.cross_native.file.file"))
        end
    end)

target("file-download")
    set_default(false)
    set_kind("phony")
    add_deps("file-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.file"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.file"), toolchain_env:get("toolchain.source_dir"))
    end)

target("file-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("file-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("file-env")
        if os.exists(file_env:get("toolchain.cross_native.file.file")) then 
            print("cross native file has already built: ", file_env:get("toolchain.cross_native.file.file"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--enable-static",
            "--disable-shared",
        }
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.file.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.file.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.file.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
