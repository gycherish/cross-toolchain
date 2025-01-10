target("binutils-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.binutils.url", "https://github.com/bminor/binutils-gdb.git")
        target:set("toolchain.binutils.branch", "binutils-2_42-branch")
        target:set("toolchain.binutils.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "binutils-2.42"))
        target:set("toolchain.native.binutils.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), "binutils-2.42"))
        target:set("toolchain.native.binutils.ld", path.join(toolchain_env:get("toolchain.native.prefix"), "bin", "ld"))
        target:set("toolchain.cross.binutils.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "binutils-2.42"))
        target:set("toolchain.cross.binutils.ld", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "bin", "ld"))
        target:set("toolchain.cross.binutils.gdb.host.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "binutils-2.42-gdb-host"))
        target:set("toolchain.cross.binutils.gdb.host.gdb", path.join(toolchain_env:get("toolchain.cross.prefix"), "bin", toolchain_env:get("toolchain.cross.target") .. "-gdb"))
        target:set("toolchain.cross.binutils.gdb.target.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "binutils-2.42-gdb-target"))
        target:set("toolchain.cross.binutils.gdb.target.gdb", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "bin", "gdb"))
        target:set("toolchain.cross_native.binutils.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), "binutils-2.42"))
        target:set("toolchain.cross_native.binutils.ld", path.join(toolchain_env:get("toolchain.cross_native.prefix"), "bin", "ld"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.binutils.url: ", target:get("toolchain.binutils.url"))
            print("toolchain.binutils.branch: ", target:get("toolchain.binutils.branch"))
            print("toolchain.binutils.source_dir: ", target:get("toolchain.binutils.source_dir"))
            print("toolchain.native.binutils.build_dir: ", target:get("toolchain.native.binutils.build_dir"))
            print("toolchain.native.binutils.ld: ", target:get("toolchain.native.binutils.ld"))
            print("toolchain.cross.binutils.build_dir: ", target:get("toolchain.cross.binutils.build_dir"))
            print("toolchain.cross.binutils.ld: ", target:get("toolchain.cross.binutils.ld"))
            print("toolchain.cross.binutils.gdb.host.build_dir: ", target:get("toolchain.cross.binutils.gdb.host.build_dir"))
            print("toolchain.cross.binutils.gdb.host.gdb: ", target:get("toolchain.cross.binutils.gdb.host.gdb"))
            print("toolchain.cross.binutils.gdb.target.build_dir: ", target:get("toolchain.cross.binutils.gdb.target.build_dir"))
            print("toolchain.cross.binutils.gdb.target.gdb: ", target:get("toolchain.cross.binutils.gdb.target.gdb"))
            print("toolchain.cross_native.binutils.build_dir: ", target:get("toolchain.cross_native.binutils.build_dir"))
            print("toolchain.cross_native.binutils.ld: ", target:get("toolchain.cross_native.binutils.ld"))
        end
    end)

target("binutils-download")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local binutils_env = project.target("binutils-env")
        if os.exists(binutils_env:get("toolchain.binutils.source_dir")) then
            print("binutils source code has already existed: ", binutils_env:get("toolchain.binutils.source_dir"))
            return
        end
        git.clone(binutils_env:get("toolchain.binutils.url"), {
            depth = 1, 
            branch = binutils_env:get("toolchain.binutils.branch"),
            outputdir = binutils_env:get("toolchain.binutils.source_dir")
        })
        os.cd(binutils_env:get("toolchain.binutils.source_dir"))
        git.apply(path.join(toolchain_env:get("toolchain.patch_dir"), "binutils-add-W_EXITCODE-macro-for-non-glibc-systems.patch"))
        git.apply(path.join(toolchain_env:get("toolchain.patch_dir"), "binutils-disable-gprofng-for-musl.patch"))
    end)

target("binutils-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-download")
    add_deps("gmp-native-build")
    add_deps("isl-native-build")
    add_deps("mpc-native-build")
    add_deps("mpfr-native-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local isl_env = project.target("isl-env")
        local mpc_env = project.target("mpc-env")
        local mpfr_env = project.target("mpfr-env")
        local binutils_env = project.target("binutils-env")
        if os.exists(binutils_env:get("toolchain.native.binutils.ld")) then 
            print("native binutils has already built: ", binutils_env:get("toolchain.native.binutils.ld"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.native.prefix"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--enable-gdb",
            "--enable-gdbserver",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--with-isl=" .. isl_env:get("toolchain.native.isl.prefix"),
            "--with-mpc=" .. mpc_env:get("toolchain.native.mpc.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        os.vrun("mkdir -p " .. binutils_env:get("toolchain.native.binutils.build_dir"))
        os.cd(binutils_env:get("toolchain.native.binutils.build_dir"))
        os.vrunv(path.join(binutils_env:get("toolchain.binutils.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("binutils-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-download")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local binutils_env = project.target("binutils-env")
        os.addenv("PATH", path.join(toolchain_env:get("toolchain.cross.prefix"), "bin"))
        import("core.base.option")
        if option.get("verbose") then
            print("PATH: ", os.getenv("PATH"))
        end
        if os.exists(binutils_env:get("toolchain.cross.binutils.ld")) then 
            print("cross binutils has already built: ", binutils_env:get("toolchain.cross.binutils.ld"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--disable-gdb",
            "--disable-gdbserver"
        }
        os.vrun("mkdir -p " .. binutils_env:get("toolchain.cross.binutils.build_dir"))
        os.cd(binutils_env:get("toolchain.cross.binutils.build_dir"))
        os.vrunv(path.join(binutils_env:get("toolchain.binutils.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("binutils-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-cross-final-build")
    add_deps("gmp-cross-build")
    add_deps("isl-cross-build")
    add_deps("mpc-cross-build")
    add_deps("mpfr-cross-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local isl_env = project.target("isl-env")
        local mpc_env = project.target("mpc-env")
        local mpfr_env = project.target("mpfr-env")
        local binutils_env = project.target("binutils-env")
        if os.exists(binutils_env:get("toolchain.cross_native.binutils.ld")) then 
            print("cross native binutils has already built: ", binutils_env:get("toolchain.cross_native.binutils.ld"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.prefix"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--enable-gdb",
            "--enable-gdbserver",
            "--with-gmp=" .. gmp_env:get("toolchain.cross.gmp.prefix"),
            "--with-isl=" .. isl_env:get("toolchain.cross.isl.prefix"),
            "--with-mpc=" .. mpc_env:get("toolchain.cross.mpc.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.cross.mpfr.prefix")
        }
        os.vrun("mkdir -p " .. binutils_env:get("toolchain.cross_native.binutils.build_dir"))
        os.cd(binutils_env:get("toolchain.cross_native.binutils.build_dir"))
        os.vrunv(path.join(binutils_env:get("toolchain.binutils.source_dir"), "configure"), argv)
        os.exec("make -j")
        -- BUG: binutils does not use the correct strip when do "make install-strip" and reported an error: "strip: Unable to recognise the format of the input file"
        -- os.exec("make install-strip -j")
        os.exec("make install -j")
    end)
