target("musl-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.musl.url", "https://github.com/kraj/musl.git")
        target:set("toolchain.musl.branch", "v1.2.5")
        target:set("toolchain.musl.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "musl-1.2.5"))
        target:set("toolchain.musl.build_dir", path.join(toolchain_env:get("toolchain.build_dir"), "musl-1.2.5"))
        target:set("toolchain.musl.libc", path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target"), "lib", "libc.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.musl.url: ", target:get("toolchain.musl.url"))
            print("toolchain.musl.branch: ", target:get("toolchain.musl.branch"))
            print("toolchain.musl.source_dir: ", target:get("toolchain.musl.source_dir"))
            print("toolchain.musl.build_dir: ", target:get("toolchain.musl.build_dir"))
            print("toolchain.musl.libc: ", target:get("toolchain.musl.libc"))
        end
    end)

target("musl-download")
    set_default(false)
    set_kind("phony")
    add_deps("musl-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local musl_env = project.target("musl-env")
        if os.exists(musl_env:get("toolchain.musl.source_dir")) then
            print("musl libc source code has already existed: ", musl_env:get("toolchain.musl.source_dir"))
            return
        end
        git.clone(musl_env:get("toolchain.musl.url"), {
            depth = 1, 
            branch = musl_env:get("toolchain.musl.branch"), 
            outputdir = musl_env:get("toolchain.musl.source_dir")
        })
    end)

target("musl-build")
    set_default(false)
    set_kind("phony")
    add_deps("musl-download")
    add_deps("gcc-bootstrap-build")
    add_deps("linux-header-install")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local musl_env = project.target("musl-env")
        if os.exists(musl_env:get("toolchain.musl.libc")) then
            print("musl libc has already built: ", musl_env:get("toolchain.musl.libc"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target")),
            "--host=" .. toolchain_env:get("toolchain.target"),
            "--disable-shared",
            "CFLAGS=" .. "-fPIC",
            "CC=" .. gcc_env:get("toolchain.gcc.cc"),
        }
        os.vrun("mkdir -p " .. musl_env:get("toolchain.musl.build_dir"))
        os.cd(musl_env:get("toolchain.musl.build_dir"))
        os.vrunv(path.join(musl_env:get("toolchain.musl.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)
