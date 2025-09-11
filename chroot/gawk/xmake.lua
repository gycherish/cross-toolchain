target("gawk-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.gawk")
        target:set("toolchain.gawk.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.gawk.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.gawk.awk", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "awk" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.gawk: ", package_info)
            print("toolchain.gawk.source_dir: ", target:get("toolchain.gawk.source_dir"))
            print("toolchain.cross_native.gawk.build_dir: ", target:get("toolchain.cross_native.gawk.build_dir"))
            print("toolchain.cross_native.gawk.awk: ", target:get("toolchain.cross_native.gawk.awk"))
        end
    end)

target("gawk-download")
    set_default(false)
    set_kind("phony")
    add_deps("gawk-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.gawk"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.gawk"), toolchain_env:get("toolchain.source_dir"))
    end)

target("gawk-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gawk-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        file_env = project.target("gawk-env")
        if os.exists(file_env:get("toolchain.cross_native.gawk.awk")) then 
            print("cross native gawk has already built: ", file_env:get("toolchain.cross_native.gawk.awk"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
        }
        os.vrun("mkdir -p " .. file_env:get("toolchain.cross_native.gawk.build_dir"))
        os.cd(file_env:get("toolchain.cross_native.gawk.build_dir"))
        os.vrunv(path.join(file_env:get("toolchain.gawk.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
