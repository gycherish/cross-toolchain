target("gdb-cross-host-build")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-download")
    add_deps("gmp-native-build")
    add_deps("mpfr-native-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local binutils_env = project.target("binutils-env")
        if os.exists(binutils_env:get("toolchain.cross.binutils.gdb.host.gdb")) then 
            print("host gdb has already built: ", binutils_env:get("toolchain.cross.binutils.gdb.host.gdb"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--enable-gdb",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        os.vrun("mkdir -p " .. binutils_env:get("toolchain.cross.binutils.gdb.host.build_dir"))
        os.cd(binutils_env:get("toolchain.cross.binutils.gdb.host.build_dir"))
        os.vrunv(path.join(binutils_env:get("toolchain.binutils.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j")
        os.exec("make install-gdb -j")
    end)

target("gdb-cross-target-build")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-download")
    add_deps("gmp-cross-build")
    add_deps("mpfr-cross-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local binutils_env = project.target("binutils-env")
        if os.exists(binutils_env:get("toolchain.cross.binutils.gdb.target.gdb")) then 
            print("target gdb has already built: ", binutils_env:get("toolchain.cross.binutils.gdb.target.gdb"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--enable-gdb",
            "--enable-gdbserver",
            "--with-gmp=" .. gmp_env:get("toolchain.cross.gmp.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.cross.mpfr.prefix"),
        }
        os.vrun("mkdir -p " .. binutils_env:get("toolchain.cross.binutils.gdb.target.build_dir"))
        os.cd(binutils_env:get("toolchain.cross.binutils.gdb.target.build_dir"))
        os.vrunv(path.join(binutils_env:get("toolchain.binutils.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j")
        os.exec("make all-gdbserver -j")
        os.exec("make install-gdb -j")
        os.exec("make install-gdbserver -j")
    end)
