target("grep-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.grep")
        target:set("toolchain.grep.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.grep.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.grep.grep", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "grep" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.grep: ", package_info)
            print("toolchain.grep.source_dir: ", target:get("toolchain.grep.source_dir"))
            print("toolchain.cross_native.grep.build_dir: ", target:get("toolchain.cross_native.grep.build_dir"))
            print("toolchain.cross_native.grep.grep: ", target:get("toolchain.cross_native.grep.grep"))
        end
    end)

target("grep-download")
    set_default(false)
    set_kind("phony")
    add_deps("grep-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.grep"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.grep"), toolchain_env:get("toolchain.source_dir"))
    end)

target("grep-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("grep-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("grep-env")
        if os.exists(file_env:get("toolchain.cross_native.grep.grep")) then 
            print("cross native grep has already built: ", file_env:get("toolchain.cross_native.grep.grep"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
        }
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.grep.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.grep.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.grep.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
