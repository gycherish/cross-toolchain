target("binutils-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.binutils.url", "https://github.com/bminor/binutils-gdb.git")
        target:set("toolchain.binutils.branch", "binutils-2_41-branch")
        target:set("toolchain.binutils.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "binutils-2.41"))
        target:set("toolchain.cross.binutils.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "binutils-2.41"))
        target:set("toolchain.cross.binutils.ld", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "bin", "ld"))
        target:set("toolchain.cross.binutils.gdb.host.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "binutils-2.41-gdb-host"))
        target:set("toolchain.cross.binutils.gdb.host.gdb", path.join(toolchain_env:get("toolchain.cross.prefix"), "bin", toolchain_env:get("toolchain.cross.target") .. "-gdb"))
        target:set("toolchain.cross.binutils.gdb.target.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "binutils-2.41-gdb-target"))
        target:set("toolchain.cross.binutils.gdb.target.gdb", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "bin", "gdb"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.binutils.url: ", target:get("toolchain.binutils.url"))
            print("toolchain.binutils.branch: ", target:get("toolchain.binutils.branch"))
            print("toolchain.binutils.source_dir: ", target:get("toolchain.binutils.source_dir"))
            print("toolchain.cross.binutils.build_dir: ", target:get("toolchain.cross.binutils.build_dir"))
            print("toolchain.cross.binutils.ld: ", target:get("toolchain.cross.binutils.ld"))
            print("toolchain.cross.binutils.gdb.host.build_dir: ", target:get("toolchain.cross.binutils.gdb.host.build_dir"))
            print("toolchain.cross.binutils.gdb.host.gdb: ", target:get("toolchain.cross.binutils.gdb.host.gdb"))
            print("toolchain.cross.binutils.gdb.target.build_dir: ", target:get("toolchain.cross.binutils.gdb.target.build_dir"))
            print("toolchain.cross.binutils.gdb.target.gdb: ", target:get("toolchain.cross.binutils.gdb.target.gdb"))
        end
    end)

target("binutils-download")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
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
        if os.exists(binutils_env:get("toolchain.cross.binutils.ld")) then 
            print("binutils has already built: ", binutils_env:get("toolchain.cross.binutils.ld"))
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
