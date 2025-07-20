target("gmp-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.gmp")
        target:set("toolchain.gmp.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.native.gmp.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), package_info.dirname))
        target:set("toolchain.native.gmp.prefix", path.join(target:get("toolchain.native.gmp.build_dir"), "install"))
        target:set("toolchain.native.gmp.libgmp", path.join(target:get("toolchain.native.gmp.prefix"), "lib", "libgmp.a"))
        target:set("toolchain.cross.gmp.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname))
        target:set("toolchain.cross.gmp.prefix", path.join(target:get("toolchain.cross.gmp.build_dir"), "install"))
        target:set("toolchain.cross.gmp.libgmp", path.join(target:get("toolchain.cross.gmp.prefix"), "lib", "libgmp.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.gmp: ", package_info)
            print("toolchain.gmp.source_dir: ", target:get("toolchain.gmp.source_dir"))
            print("toolchain.native.gmp.build_dir: ", target:get("toolchain.native.gmp.build_dir"))
            print("toolchain.native.gmp.prefix: ", target:get("toolchain.native.gmp.prefix"))
            print("toolchain.native.gmp.libgmp: ", target:get("toolchain.native.gmp.libgmp"))
            print("toolchain.cross.gmp.build_dir: ", target:get("toolchain.cross.gmp.build_dir"))
            print("toolchain.cross.gmp.prefix: ", target:get("toolchain.cross.gmp.prefix"))
            print("toolchain.cross.gmp.libgmp: ", target:get("toolchain.cross.gmp.libgmp"))
        end
    end)

target("gmp-download")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-env")
    add_deps("config-download")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local config_env = project.target("config-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.gmp"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.gmp"), toolchain_env:get("toolchain.source_dir"))
        package.copy(function () 
            os.cp(config_env:get("toolchain.config.sub"), path.join(gmp_env:get("toolchain.gmp.source_dir"), "configfsf.sub"))
            os.cp(config_env:get("toolchain.config.guess"), path.join(gmp_env:get("toolchain.gmp.source_dir"), "configfsf.guess"))
            end,
            gmp_env:get("toolchain.gmp.source_dir")
        )
    end)

target("gmp-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-download")
    on_build(function (target)
        import("core.project.project")
        local gmp_env = project.target("gmp-env")
        if os.exists(gmp_env:get("toolchain.native.gmp.libgmp")) then 
            print("native libgmp has already built: ", gmp_env:get("toolchain.native.gmp.libgmp"))
            return
        end
        local argv = {
            "--prefix=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--disable-shared",
            "--with-pic"
        }
        os.vrun("mkdir -p " .. gmp_env:get("toolchain.native.gmp.build_dir"))
        os.cd(gmp_env:get("toolchain.native.gmp.build_dir"))
        os.vrunv(path.join(gmp_env:get("toolchain.gmp.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("gmp-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        if os.exists(gmp_env:get("toolchain.cross.gmp.libgmp")) then 
            print("cross libgmp has already built: ", gmp_env:get("toolchain.cross.gmp.libgmp"))
            return
        end
        local argv = {
            "--prefix=" .. gmp_env:get("toolchain.cross.gmp.prefix"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "--with-pic"
        }
        os.vrun("mkdir -p " .. gmp_env:get("toolchain.cross.gmp.build_dir"))
        os.cd(gmp_env:get("toolchain.cross.gmp.build_dir"))
        os.vrunv(path.join(gmp_env:get("toolchain.gmp.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)
