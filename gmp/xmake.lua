target("gmp-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.gmp.basename", "gmp-6.3.0.tar.xz")
        target:set("toolchain.gmp.url", "https://gmplib.org/download/gmp/" .. target:get("toolchain.gmp.basename"))
        target:set("toolchain.gmp.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "gmp-6.3.0"))
        target:set("toolchain.gmp.host.build_dir", path.join(toolchain_env:get("toolchain.build_dir"), "gmp-6.3.0-host"))
        target:set("toolchain.gmp.host.libgmp", path.join(toolchain_env:get("toolchain.prefix"), "lib", "libgmp.a"))
        target:set("toolchain.gmp.target.build_dir", path.join(toolchain_env:get("toolchain.build_dir"), "gmp-6.3.0-target"))
        target:set("toolchain.gmp.target.libgmp", path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target"), "lib", "libgmp.a"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.gmp.basename: ", target:get("toolchain.gmp.basename"))
            print("toolchain.gmp.url: ", target:get("toolchain.gmp.url"))
            print("toolchain.gmp.source_dir: ", target:get("toolchain.gmp.source_dir"))
            print("toolchain.gmp.host.build_dir: ", target:get("toolchain.gmp.host.build_dir"))
            print("toolchain.gmp.host.libgmp: ", target:get("toolchain.gmp.host.libgmp"))
            print("toolchain.gmp.target.build_dir: ", target:get("toolchain.gmp.target.build_dir"))
            print("toolchain.gmp.target.libgmp: ", target:get("toolchain.gmp.target.libgmp"))
        end
    end)

target("gmp-download")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-env")
    on_build(function (target)
        import("core.project.project")
        import("net.http")
        import("utils.archive")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        if os.exists(gmp_env:get("toolchain.gmp.source_dir")) then
            print("gmp source code has already existed: ", gmp_env:get("toolchain.gmp.source_dir"))
            return
        end
        local output = path.join(toolchain_env:get("toolchain.source_dir"), gmp_env:get("toolchain.gmp.basename"))
        http.download(gmp_env:get("toolchain.gmp.url"), output)
        archive.extract(output, toolchain_env:get("toolchain.source_dir"))
    end)

target("gmp-host-build")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-download")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        if os.exists(gmp_env:get("toolchain.gmp.host.libgmp")) then 
            print("host libgmp has already built: ", gmp_env:get("toolchain.gmp.host.libgmp"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.prefix"),
            "--disable-shared"
        }
        os.vrun("mkdir -p " .. gmp_env:get("toolchain.gmp.host.build_dir"))
        os.cd(gmp_env:get("toolchain.gmp.host.build_dir"))
        os.vrunv(path.join(gmp_env:get("toolchain.gmp.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("gmp-target-build")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-download")
    add_deps("gcc-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        if os.exists(gmp_env:get("toolchain.gmp.target.libgmp")) then 
            print("target libgmp has already built: ", gmp_env:get("toolchain.gmp.target.libgmp"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target")),
            "--host=" .. toolchain_env:get("toolchain.target"),
            "--disable-shared"
        }
        os.vrun("mkdir -p " .. gmp_env:get("toolchain.gmp.target.build_dir"))
        os.cd(gmp_env:get("toolchain.gmp.target.build_dir"))
        os.vrunv(path.join(gmp_env:get("toolchain.gmp.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)
