target("bash-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.bash")
        target:set("toolchain.bash.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross_native.bash.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.bash.bash", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "bin", "bash" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.bash: ", package_info)
            print("toolchain.bash.source_dir: ", target:get("toolchain.bash.source_dir"))
            print("toolchain.cross_native.bash.build_dir: ", target:get("toolchain.cross_native.bash.build_dir"))
            print("toolchain.cross_native.bash.bash: ", target:get("toolchain.cross_native.bash.bash"))
        end
    end)

target("bash-download")
    set_default(false)
    set_kind("phony")
    add_deps("bash-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.bash"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.bash"), toolchain_env:get("toolchain.source_dir"))
    end)

target("bash-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("bash-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local bash_env = project.target("bash-env")
        if os.exists(bash_env:get("toolchain.cross_native.bash.bash")) then 
            print("cross native bash has already built: ", bash_env:get("toolchain.cross_native.bash.bash"))
            return
        end
        local argv = {
            "--prefix=/usr",
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--without-bash-malloc"
        }
        os.vrun("mkdir -p " .. bash_env:get("toolchain.cross_native.bash.build_dir"))
        os.cd(bash_env:get("toolchain.cross_native.bash.build_dir"))
        os.vrunv(path.join(bash_env:get("toolchain.bash.source_dir"), "configure"), argv)
        os.exec("make install -j DESTDIR=" .. toolchain_env:get("toolchain.cross_native.sysroot"))
    end)
