target("glibc-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.glibc.url", "https://github.com/bminor/glibc.git")
        target:set("toolchain.glibc.branch", "glibc-2.38")
        target:set("toolchain.glibc.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "glibc-2.38"))
        target:set("toolchain.glibc.build_dir", path.join(toolchain_env:get("toolchain.build_dir"), "glibc-2.38"))
        target:set("toolchain.glibc.libc", path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target"), "lib", "libc.so"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.glibc.url: ", target:get("toolchain.glibc.url"))
            print("toolchain.glibc.branch: ", target:get("toolchain.glibc.branch"))
            print("toolchain.glibc.source_dir: ", target:get("toolchain.glibc.source_dir"))
            print("toolchain.glibc.build_dir: ", target:get("toolchain.glibc.build_dir"))
            print("toolchain.glibc.libc: ", target:get("toolchain.glibc.libc"))
        end
    end)

target("glibc-download")
    set_default(false)
    set_kind("phony")
    add_deps("glibc-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local glibc_env = project.target("glibc-env")
        if os.exists(glibc_env:get("toolchain.glibc.source_dir")) then
            print("glibc source code has already existed: ", glibc_env:get("toolchain.glibc.source_dir"))
            return
        end
        git.clone(glibc_env:get("toolchain.glibc.url"), {
            depth = 1, 
            branch = glibc_env:get("toolchain.glibc.branch"), 
            outputdir = glibc_env:get("toolchain.glibc.source_dir")
        })
    end)

target("glibc-build")
    set_default(false)
    set_kind("phony")
    add_deps("glibc-download")
    add_deps("gcc-bootstrap-build")
    add_deps("linux-header-install")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local linux_env = project.target("linux-env")
        local gcc_env = project.target("gcc-env")
        local glibc_env = project.target("glibc-env")
        if os.exists(glibc_env:get("toolchain.glibc.libc")) then
            print("glibc has already built: ", glibc_env:get("toolchain.glibc.libc"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target")),
            "--host=" .. toolchain_env:get("toolchain.target"),
            "--with-headers=" .. path.join(toolchain_env:get("toolchain.prefix"), toolchain_env:get("toolchain.target"), "include"),
            "--enable-kernel=" .. linux_env:get("toolchain.linux.version"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-profile",
            "CC=" .. gcc_env:get("toolchain.gcc.cc"),
            "CPP=" .. gcc_env:get("toolchain.gcc.cpp"),
            "CXX=" .. gcc_env:get("toolchain.gcc.cxx"),
        }
        os.vrun("mkdir -p " .. glibc_env:get("toolchain.glibc.build_dir"))
        os.cd(glibc_env:get("toolchain.glibc.build_dir"))
        os.vrunv(path.join(glibc_env:get("toolchain.glibc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)
