target("linux-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.linux.url", "https://github.com/torvalds/linux.git")
        target:set("toolchain.linux.branch", "v6.11")
        target:set("toolchain.linux.version", "6.11")
        target:set("toolchain.linux.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "linux-6.11"))
        target:set("toolchain.cross.linux.install_dir", path.join(toolchain_env:get("toolchain.cross.prefix"), toolchain_env:get("toolchain.cross.target")))
        target:set("toolchain.cross.linux.install_header_dir", path.join(target:get("toolchain.cross.linux.install_dir"), "include", "linux"))
        local arch = get_config("Arch")
        arch = arch:gsub("i%d+86", "x86"):gsub("aarch", "arm"):gsub("loongarch64", "loongarch")
        target:set("toolchain.cross.linux.arch", arch)
        target:set("toolchain.cross_native.linux.install_dir", toolchain_env:get("toolchain.cross_native.sysroot.usr"))
        target:set("toolchain.cross_native.linux.install_header_dir", path.join(target:get("toolchain.cross_native.linux.install_dir"), "include", "linux"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.linux.url: ", target:get("toolchain.linux.url"))
            print("toolchain.linux.branch: ", target:get("toolchain.linux.branch"))
            print("toolchain.linux.version: ", target:get("toolchain.linux.version"))
            print("toolchain.linux.source_dir: ", target:get("toolchain.linux.source_dir"))
            print("toolchain.cross.linux.arch: ", target:get("toolchain.cross.linux.arch"))
            print("toolchain.cross.linux.install_dir: ", target:get("toolchain.cross.linux.install_dir"))
            print("toolchain.cross.linux.install_header_dir: ", target:get("toolchain.cross.linux.install_header_dir"))
            print("toolchain.cross_native.linux.install_dir: ", target:get("toolchain.cross_native.linux.install_dir"))
            print("toolchain.cross_native.linux.install_header_dir: ", target:get("toolchain.cross_native.linux.install_header_dir"))
        end
    end)

target("linux-download")
    set_default(false)
    set_kind("phony")
    add_deps("linux-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local linux_env = project.target("linux-env")
        if os.exists(linux_env:get("toolchain.linux.source_dir")) then
            print("linux kernel source code has already existed: ", linux_env:get("toolchain.linux.source_dir"))
            return
        end
        git.clone(linux_env:get("toolchain.linux.url"), {
            depth = 1, 
            branch = linux_env:get("toolchain.linux.branch"), 
            outputdir = linux_env:get("toolchain.linux.source_dir")
        })
    end)

target("linux-cross-header-install")
    set_default(false)
    set_kind("phony")
    add_deps("linux-download")
    on_build(function (target)
        import("core.project.project")
        local linux_env = project.target("linux-env")
        if os.exists(linux_env:get("toolchain.cross.linux.install_header_dir")) then
            print("cross linux header has already installed: ", linux_env:get("toolchain.cross.linux.install_header_dir"))
            return
        end
        local argv = {
            "headers_install",
            "ARCH=" .. linux_env:get("toolchain.cross.linux.arch"),
            "INSTALL_HDR_PATH=" .. linux_env:get("toolchain.cross.linux.install_dir")
        }
        os.cd(linux_env:get("toolchain.linux.source_dir"))
        os.exec("make defconfig ARCH=" .. linux_env:get("toolchain.cross.linux.arch"))
        os.execv("make", argv)
    end)

target("linux-cross-native-header-install")
    set_default(false)
    set_kind("phony")
    add_deps("linux-cross-header-install")
    on_build(function (target)
        import("core.project.project")
        local linux_env = project.target("linux-env")
        if os.exists(linux_env:get("toolchain.cross_native.linux.install_header_dir")) then
            print("cross native linux header has already installed: ", linux_env:get("toolchain.cross_native.linux.install_header_dir"))
            return
        end
        local argv = {
            "headers_install",
            "ARCH=" .. linux_env:get("toolchain.cross.linux.arch"),
            "INSTALL_HDR_PATH=" .. linux_env:get("toolchain.cross_native.linux.install_dir")
        }
        os.cd(linux_env:get("toolchain.linux.source_dir"))
        os.exec("make defconfig ARCH=" .. linux_env:get("toolchain.cross.linux.arch"))
        os.execv("make", argv)
    end)
