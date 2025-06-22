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
        target:set("toolchain.native.gcc.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), "gcc-14"))
        target:set("toolchain.native.gcc.cc", path.join(toolchain_env:get("toolchain.native.prefix"), "bin", "gcc"))
        target:set("toolchain.cross.gcc.build_bootstrap_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "gcc-14-bootstrap"))
        target:set("toolchain.cross.gcc.build_final_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), "gcc-14-final"))
        target:set("toolchain.cross.gcc.final_install_flag", path.join(target:get("toolchain.cross.gcc.build_final_dir"), "gcc-installed"))
        local bin_prefix = path.join(toolchain_env:get("toolchain.cross.prefix"), "bin", toolchain_env:get("toolchain.cross.target") .. "-")
        target:set("toolchain.cross.gcc.cc", bin_prefix .. "gcc")
        target:set("toolchain.cross.gcc.cpp", bin_prefix .. "cpp")
        target:set("toolchain.cross.gcc.cxx", bin_prefix .. "g++")
        target:set("toolchain.cross.gcc.ranlib", bin_prefix .. "ranlib")
        target:set("toolchain.cross.gcc.strip", bin_prefix .. "strip")
        target:set("toolchain.cross_native.gcc.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), "gcc-14"))
        target:set("toolchain.cross_native.gcc.cc", path.join(toolchain_env:get("toolchain.cross_native.prefix"), "bin", "gcc" .. toolchain_env:get("toolchain.exe.suffix")))
        target:set("toolchain.cross_native.gcc.cc1_dir", path.join(toolchain_env:get("toolchain.cross_native.prefix"), "libexec", "gcc", toolchain_env:get("toolchain.cross.target"), "14"))

        local extra_configure = {}
        local final_extra_configure = {}
        if get_config("Libc") == "musl" then
            extra_configure = table.join(extra_configure, {
                "--disable-shared",
                "--disable-libsanitizer",
                "--enable-linker-plugin-configure-flags=--with-pic",
                "--enable-linker-plugin-configure-flags=--disable-shared",
            })
            final_extra_configure = table.join(final_extra_configure, {
                "--with-specs=" .. "%{!nostdlib:%{!r:%{!nodefaultlibs:-ljemalloc}}}", -- enable jemalloc to be linked by default 
            })
        end
        if get_config("Libc") == "mingw" and get_config("Arch") == "i686" then
            extra_configure = table.join(extra_configure, {
                "--disable-sjlj-exceptions",
                "--with-dwarf2",
            })
        end
        target:set("toolchain.gcc.extra_configure", extra_configure)
        target:set("toolchain.gcc.final_extra_configure", final_extra_configure)

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.gcc.url: ", target:get("toolchain.gcc.url"))
            print("toolchain.gcc.branch: ", target:get("toolchain.gcc.branch"))
            print("toolchain.gcc.source_dir: ", target:get("toolchain.gcc.source_dir"))
            print("toolchain.gcc.extra_configure: ", target:get("toolchain.gcc.extra_configure"))
            print("toolchain.gcc.final_extra_configure: ", target:get("toolchain.gcc.final_extra_configure"))
            print("toolchain.native.gcc.build_dir: ", target:get("toolchain.native.gcc.build_dir"))
            print("toolchain.native.gcc.cc: ", target:get("toolchain.native.gcc.cc"))
            print("toolchain.cross.gcc.build_bootstrap_dir: ", target:get("toolchain.cross.gcc.build_bootstrap_dir"))
            print("toolchain.cross.gcc.build_final_dir: ", target:get("toolchain.cross.gcc.build_final_dir"))
            print("toolchain.cross.gcc.final_install_flag: ", target:get("toolchain.cross.gcc.final_install_flag"))
            print("toolchain.cross.gcc.cc: ", target:get("toolchain.cross.gcc.cc"))
            print("toolchain.cross.gcc.cpp: ", target:get("toolchain.cross.gcc.cpp"))
            print("toolchain.cross.gcc.cxx: ", target:get("toolchain.cross.gcc.cxx"))
            print("toolchain.cross.gcc.ranlib: ", target:get("toolchain.cross.gcc.ranlib"))
            print("toolchain.cross.gcc.strip: ", target:get("toolchain.cross.gcc.strip"))
            print("toolchain.cross_native.gcc.build_dir: ", target:get("toolchain.cross_native.gcc.build_dir"))
            print("toolchain.cross_native.gcc.cc: ", target:get("toolchain.cross_native.gcc.cc"))
            print("toolchain.cross_native.gcc.cc1_dir: ", target:get("toolchain.cross_native.gcc.cc1_dir"))
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
        os.exec("./contrib/download_prerequisites --only-gettext")
    end)

target("gcc-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-download-prerequisites")
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
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.native.gcc.cc")) then 
            print("native gcc has already built: ", gcc_env:get("toolchain.native.gcc.cc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.native.prefix"),
            "--enable-languages=c,c++",
            "--enable-threads=posix",
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--with-isl=" .. isl_env:get("toolchain.native.isl.prefix"),
            "--with-mpc=" .. mpc_env:get("toolchain.native.mpc.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        os.vrun("mkdir -p " .. gcc_env:get("toolchain.native.gcc.build_dir"))
        os.cd(gcc_env:get("toolchain.native.gcc.build_dir"))
        os.vrunv(gcc_env:get("toolchain.gcc.source_dir") .. "/configure", argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("gcc-cross-bootstrap-build")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-download-prerequisites")
    add_deps("gmp-native-build")
    add_deps("isl-native-build")
    add_deps("mpc-native-build")
    add_deps("mpfr-native-build")
    add_deps("binutils-cross-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local isl_env = project.target("isl-env")
        local mpc_env = project.target("mpc-env")
        local mpfr_env = project.target("mpfr-env")
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.cross.gcc.cc")) then
            print("cross bootstrap gcc has already built: ", gcc_env:get("toolchain.cross.gcc.cc"))
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
            "--disable-libstdcxx",
            "--with-gcc-major-version-only",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--with-isl=" .. isl_env:get("toolchain.native.isl.prefix"),
            "--with-mpc=" .. mpc_env:get("toolchain.native.mpc.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        argv = table.join(argv, gcc_env:get("toolchain.gcc.extra_configure"))
        os.vrun("mkdir -p " .. gcc_env:get("toolchain.cross.gcc.build_bootstrap_dir"))
        os.cd(gcc_env:get("toolchain.cross.gcc.build_bootstrap_dir"))
        os.vrunv(path.join(gcc_env:get("toolchain.gcc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("gcc-cross-final-build")
    set_default(false)
    set_kind("phony")
    add_deps("gmp-native-build")
    add_deps("isl-native-build")
    add_deps("mpc-native-build")
    add_deps("mpfr-native-build")
    add_deps("gcc-cross-bootstrap-build")
    if get_config("Libc") == "musl" then
        add_deps("jemalloc-cross-build")
        add_deps("musl-cross-build")
    elseif get_config("Libc") == "mingw" then
        add_deps("mingw-cross-winpthread-build")
        add_deps("mingw-cross-crt-build")
    else
        add_deps("glibc-cross-build")
    end
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gmp_env = project.target("gmp-env")
        local isl_env = project.target("isl-env")
        local mpc_env = project.target("mpc-env")
        local mpfr_env = project.target("mpfr-env")
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.cross.gcc.final_install_flag")) then 
            print("cross final gcc has already built: ", gcc_env:get("toolchain.cross.gcc.cc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross.prefix"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-headers=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "include"),
            "--enable-languages=c,c++",
            "--enable-threads=posix",
            "--enable-ssp",
            "--enable-lto",
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--with-gcc-major-version-only",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.native.gmp.prefix"),
            "--with-isl=" .. isl_env:get("toolchain.native.isl.prefix"),
            "--with-mpc=" .. mpc_env:get("toolchain.native.mpc.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.native.mpfr.prefix")
        }
        argv = table.join(argv, gcc_env:get("toolchain.gcc.extra_configure"))
        argv = table.join(argv, gcc_env:get("toolchain.gcc.final_extra_configure"))
        os.vrun("mkdir -p " .. gcc_env:get("toolchain.cross.gcc.build_final_dir"))
        os.cd(gcc_env:get("toolchain.cross.gcc.build_final_dir"))
        os.vrunv(gcc_env:get("toolchain.gcc.source_dir") .. "/configure", argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
        io.open(gcc_env:get("toolchain.cross.gcc.final_install_flag"), "w")
    end)

target("gcc-cross-package")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-cross-final-build")
    add_deps("gdb-cross-host-build")
    add_deps("gdb-cross-target-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_file =  path.join(toolchain_env:get("toolchain.cross.package_dir"), toolchain_env:get("toolchain.cross.target") .. ".tar.gz")
        if os.exists(package_file) then 
            print("cross toolchain has already packaged: ", package_file)
            return
        end
        os.mkdir(toolchain_env:get("toolchain.cross.package_dir"))
        os.cd(toolchain_env:get("toolchain.cross.out_dir"))
        local argv = {
            "-czvf",
            package_file,
            toolchain_env:get("toolchain.cross.target")
        }
        os.execv("tar", argv)
    end)

target("gcc-cross-native-build")
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
        local gcc_env = project.target("gcc-env")
        if os.exists(gcc_env:get("toolchain.cross_native.gcc.cc")) then 
            print("cross native gcc has already built: ", gcc_env:get("toolchain.cross_native.gcc.cc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.prefix"),
            "--with-sysroot=" .. toolchain_env:get("toolchain.cross_native.sysroot"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--target=" .. toolchain_env:get("toolchain.cross.target"),
            "--enable-languages=c,c++",
            "--enable-threads=posix",
            "--enable-ssp",
            "--enable-lto",
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-multilib",
            "--with-gcc-major-version-only",
            "--with-pic",
            "--with-gmp=" .. gmp_env:get("toolchain.cross.gmp.prefix"),
            "--with-isl=" .. isl_env:get("toolchain.cross.isl.prefix"),
            "--with-mpc=" .. mpc_env:get("toolchain.cross.mpc.prefix"),
            "--with-mpfr=" .. mpfr_env:get("toolchain.cross.mpfr.prefix")
        }
        argv = table.join(argv, gcc_env:get("toolchain.gcc.extra_configure"))
        argv = table.join(argv, gcc_env:get("toolchain.gcc.final_extra_configure"))
        os.vrun("mkdir -p " .. gcc_env:get("toolchain.cross_native.gcc.build_dir"))
        os.cd(gcc_env:get("toolchain.cross_native.gcc.build_dir"))
        os.vrunv(gcc_env:get("toolchain.gcc.source_dir") .. "/configure", argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
    end)

target("gcc-cross-native-package")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-cross-package")
    add_deps("binutils-cross-native-build")
    add_deps("gcc-cross-native-build")
    if get_config("Libc") == "musl" then
        add_deps("jemalloc-cross-native-build")
        add_deps("musl-cross-native-build")
    elseif get_config("Libc") == "mingw" then
        add_deps("mingw-cross-native-build")
    else
        add_deps("glibc-cross-native-build")
    end
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local mingw_env = project.target("mingw-env")
        local package_file =  path.join(toolchain_env:get("toolchain.cross_native.package_dir"), toolchain_env:get("toolchain.cross.target") .. ".tar.gz")
        if os.exists(package_file) then 
            print("cross native toolchain has already packaged: ", package_file)
            return
        end
        if get_config("Libc") == "mingw" then
            local cc1_winpthread = path.join(gcc_env:get("toolchain.cross_native.gcc.cc1_dir"), mingw_env:get("toolchain.mingw.winpthread.dll_name"))
            os.cp(mingw_env:get("toolchain.cross_native.mingw.winpthread_dll"), cc1_winpthread)
            local as_winpthread = path.join(toolchain_env:get("toolchain.cross_native.prefix"), toolchain_env:get("toolchain.cross.target"), "bin", mingw_env:get("toolchain.mingw.winpthread.dll_name"))
            os.cp(mingw_env:get("toolchain.cross_native.mingw.winpthread_dll"), as_winpthread)
        end
        os.mkdir(toolchain_env:get("toolchain.cross_native.package_dir"))
        os.cd(toolchain_env:get("toolchain.cross_native.out_dir"))
        local argv = {
            "-czvf",
            package_file,
            toolchain_env:get("toolchain.cross.target")
        }
        os.execv("tar", argv)
    end)
