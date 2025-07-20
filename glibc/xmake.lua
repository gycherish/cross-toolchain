target("glibc-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.glibc")
        target:set("toolchain.glibc.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.native.glibc.build_dir", path.join(toolchain_env:get("toolchain.native.build_dir"), package_info.dirname))
        target:set("toolchain.native.glibc.libc", path.join(toolchain_env:get("toolchain.native.prefix"), "lib", "libc.so"))
        target:set("toolchain.cross.glibc.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname))
        target:set("toolchain.cross.glibc.libc", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "lib", "libc.so"))
        target:set("toolchain.cross_native.glibc.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.glibc.libc", path.join(toolchain_env:get("toolchain.cross_native.sysroot.usr"), "lib", "libc.so"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.glibc: ", package_info)
            print("toolchain.glibc.source_dir: ", target:get("toolchain.glibc.source_dir"))
            print("toolchain.native.glibc.build_dir: ", target:get("toolchain.native.glibc.build_dir"))
            print("toolchain.native.glibc.libc: ", target:get("toolchain.native.glibc.libc"))
            print("toolchain.cross.glibc.build_dir: ", target:get("toolchain.cross.glibc.build_dir"))
            print("toolchain.cross.glibc.libc: ", target:get("toolchain.cross.glibc.libc"))
            print("toolchain.cross_native.glibc.build_dir: ", target:get("toolchain.cross_native.glibc.build_dir"))
            print("toolchain.cross_native.glibc.libc: ", target:get("toolchain.cross_native.glibc.libc"))
        end
    end)

target("glibc-download")
    set_default(false)
    set_kind("phony")
    add_deps("glibc-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.glibc"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.glibc"), toolchain_env:get("toolchain.source_dir"))
    end)

target("glibc-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("glibc-download")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local glibc_env = project.target("glibc-env")
        if os.exists(glibc_env:get("toolchain.native.glibc.libc")) then
            print("native glibc has already built: ", glibc_env:get("toolchain.native.glibc.libc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.native.prefix"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-profile"
        }
        os.vrun("mkdir -p " .. glibc_env:get("toolchain.native.glibc.build_dir"))
        os.cd(glibc_env:get("toolchain.native.glibc.build_dir"))
        os.vrunv(path.join(glibc_env:get("toolchain.glibc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)

target("glibc-cross-build")
    set_default(false)
    set_kind("phony")
    add_deps("glibc-download")
    add_deps("gcc-cross-bootstrap-build")
    add_deps("linux-cross-header-install")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local linux_env = project.target("linux-env")
        local gcc_env = project.target("gcc-env")
        local glibc_env = project.target("glibc-env")
        if os.exists(glibc_env:get("toolchain.cross.glibc.libc")) then
            print("cross glibc has already built: ", glibc_env:get("toolchain.cross.glibc.libc"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-headers=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "include"),
            "--enable-kernel=" .. linux_env:get("toolchain.linux.version"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-profile",
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc"),
            "CPP=" .. gcc_env:get("toolchain.cross.gcc.cpp"),
            "CXX=" .. gcc_env:get("toolchain.cross.gcc.cxx"),
        }
        os.vrun("mkdir -p " .. glibc_env:get("toolchain.cross.glibc.build_dir"))
        os.cd(glibc_env:get("toolchain.cross.glibc.build_dir"))
        os.vrunv(path.join(glibc_env:get("toolchain.glibc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)

target("glibc-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("gcc-cross-final-build")
    add_deps("linux-cross-native-header-install")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local linux_env = project.target("linux-env")
        local gcc_env = project.target("gcc-env")
        local glibc_env = project.target("glibc-env")
        if os.exists(glibc_env:get("toolchain.cross_native.glibc.libc")) then
            print("cross native glibc has already built: ", glibc_env:get("toolchain.cross_native.glibc.libc"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.sysroot.usr"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--disable-bootstrap",
            "--disable-werror",
            "--disable-nls",
            "--disable-profile",
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc"),
            "CPP=" .. gcc_env:get("toolchain.cross.gcc.cpp"),
            "CXX=" .. gcc_env:get("toolchain.cross.gcc.cxx"),
        }
        os.vrun("mkdir -p " .. glibc_env:get("toolchain.cross_native.glibc.build_dir"))
        os.cd(glibc_env:get("toolchain.cross_native.glibc.build_dir"))
        os.vrunv(path.join(glibc_env:get("toolchain.glibc.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
    end)
