target("jemalloc-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.jemalloc.url", "https://github.com/jemalloc/jemalloc.git")
        target:set("toolchain.jemalloc.branch", "master")
        target:set("toolchain.jemalloc.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "jemalloc"))
        target:set("toolchain.cross.jemalloc.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "jemalloc"))
        target:set("toolchain.cross.jemalloc.build_lib", path.join(target:get("toolchain.cross.jemalloc.build_dir"), "lib", "libjemalloc_pic.a"))
        target:set("toolchain.cross.jemalloc.lib", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "lib", "libjemalloc.a"))
        target:set("toolchain.cross_native.jemalloc.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), "jemalloc"))
        target:set("toolchain.cross_native.jemalloc.build_lib", path.join(target:get("toolchain.cross_native.jemalloc.build_dir"), "lib", "libjemalloc_pic.a"))
        target:set("toolchain.cross_native.jemalloc.lib", path.join(toolchain_env:get("toolchain.cross_native.prefix"), "lib", "libjemalloc.a"))
        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.jemalloc.url: ", target:get("toolchain.jemalloc.url"))
            print("toolchain.jemalloc.branch: ", target:get("toolchain.jemalloc.branch"))
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
        import("devel.git")
        import("core.project.project")
        local jemalloc_env = project.target("jemalloc-env")
        if os.exists(jemalloc_env:get("toolchain.jemalloc.source_dir")) then
            print("jemalloc source code has already existed: ", jemalloc_env:get("toolchain.jemalloc.source_dir"))
            return
        end
        git.clone(jemalloc_env:get("toolchain.jemalloc.url"), {
            depth = 1, 
            branch = jemalloc_env:get("toolchain.jemalloc.branch"), 
            outputdir = jemalloc_env:get("toolchain.jemalloc.source_dir")
        })
        os.cd(jemalloc_env:get("toolchain.jemalloc.source_dir"))
        os.exec("autoconf")
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
    if get_config("Libc") ~= "musl" then
        set_enabled(false)
    end
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local jemalloc_env = project.target("jemalloc-env")
        if os.exists(jemalloc_env:get("toolchain.cross_native.jemalloc.libpic")) then
            print("cross native jemalloc has already built: ", jemalloc_env:get("toolchain.cross_native.jemalloc.libpic"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.prefix"),
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
        os.cp(jemalloc_env:get("toolchain.cross_native.jemalloc.build_lib"), jemalloc_env:get("toolchain.cross_native.jemalloc.lib"))
    end)
