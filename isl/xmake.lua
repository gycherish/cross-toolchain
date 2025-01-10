target("isl-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.isl.basename", "isl-0.27.tar.gz")
        target:set("toolchain.isl.url", "https://libisl.sourceforge.io/" .. target:get("toolchain.isl.basename"))
        target:set("toolchain.isl.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "isl-0.27"))
        target:set("toolchain.native.isl.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), "isl-0.27"))
        target:set("toolchain.native.isl.prefix", path.join(target:get("toolchain.native.isl.build_dir"), "install"))
        target:set("toolchain.native.isl.libisl", path.join(target:get("toolchain.native.isl.prefix"), "lib", "libisl.a"))
        target:set("toolchain.cross.isl.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "isl-0.27"))
        target:set("toolchain.cross.isl.prefix", path.join(target:get("toolchain.cross.isl.build_dir"), "install"))
        target:set("toolchain.cross.isl.libisl", path.join(target:get("toolchain.cross.isl.prefix"), "lib", "libisl.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.isl.basename: ", target:get("toolchain.isl.basename"))
            print("toolchain.isl.url: ", target:get("toolchain.isl.url"))
            print("toolchain.isl.source_dir: ", target:get("toolchain.isl.source_dir"))
            print("toolchain.native.isl.build_dir: ", target:get("toolchain.native.isl.build_dir"))
            print("toolchain.native.isl.prefix: ", target:get("toolchain.native.isl.prefix"))
            print("toolchain.native.isl.libisl: ", target:get("toolchain.native.isl.libisl"))
            print("toolchain.cross.isl.build_dir: ", target:get("toolchain.cross.isl.build_dir"))
            print("toolchain.cross.isl.prefix: ", target:get("toolchain.cross.isl.prefix"))
            print("toolchain.cross.isl.libisl: ", target:get("toolchain.cross.isl.libisl"))
        end
    end)

target("isl-download")
    set_default(false)
    set_kind("phony")
    add_deps("isl-env")
    add_deps("config-download")
    on_build(function (target)
        import("core.project.project")
        import("net.http")
        import("utils.archive")
        local toolchain_env = project.target("toolchain-env")
        local isl_env = project.target("isl-env")
        local config_env = project.target("config-env")
        if os.exists(isl_env:get("toolchain.isl.source_dir")) then
            print("isl source code has already existed: ", isl_env:get("toolchain.isl.source_dir"))
            return
        end
        local output = path.join(toolchain_env:get("toolchain.source_dir"), isl_env:get("toolchain.isl.basename"))
        http.download(isl_env:get("toolchain.isl.url"), output)
        archive.extract(output, toolchain_env:get("toolchain.source_dir"))
        os.cp(config_env:get("toolchain.config.sub"), isl_env:get("toolchain.isl.source_dir"))
        os.cp(config_env:get("toolchain.config.guess"), isl_env:get("toolchain.isl.source_dir"))
    end)

target("isl-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("isl-download")
    add_deps("gmp-native-build")
    on_build(function (target)
        import("core.project.project")
        local gmp_env = project.target("gmp-env")
        local isl_env = project.target("isl-env")
        if os.exists(isl_env:get("toolchain.native.isl.libisl")) then 
            print("native libisl has already built: ", isl_env:get("toolchain.native.isl.libisl"))
            return
        end
        local argv = {
            "--prefix=" .. isl_env:get("toolchain.native.isl.prefix"),
            "--disable-shared",
            "--with-pic",
            "--with-gmp-prefix=" .. gmp_env:get("toolchain.native.gmp.prefix")
        }
        os.vrun("mkdir -p " .. isl_env:get("toolchain.native.isl.build_dir"))
        os.cd(isl_env:get("toolchain.native.isl.build_dir"))
        os.vrunv(path.join(isl_env:get("toolchain.isl.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("isl-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("isl-download")
    add_deps("gmp-cross-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local isl_env = project.target("isl-env")
        if os.exists(isl_env:get("toolchain.cross.isl.libisl")) then 
            print("cross libisl has already built: ", isl_env:get("toolchain.cross.isl.libisl"))
            return
        end
        local argv = {
            "--prefix=" .. isl_env:get("toolchain.cross.isl.prefix"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "--with-pic",
            "--with-gmp-prefix=" .. gmp_env:get("toolchain.cross.gmp.prefix")
        }
        os.vrun("mkdir -p " .. isl_env:get("toolchain.cross.isl.build_dir"))
        os.cd(isl_env:get("toolchain.cross.isl.build_dir"))
        os.vrunv(path.join(isl_env:get("toolchain.isl.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)
