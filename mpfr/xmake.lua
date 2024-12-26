target("mpfr-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.mpfr.basename", "mpfr-4.2.1.tar.gz")
        target:set("toolchain.mpfr.url", "https://www.mpfr.org/mpfr-current/" .. target:get("toolchain.mpfr.basename"))
        target:set("toolchain.mpfr.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "mpfr-4.2.1"))
        target:set("toolchain.cross.mpfr.host.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "mpfr-4.2.1-host"))
        target:set("toolchain.cross.mpfr.host.libmpfr", path.join(toolchain_env:get("toolchain.cross.prefix"), "lib", "libmpfr.a"))
        target:set("toolchain.cross.mpfr.target.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "mpfr-4.2.1-target"))
        target:set("toolchain.cross.mpfr.target.libmpfr", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "lib", "libmpfr.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.mpfr.basename: ", target:get("toolchain.mpfr.basename"))
            print("toolchain.mpfr.url: ", target:get("toolchain.mpfr.url"))
            print("toolchain.mpfr.source_dir: ", target:get("toolchain.mpfr.source_dir"))
            print("toolchain.cross.mpfr.host.build_dir: ", target:get("toolchain.cross.mpfr.host.build_dir"))
            print("toolchain.cross.mpfr.host.libmpfr: ", target:get("toolchain.cross.mpfr.host.libmpfr"))
            print("toolchain.cross.mpfr.target.build_dir: ", target:get("toolchain.cross.mpfr.target.build_dir"))
            print("toolchain.cross.mpfr.target.libmpfr: ", target:get("toolchain.cross.mpfr.target.libmpfr"))
        end
    end)

target("mpfr-download")
    set_default(false)
    set_kind("phony")
    add_deps("mpfr-env")
    add_deps("config-download")
    on_build(function (target)
        import("core.project.project")
        import("net.http")
        import("utils.archive")
        local toolchain_env = project.target("toolchain-env")
        local mpfr_env = project.target("mpfr-env")
        local config_env = project.target("config-env")
        if os.exists(mpfr_env:get("toolchain.mpfr.source_dir")) then
            print("mpfr source code has already existed: ", mpfr_env:get("toolchain.mpfr.source_dir"))
            return
        end
        local output = path.join(toolchain_env:get("toolchain.source_dir"), mpfr_env:get("toolchain.mpfr.basename"))
        http.download(mpfr_env:get("toolchain.mpfr.url"), output)
        archive.extract(output, toolchain_env:get("toolchain.source_dir"))
        os.cp(config_env:get("toolchain.cross.config.sub"), mpfr_env:get("toolchain.mpfr.source_dir"))
        os.cp(config_env:get("toolchain.cross.config.guess"), mpfr_env:get("toolchain.mpfr.source_dir"))
    end)

target("mpfr-cross-host-build")
    set_default(false)
    set_kind("phony")
    add_deps("mpfr-download")
    add_deps("gmp-cross-host-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local mpfr_env = project.target("mpfr-env")
        if os.exists(mpfr_env:get("toolchain.cross.mpfr.host.libmpfr")) then 
            print("host libmpfr has already built: ", mpfr_env:get("toolchain.cross.mpfr.host.libmpfr"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--disable-shared",
            "--with-gmp=" .. toolchain_env:get("toolchain.cross.prefix")
        }
        os.vrun("mkdir -p " .. mpfr_env:get("toolchain.cross.mpfr.host.build_dir"))
        os.cd(mpfr_env:get("toolchain.cross.mpfr.host.build_dir"))
        os.vrunv(path.join(mpfr_env:get("toolchain.mpfr.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("mpfr-cross-target-build")
    set_default(false)
    set_kind("phony")
    add_deps("mpfr-download")
    add_deps("gmp-cross-target-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local mpfr_env = project.target("mpfr-env")
        if os.exists(mpfr_env:get("toolchain.cross.mpfr.target.libmpfr")) then 
            print("target libmpfr has already built: ", mpfr_env:get("toolchain.cross.mpfr.target.libmpfr"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-gmp=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--disable-shared"
        }
        os.vrun("mkdir -p " .. mpfr_env:get("toolchain.cross.mpfr.target.build_dir"))
        os.cd(mpfr_env:get("toolchain.cross.mpfr.target.build_dir"))
        os.vrunv(path.join(mpfr_env:get("toolchain.mpfr.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)
