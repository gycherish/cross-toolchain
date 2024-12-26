target("gcc-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.gcc.url", "https://github.com/gcc-mirror/gcc.git")
        target:set("toolchain.gcc.branch", "releases/gcc-14")
        target:set("toolchain.gcc.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "gcc-14"))
        target:set("toolchain.cross.gcc.build_bootstrap_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "gcc-14-bootstrap"))
        target:set("toolchain.cross.gcc.build_final_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "gcc-14-final"))
        target:set("toolchain.cross.gcc.build_final_flag", path.join(target:get("toolchain.cross.gcc.build_final_dir"), "gcc-installed"))
        local bin_prefix = path.join(toolchain_env:get("toolchain.cross.prefix"), "bin", toolchain_env:get("toolchain.cross.target") .. "-")
        target:set("toolchain.cross.gcc.cc", bin_prefix .. "gcc")
        target:set("toolchain.cross.gcc.cpp", bin_prefix .. "cpp")
        target:set("toolchain.cross.gcc.cxx", bin_prefix .. "g++")

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.gcc.url: ", target:get("toolchain.gcc.url"))
            print("toolchain.gcc.branch: ", target:get("toolchain.gcc.branch"))
            print("toolchain.gcc.source_dir: ", target:get("toolchain.gcc.source_dir"))
            print("toolchain.cross.gcc.build_bootstrap_dir: ", target:get("toolchain.cross.gcc.build_bootstrap_dir"))
            print("toolchain.cross.gcc.build_final_dir: ", target:get("toolchain.cross.gcc.build_final_dir"))
            print("toolchain.cross.gcc.build_final_flag: ", target:get("toolchain.cross.gcc.build_final_flag"))
            print("toolchain.cross.gcc.cc: ", target:get("toolchain.cross.gcc.cc"))
            print("toolchain.cross.gcc.cpp: ", target:get("toolchain.cross.gcc.cpp"))
            print("toolchain.cross.gcc.cxx: ", target:get("toolchain.cross.gcc.cxx"))
        end
    end)

target("gcc-download")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.gcc.source_dir")) then
            print("gcc source code has already existed: ", gcc_env:get("toolchain.gcc.source_dir"))
            return
        end
        git.clone(gcc_env:get("toolchain.gcc.url"), {
            depth = 1, 
            branch = gcc_env:get("toolchain.gcc.branch"),
            outputdir = gcc_env:get("toolchain.gcc.source_dir")
        })
        os.cd(gcc_env:get("toolchain.gcc.source_dir"))
        git.apply(path.join(toolchain_env:get("toolchain.patch_dir"), "gcc-libstdc++-no-fpic.patch"))
    end)

target("gcc-download-prerequisites")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-download")
    on_build(function (target)
        import("core.project.project")
        local gcc_env = project.target("gcc-env")
        os.cd(gcc_env:get("toolchain.gcc.source_dir"))
        os.exec("./contrib/download_prerequisites")
    end)

target("gcc-cross-bootstrap-build")
    set_default(false)
    set_kind("phony")
    add_deps("binutils-cross-build")
    add_deps("gcc-download-prerequisites")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.cross.gcc.cc")) then
            print("bootstrap gcc has already built: ", gcc_env:get("toolchain.cross.gcc.cc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--enable-languages=c,c++",
            "--with-newlib",
            "--without-headers",
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-shared",
            "--disable-multilib",
            "--disable-threads",
            "--disable-libatomic",
            "--disable-libgomp",
            "--disable-libquadmath",
            "--disable-libssp",
            "--disable-libvtv",
            "--disable-libstdcxx"
        }
        os.vrun("mkdir -p " .. gcc_env:get("toolchain.cross.gcc.build_bootstrap_dir"))
        os.cd(gcc_env:get("toolchain.cross.gcc.build_bootstrap_dir"))
        os.vrunv(path.join(gcc_env:get("toolchain.gcc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("gcc-cross-final-build")
    set_default(false)
    set_kind("phony")
    if get_config("Libc") == "musl" then
        add_deps("musl-cross-build")
    else
        add_deps("glibc-cross-build") 
    end
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.cross.gcc.build_final_flag")) then 
            print("final gcc has already built: ", gcc_env:get("toolchain.cross.gcc.build_final_flag"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-headers=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "include"),
            "--enable-languages=c,c++",
            "--enable-threads=posix",
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--with-pic"
        }
        if get_config("Libc") == "musl" then
            table.insert(argv, "--disable-shared")
            table.insert(argv, "--disable-libsanitizer")
        end
        os.vrun("mkdir -p " .. gcc_env:get("toolchain.cross.gcc.build_final_dir"))
        os.cd(gcc_env:get("toolchain.cross.gcc.build_final_dir"))
        os.vrunv(gcc_env:get("toolchain.gcc.source_dir") .. "/configure", argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
        io.open(gcc_env:get("toolchain.cross.gcc.build_final_flag"), "w")
    end)

target("gcc-cross-package")
    set_default(false)
    set_kind("phony")
    add_deps("gdb-cross-host-build")
    add_deps("gdb-cross-target-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local package_file =  path.join(toolchain_env:get("toolchain.package_dir"), toolchain_env:get("toolchain.cross.target") .. ".tar.gz")
        if os.exists(package_file) then 
            print("toolchain has already packaged: ", package_file)
            return
        end
        os.mkdir(toolchain_env:get("toolchain.package_dir"))
        os.cd(toolchain_env:get("toolchain.out_dir"))
        local argv = {
            "-czvf",
            package_file,
            toolchain_env:get("toolchain.cross.target")
        }
        os.execv("tar", argv)
    end)
