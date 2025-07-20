target("mpc-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.mpc")
        target:set("toolchain.mpc.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.native.mpc.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), package_info.dirname))
        target:set("toolchain.native.mpc.prefix", path.join(target:get("toolchain.native.mpc.build_dir"), "install"))
        target:set("toolchain.native.mpc.libmpc", path.join(target:get("toolchain.native.mpc.prefix"), "lib", "libmpc.a"))
        target:set("toolchain.cross.mpc.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname))
        target:set("toolchain.cross.mpc.prefix", path.join(target:get("toolchain.cross.mpc.build_dir"), "install"))
        target:set("toolchain.cross.mpc.libmpc", path.join(target:get("toolchain.cross.mpc.prefix"), "lib", "libmpc.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.mpc: ", package_info)
            print("toolchain.mpc.source_dir: ", target:get("toolchain.mpc.source_dir"))
            print("toolchain.native.mpc.build_dir: ", target:get("toolchain.native.mpc.build_dir"))
            print("toolchain.native.mpc.prefix: ", target:get("toolchain.native.mpc.prefix"))
            print("toolchain.native.mpc.libmpc: ", target:get("toolchain.native.mpc.libmpc"))
            print("toolchain.cross.mpc.build_dir: ", target:get("toolchain.cross.mpc.build_dir"))
            print("toolchain.cross.mpc.prefix: ", target:get("toolchain.cross.mpc.prefix"))
            print("toolchain.cross.mpc.libmpc: ", target:get("toolchain.cross.mpc.libmpc"))
        end
    end)

target("mpc-download")
    set_default(false)
    set_kind("phony")
    add_deps("mpc-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.mpc"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.mpc"), toolchain_env:get("toolchain.source_dir"))
    end)

target("mpc-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("mpc-download")
    add_deps("gmp-native-build")
    add_deps("mpfr-native-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local mpc_env = project.target("mpc-env")
        if os.exists(mpc_env:get("toolchain.native.mpc.libmpc")) then 
            print("native libmpc has already built: ", mpc_env:get("toolchain.native.mpc.libmpc"))
            return
        end
        local argv = {
            "--prefix=" .. mpc_env:get("toolchain.native.mpc.prefix"),
            "--disable-shared",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        os.vrun("mkdir -p " .. mpc_env:get("toolchain.native.mpc.build_dir"))
        os.cd(mpc_env:get("toolchain.native.mpc.build_dir"))
        os.vrunv(path.join(mpc_env:get("toolchain.mpc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("mpc-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("mpc-download")
    add_deps("gmp-cross-build")
    add_deps("mpfr-cross-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local mpc_env = project.target("mpc-env")
        if os.exists(mpc_env:get("toolchain.cross.mpc.libmpc")) then 
            print("cross libmpc has already built: ", mpc_env:get("toolchain.cross.mpc.libmpc"))
            return
        end
        local argv = {
            "--prefix=" .. mpc_env:get("toolchain.cross.mpc.prefix"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-shared",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.cross.gmp.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.cross.mpfr.prefix")
            
        }
        os.vrun("mkdir -p " .. mpc_env:get("toolchain.cross.mpc.build_dir"))
        os.cd(mpc_env:get("toolchain.cross.mpc.build_dir"))
        os.vrunv(path.join(mpc_env:get("toolchain.mpc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)
