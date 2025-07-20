target("jemalloc-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.jemalloc")
        target:set("toolchain.jemalloc.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross.jemalloc.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname))
        target:set("toolchain.cross.jemalloc.build_lib", path.join(target:get("toolchain.cross.jemalloc.build_dir"), "lib", "libjemalloc_pic.a"))
        target:set("toolchain.cross.jemalloc.lib", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "lib", "libjemalloc.a"))
        target:set("toolchain.cross_native.jemalloc.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.jemalloc.build_lib", path.join(target:get("toolchain.cross_native.jemalloc.build_dir"), "lib", "libjemalloc_pic.a"))
        target:set("toolchain.cross_native.jemalloc.lib", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "lib", "libjemalloc.a"))
        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.jemalloc: ", package_info)
            print("toolchain.jemalloc.source_dir: ", target:get("toolchain.jemalloc.source_dir"))
            print("toolchain.cross.jemalloc.build_dir: ", target:get("toolchain.cross.jemalloc.build_dir"))
            print("toolchain.cross.jemalloc.build_lib: ", target:get("toolchain.cross.jemalloc.build_lib"))
            print("toolchain.cross.jemalloc.lib: ", target:get("toolchain.cross.jemalloc.lib"))
            print("toolchain.cross_native.jemalloc.build_dir: ", target:get("toolchain.cross_native.jemalloc.build_dir"))
            print("toolchain.cross_native.jemalloc.build_lib: ", target:get("toolchain.cross_native.jemalloc.build_lib"))
            print("toolchain.cross_native.jemalloc.lib: ", target:get("toolchain.cross_native.jemalloc.lib"))
        end
    end)

target("jemalloc-download")
    set_default(false)
    set_kind("phony")
    add_deps("jemalloc-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local jemalloc_env = project.target("jemalloc-env")
        package.download(package_env:get("toolchain.source.jemalloc"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.jemalloc"), toolchain_env:get("toolchain.source_dir"))
        local configure_file = path.join(toolchain_env:get("toolchain.source_dir"), "configure")
        if not os.exists(configure_file) then
            os.cd(jemalloc_env:get("toolchain.jemalloc.source_dir"))
            os.exec("autoconf")
        end
    end)

target("jemalloc-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("jemalloc-download")
    add_deps("gcc-cross-bootstrap-build")
    add_deps("linux-cross-header-install")
    add_deps("musl-cross-build")
    if get_config("Libc") ~= "musl" then
        set_enabled(false)
    end
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local jemalloc_env = project.target("jemalloc-env")
        if os.exists(jemalloc_env:get("toolchain.cross.jemalloc.lib")) then
            print("cross jemalloc has already installed: ", jemalloc_env:get("toolchain.cross.jemalloc.lib"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--enable-static",
            "--disable-shared",
            "--disable-cxx",
            -- "CFLAGS=" .. "-fPIC", -- jemalloc will add -fPIC automatically
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc"),
        }
        os.vrun("mkdir -p " .. jemalloc_env:get("toolchain.cross.jemalloc.build_dir"))
        os.cd(jemalloc_env:get("toolchain.cross.jemalloc.build_dir"))
        os.vrunv(path.join(jemalloc_env:get("toolchain.jemalloc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec(gcc_env:get("toolchain.cross.gcc.strip") .. " --strip-debug " .. jemalloc_env:get("toolchain.cross.jemalloc.build_lib"))
        os.exec(gcc_env:get("toolchain.cross.gcc.ranlib") .. " " .. jemalloc_env:get("toolchain.cross.jemalloc.build_lib"))
        os.cp(jemalloc_env:get("toolchain.cross.jemalloc.build_lib"), jemalloc_env:get("toolchain.cross.jemalloc.lib"))
    end)

target("jemalloc-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-cross-final-build")
    add_deps("linux-cross-native-header-install")
    add_deps("musl-cross-native-build")
    if get_config("Libc") ~= "musl" then
        set_enabled(false)
    end
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local jemalloc_env = project.target("jemalloc-env")
        if os.exists(jemalloc_env:get("toolchain.cross_native.jemalloc.lib")) then
            print("cross native jemalloc has already built: ", jemalloc_env:get("toolchain.cross_native.jemalloc.lib"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.sysroot.usr"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--enable-static",
            "--disable-shared",
            "--disable-cxx",
            -- "CFLAGS=" .. "-fPIC", -- jemalloc will add -fPIC automatically
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc"),
        }
        os.vrun("mkdir -p " .. jemalloc_env:get("toolchain.cross_native.jemalloc.build_dir"))
        os.cd(jemalloc_env:get("toolchain.cross_native.jemalloc.build_dir"))
        os.vrunv(path.join(jemalloc_env:get("toolchain.jemalloc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec(gcc_env:get("toolchain.cross.gcc.strip") .. " --strip-debug " .. jemalloc_env:get("toolchain.cross_native.jemalloc.build_lib"))
        os.exec(gcc_env:get("toolchain.cross.gcc.ranlib") .. " " .. jemalloc_env:get("toolchain.cross_native.jemalloc.build_lib"))
        os.cp(jemalloc_env:get("toolchain.cross_native.jemalloc.build_lib"), jemalloc_env:get("toolchain.cross_native.jemalloc.lib"))
    end)
