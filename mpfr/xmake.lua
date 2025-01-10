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
        target:set("toolchain.native.mpfr.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), "mpfr-4.2.1"))
        target:set("toolchain.native.mpfr.prefix", path.join(target:get("toolchain.native.mpfr.build_dir"), "install"))
        target:set("toolchain.native.mpfr.libmpfr", path.join(target:get("toolchain.native.mpfr.prefix"), "lib", "libmpfr.a"))
        target:set("toolchain.cross.mpfr.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "mpfr-4.2.1"))
        target:set("toolchain.cross.mpfr.prefix", path.join(target:get("toolchain.cross.mpfr.build_dir"), "install"))
        target:set("toolchain.cross.mpfr.libmpfr", path.join(target:get("toolchain.cross.mpfr.prefix"), "lib", "libmpfr.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.mpfr.basename: ", target:get("toolchain.mpfr.basename"))
            print("toolchain.mpfr.url: ", target:get("toolchain.mpfr.url"))
            print("toolchain.mpfr.source_dir: ", target:get("toolchain.mpfr.source_dir"))
            print("toolchain.native.mpfr.build_dir: ", target:get("toolchain.native.mpfr.build_dir"))
            print("toolchain.native.mpfr.prefix: ", target:get("toolchain.native.mpfr.prefix"))
            print("toolchain.native.mpfr.libmpfr: ", target:get("toolchain.native.mpfr.libmpfr"))
            print("toolchain.cross.mpfr.build_dir: ", target:get("toolchain.cross.mpfr.build_dir"))
            print("toolchain.cross.mpfr.prefix: ", target:get("toolchain.cross.mpfr.prefix"))
            print("toolchain.cross.mpfr.libmpfr: ", target:get("toolchain.cross.mpfr.libmpfr"))
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
        os.cp(config_env:get("toolchain.config.sub"), mpfr_env:get("toolchain.mpfr.source_dir"))
        os.cp(config_env:get("toolchain.config.guess"), mpfr_env:get("toolchain.mpfr.source_dir"))
    end)

target("mpfr-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("mpfr-download")
    add_deps("gmp-native-build")
    on_build(function (target)
        import("core.project.project")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        if os.exists(mpfr_env:get("toolchain.native.mpfr.libmpfr")) then 
            print("native libmpfr has already built: ", mpfr_env:get("toolchain.native.mpfr.libmpfr"))
            return
        end
        local argv = {
            "--prefix=" .. mpfr_env:get("toolchain.native.mpfr.prefix"),
            "--disable-shared",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix")
        }
        os.vrun("mkdir -p " .. mpfr_env:get("toolchain.native.mpfr.build_dir"))
        os.cd(mpfr_env:get("toolchain.native.mpfr.build_dir"))
        os.vrunv(path.join(mpfr_env:get("toolchain.mpfr.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("mpfr-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("mpfr-download")
    add_deps("gmp-cross-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        if os.exists(mpfr_env:get("toolchain.cross.mpfr.libmpfr")) then 
            print("cross libmpfr has already built: ", mpfr_env:get("toolchain.cross.mpfr.libmpfr"))
            return
        end
        local argv = {
            "--prefix=" .. mpfr_env:get("toolchain.cross.mpfr.prefix"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.cross.gmp.prefix")
        }
        os.vrun("mkdir -p " .. mpfr_env:get("toolchain.cross.mpfr.build_dir"))
        os.cd(mpfr_env:get("toolchain.cross.mpfr.build_dir"))
        os.vrunv(path.join(mpfr_env:get("toolchain.mpfr.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)
