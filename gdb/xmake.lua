target("gdb-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.gdb")
        target:set("toolchain.gdb.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.cross.gdb.host.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname .. "-host"))
        target:set("toolchain.cross.gdb.host.gdb", path.join(toolchain_env:get("toolchain.cross.prefix"), "bin", toolchain_env:get("toolchain.cross.target") .. "-gdb"))
        target:set("toolchain.cross.gdb.target.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname .. "-target"))
        target:set("toolchain.cross.gdb.target.gdb", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "bin", "gdb" .. toolchain_env:get("toolchain.exe.suffix")))
        target:set("toolchain.native.gdb.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), package_info.dirname))
        target:set("toolchain.native.gdb.gdb", path.join(toolchain_env:get("toolchain.native.prefix"), "bin", "gdb"))
        target:set("toolchain.cross_native.gdb.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.gdb.gdb", path.join(toolchain_env:get("toolchain.cross_native.prefix"), "bin", "gdb" .. toolchain_env:get("toolchain.exe.suffix")))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.gdb: ", package_info)
            print("toolchain.gdb.source_dir: ", target:get("toolchain.gdb.source_dir"))
            print("toolchain.cross.gdb.host.build_dir: ", target:get("toolchain.cross.gdb.host.build_dir"))
            print("toolchain.cross.gdb.host.gdb: ", target:get("toolchain.cross.gdb.host.gdb"))
            print("toolchain.cross.gdb.target.build_dir: ", target:get("toolchain.cross.gdb.target.build_dir"))
            print("toolchain.cross.gdb.target.gdb: ", target:get("toolchain.cross.gdb.target.gdb"))
        end
    end)

target("gdb-download")
    set_default(false)
    set_kind("phony")
    add_deps("gdb-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.gdb"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.gdb"), toolchain_env:get("toolchain.source_dir"))
    end)

target("gdb-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gdb-download")
    add_deps("gmp-native-build")
    add_deps("mpfr-native-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local gdb_env = project.target("gdb-env")
        if os.exists(gdb_env:get("toolchain.native.gdb.gdb")) then 
            print("native gdb has already built: ", gdb_env:get("toolchain.native.gdb.gdb"))
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
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        os.vrun("mkdir -p " .. gdb_env:get("toolchain.native.gdb.build_dir"))
        os.cd(gdb_env:get("toolchain.native.gdb.build_dir"))
        os.vrunv(path.join(gdb_env:get("toolchain.gdb.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j" .. os.default_njob())
        os.exec("make all-gdbserver -j" .. os.default_njob())
        os.exec("make install-gdb")
        os.exec("make install-gdbserver")
        os.vrunv("strip", {gdb_env:get("toolchain.native.gdb.gdb"), path.join(path.directory(gdb_env:get("toolchain.native.gdb.gdb")), "gdbserver")})
    end)

target("gdb-cross-host-build")
    set_default(false)
    set_kind("phony")
    add_deps("gdb-download")
    add_deps("gmp-native-build")
    add_deps("mpfr-native-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local gdb_env = project.target("gdb-env")
        if os.exists(gdb_env:get("toolchain.cross.gdb.host.gdb")) then
            print("host gdb has already built: ", gdb_env:get("toolchain.cross.gdb.host.gdb"))
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
        os.vrun("mkdir -p " .. gdb_env:get("toolchain.cross.gdb.host.build_dir"))
        os.cd(gdb_env:get("toolchain.cross.gdb.host.build_dir"))
        os.vrunv(path.join(gdb_env:get("toolchain.gdb.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j" .. os.default_njob())
        os.exec("make install-gdb")
        -- install-gdb does not strip, and an unstripped gdb is a few hundred megabytes
        os.vrunv("strip", {gdb_env:get("toolchain.cross.gdb.host.gdb")})
    end)

target("gdb-cross-target-build")
    set_default(false)
    set_kind("phony")
    add_deps("gdb-download")
    add_deps("gmp-cross-build")
    add_deps("mpfr-cross-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local gdb_env = project.target("gdb-env")
        if os.exists(gdb_env:get("toolchain.cross.gdb.target.gdb")) then
            print("target gdb has already built: ", gdb_env:get("toolchain.cross.gdb.target.gdb"))
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
        os.vrun("mkdir -p " .. gdb_env:get("toolchain.cross.gdb.target.build_dir"))
        os.cd(gdb_env:get("toolchain.cross.gdb.target.build_dir"))
        os.vrunv(path.join(gdb_env:get("toolchain.gdb.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j" .. os.default_njob())
        os.exec("make all-gdbserver -j" .. os.default_njob())
        os.exec("make install-gdb")
        os.exec("make install-gdbserver")
        local gcc_env = project.target("gcc-env")
        local gdb = gdb_env:get("toolchain.cross.gdb.target.gdb")
        os.vrunv(gcc_env:get("toolchain.cross.gcc.strip"), {gdb, path.join(path.directory(gdb), "gdbserver" .. toolchain_env:get("toolchain.exe.suffix"))})
    end)

target("gdb-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gdb-download")
    add_deps("gmp-cross-build")
    add_deps("mpfr-cross-build")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local mpfr_env = project.target("mpfr-env")
        local gdb_env = project.target("gdb-env")
        if os.exists(gdb_env:get("toolchain.cross_native.gdb.gdb")) then 
            print("cross native gdb has already built: ", gdb_env:get("toolchain.cross_native.gdb.gdb"))
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
            "--with-mpfr=" .. mpfr_env:get("toolchain.cross.mpfr.prefix"),
        }
        os.vrun("mkdir -p " .. gdb_env:get("toolchain.cross_native.gdb.build_dir"))
        os.cd(gdb_env:get("toolchain.cross_native.gdb.build_dir"))
        os.vrunv(path.join(gdb_env:get("toolchain.gdb.source_dir"), "configure"), argv)
        os.exec("make all-gdb -j" .. os.default_njob())
        os.exec("make all-gdbserver -j" .. os.default_njob())
        os.exec("make install-gdb")
        os.exec("make install-gdbserver")
        local gcc_env = project.target("gcc-env")
        local gdb = gdb_env:get("toolchain.cross_native.gdb.gdb")
        os.vrunv(gcc_env:get("toolchain.cross.gcc.strip"), {gdb, path.join(path.directory(gdb), "gdbserver" .. toolchain_env:get("toolchain.exe.suffix"))})
    end)
