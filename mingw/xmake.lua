target("mingw-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        local package_info = package_env:get("toolchain.source.mingw")
        target:set("toolchain.mingw.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), package_info.dirname))
        target:set("toolchain.mingw.headers.source_dir", path.join(target:get("toolchain.mingw.source_dir"), "mingw-w64-headers"))
        target:set("toolchain.mingw.headers.link", "mingw")
        target:set("toolchain.mingw.crt.source_dir", path.join(target:get("toolchain.mingw.source_dir"), "mingw-w64-crt"))
        target:set("toolchain.mingw.winpthread.dll_name", "libwinpthread-1.dll")
        target:set("toolchain.cross.mingw.build_dir", path.join(toolchain_env:get("toolchain.cross.build_dir"), package_info.dirname))
        target:set("toolchain.cross.mingw.headers.build_dir", path.join(target:get("toolchain.cross.mingw.build_dir"), "headers"))
        target:set("toolchain.cross.mingw.crt.build_dir", path.join(target:get("toolchain.cross.mingw.build_dir"), "crt")) 
        target:set("toolchain.cross.mingw.crt.install_flag", path.join(target:get("toolchain.cross.mingw.crt.build_dir"), "crt-installed"))
        target:set("toolchain.cross.mingw.winpthread.build_dir", path.join(target:get("toolchain.cross.mingw.build_dir"), "winpthread")) 
        target:set("toolchain.cross.mingw.winpthread.libwinpthread", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target"), "lib", "libwinpthread.a"))
        target:set("toolchain.cross_native.mingw.build_dir", path.join(toolchain_env:get("toolchain.cross_native.build_dir"), package_info.dirname))
        target:set("toolchain.cross_native.mingw.winpthread_dll", path.join(toolchain_env:get("toolchain.cross_native.prefix"), "bin", target:get("toolchain.mingw.winpthread.dll_name")))
        target:set("toolchain.cross_native.mingw.install_flag", path.join(target:get("toolchain.cross_native.mingw.build_dir"), "mingw-installed"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.source.mingw: ", package_info)
            print("toolchain.mingw.source_dir: ", target:get("toolchain.mingw.source_dir"))
            print("toolchain.mingw.headers.source_dir: ", target:get("toolchain.mingw.headers.source_dir"))
            print("toolchain.mingw.headers.link: ", target:get("toolchain.mingw.headers.link"))
            print("toolchain.mingw.crt.source_dir: ", target:get("toolchain.mingw.crt.source_dir"))
            print("toolchain.mingw.winpthread.dll_name: ", target:get("toolchain.mingw.winpthread.dll_name"))
            print("toolchain.cross.mingw.build_dir: ", target:get("toolchain.cross.mingw.build_dir"))
            print("toolchain.cross.mingw.headers.build_dir: ", target:get("toolchain.cross.mingw.headers.build_dir"))
            print("toolchain.cross.mingw.crt.build_dir: ", target:get("toolchain.cross.mingw.crt.build_dir"))
            print("toolchain.cross.mingw.crt.install_flag: ", target:get("toolchain.cross.mingw.crt.install_flag"))
            print("toolchain.cross.mingw.winpthread.build_dir: ", target:get("toolchain.cross.mingw.winpthread.build_dir"))
            print("toolchain.cross.mingw.winpthread.libwinpthread: ", target:get("toolchain.cross.mingw.winpthread.libwinpthread"))
            print("toolchain.cross_native.mingw.build_dir: ", target:get("toolchain.cross_native.mingw.build_dir"))
            print("toolchain.cross_native.mingw.winpthread_dll: ", target:get("toolchain.cross_native.mingw.winpthread_dll"))
            print("toolchain.cross_native.mingw.install_flag: ", target:get("toolchain.cross_native.mingw.install_flag"))
        end
    end)

target("mingw-download")
    set_default(false)
    set_kind("phony")
    add_deps("mingw-env")
    on_build(function (target)
        import("core.project.project")
        import("package")
        local toolchain_env = project.target("toolchain-env")
        local package_env = project.target("toolchain-package-env")
        package.download(package_env:get("toolchain.source.mingw"), toolchain_env:get("toolchain.source_dir"))
        package.patch(package_env:get("toolchain.source.mingw"), toolchain_env:get("toolchain.source_dir"))
    end)

target("mingw-cross-headers-install")
    set_default(false)
    set_kind("phony")
    add_deps("mingw-download")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local mingw_env = project.target("mingw-env")
        local mingw_header_link = path.join(toolchain_env:get("toolchain.cross.prefix"), mingw_env:get("toolchain.mingw.headers.link"))
        if os.exists(mingw_header_link) then
            print("cross mingw libc header has already installed: ", mingw_header_link)
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-default-msvcrt=msvcrt"
        }
        os.vrun("mkdir -p " .. mingw_env:get("toolchain.cross.mingw.headers.build_dir"))
        os.cd(mingw_env:get("toolchain.cross.mingw.headers.build_dir"))
        os.vrunv(path.join(mingw_env:get("toolchain.mingw.headers.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install -j")
        os.cd(toolchain_env:get("toolchain.cross.prefix"))
        os.ln(toolchain_env:get("toolchain.cross.target"), mingw_env:get("toolchain.mingw.headers.link"))
    end)

target("mingw-cross-crt-build")
    set_default(false)
    set_kind("phony")
    add_deps("mingw-download")
    add_deps("mingw-cross-headers-install")
    add_deps("gcc-cross-bootstrap-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local mingw_env = project.target("mingw-env")
        if os.exists(mingw_env:get("toolchain.cross.mingw.crt.install_flag")) then 
            print("cross mingw crt has already built: ", mingw_env:get("toolchain.cross.mingw.crt.install_flag"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-default-msvcrt=msvcrt",
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc")
        }
        os.vrun("mkdir -p " .. mingw_env:get("toolchain.cross.mingw.crt.build_dir"))
        os.cd(mingw_env:get("toolchain.cross.mingw.crt.build_dir"))
        os.vrunv(path.join(mingw_env:get("toolchain.mingw.crt.source_dir"), "configure"), argv)
        os.exec("make")
        os.exec("make install-strip -j")
        io.open(mingw_env:get("toolchain.cross.mingw.crt.install_flag"), "w")
    end)

target("mingw-cross-winpthread-build")
    set_default(false)
    set_kind("phony")
    add_deps("mingw-download")
    add_deps("mingw-cross-headers-install")
    add_deps("mingw-cross-crt-build")
    add_deps("gcc-cross-bootstrap-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local mingw_env = project.target("mingw-env")
        if os.exists(mingw_env:get("toolchain.cross.mingw.winpthread.libwinpthread")) then
            print("cross mingw libwinpthread has already built: ", mingw_env:get("toolchain.cross.mingw.winpthread.libwinpthread"))
            return
        end
        local argv = {
            "--prefix=" .. path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--without-crt",
            "--without-headers",
            "--with-libraries=winpthreads",
            "CC=" .. gcc_env:get("toolchain.cross.gcc.cc")
        }
        os.vrun("mkdir -p " .. mingw_env:get("toolchain.cross.mingw.winpthread.build_dir"))
        os.cd(mingw_env:get("toolchain.cross.mingw.winpthread.build_dir"))
        os.vrunv(path.join(mingw_env:get("toolchain.mingw.source_dir"), "configure"), argv)
        os.exec("make")
        os.exec("make install-strip -j")
    end)

target("mingw-cross-native-build")
    set_default(false)
    set_kind("phony")
    add_deps("mingw-download")
    add_deps("gcc-cross-final-build")
    on_build(function (target)
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        local gcc_env = project.target("gcc-env")
        local mingw_env = project.target("mingw-env")
        if os.exists(mingw_env:get("toolchain.cross_native.mingw.install_flag")) then 
            print("cross native mingw has already built: ", mingw_env:get("toolchain.cross_native.mingw.install_flag"))
            return
        end
        local argv = {
            "--prefix=" .. toolchain_env:get("toolchain.cross_native.prefix"),
            "--host=" .. toolchain_env:get("toolchain.cross.target"),
            "--with-default-msvcrt=msvcrt",
            "--with-libraries=all",
            "--with-tools=all"
        }
        os.vrun("mkdir -p " .. mingw_env:get("toolchain.cross_native.mingw.build_dir"))
        os.cd(mingw_env:get("toolchain.cross_native.mingw.build_dir"))
        os.vrunv(path.join(mingw_env:get("toolchain.mingw.source_dir"), "configure"), argv)
        os.exec("make -j")
        os.exec("make install-strip -j")
        io.open(mingw_env:get("toolchain.cross_native.mingw.install_flag"), "w")
    end)
