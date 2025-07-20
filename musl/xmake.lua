target("musl-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.musl")
        target:set("toolchain.musl.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.native.musl.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), package_info.dirname))
        target:set("toolchain.native.musl.libc", path.join(toolchain_env:get("toolchain.native.prefix"), "lib", "libc.a"))
        target:set("toolchain.cross.musl.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname))
        target:set("toolchain.cross.musl.libc", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "lib", "libc.a"))
        target:set("toolchain.cross_native.musl.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.musl.libc", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "lib", "libc.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.musl: ", package_info)
            print("toolchain.musl.source_dir: ", target:get("toolchain.musl.source_dir"))
            print("toolchain.native.musl.build_dir: ", target:get("toolchain.native.musl.build_dir"))
            print("toolchain.native.musl.libc: ", target:get("toolchain.native.musl.libc"))
            print("toolchain.cross.musl.build_dir: ", target:get("toolchain.cross.musl.build_dir"))
            print("toolchain.cross.musl.libc: ", target:get("toolchain.cross.musl.libc"))
            print("toolchain.cross_native.musl.build_dir: ", target:get("toolchain.cross_native.musl.build_dir"))
            print("toolchain.cross_native.musl.libc: ", target:get("toolchain.cross_native.musl.libc"))
        end
    end)

target("musl-download")
    set_default(false)
    set_kind("phony")
    add_deps("musl-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.musl"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.musl"), toolchain_env:get("toolchain.source_dir"))
    end)

target("musl-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("musl-download")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local musl_env = project.target("musl-env")
        if os.exists(musl_env:get("toolchain.native.musl.libc")) then
            print("native musl libc has already built: ", musl_env:get("toolchain.native.musl.libc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.native.prefix"),
            "--disable-shared",
            "CFLAGS=" .. "-fPIC",
        }
        os.vrun("mkdir -p " .. musl_env:get("toolchain.native.musl.build_dir"))
        os.cd(musl_env:get("toolchain.native.musl.build_dir"))
        os.vrunv(path.join(musl_env:get("toolchain.musl.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)

target("musl-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("musl-download")
    add_deps("gcc-cross-bootstrap-build")
    add_deps("linux-cross-header-install")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local musl_env = project.target("musl-env")
        if os.exists(musl_env:get("toolchain.cross.musl.libc")) then
            print("cross musl libc has already built: ", musl_env:get("toolchain.cross.musl.libc"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "CFLAGS=" .. "-fPIC",
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc"),
        }
        os.vrun("mkdir -p " .. musl_env:get("toolchain.cross.musl.build_dir"))
        os.cd(musl_env:get("toolchain.cross.musl.build_dir"))
        os.vrunv(path.join(musl_env:get("toolchain.musl.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)

target("musl-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-cross-final-build")
    add_deps("linux-cross-native-header-install")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local musl_env = project.target("musl-env")
        if os.exists(musl_env:get("toolchain.cross_native.musl.libc")) then
            print("cross native musl libc has already built: ", musl_env:get("toolchain.cross_native.musl.libc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.sysroot.usr"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "CFLAGS=" .. "-fPIC",
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc"),
        }
        os.vrun("mkdir -p " .. musl_env:get("toolchain.cross_native.musl.build_dir"))
        os.cd(musl_env:get("toolchain.cross_native.musl.build_dir"))
        os.vrunv(path.join(musl_env:get("toolchain.musl.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)
