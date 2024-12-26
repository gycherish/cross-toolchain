target("gdb-cross-host-build")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-download")
    add_deps("gmp-cross-host-build")
    add_deps("mpfr-cross-host-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
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
            "--with-gmp=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--with-mpfr=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--enable-gdb"
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
    add_deps("gmp-cross-target-build")
    add_deps("mpfr-cross-target-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
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
            "--with-gmp=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--with-mpfr=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--enable-gdb",
            "--enable-gdbserver"
        }
        os.vrun("mkdir -p " .. binutils_env:get("toolchain.cross.binutils.gdb.target.build_dir"))
        os.cd(binutils_env:get("toolchain.cross.binutils.gdb.target.build_dir"))
        os.vrunv(path.join(binutils_env:get("toolchain.binutils.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j")
        os.exec("make all-gdbserver -j")
        os.exec("make install-gdb -j")
        os.exec("make install-gdbserver -j")
    end)
