target("config-env")
    set_default(false)
    set_kind("phony")
    add_deps("toolchain-env")
    on_build(function (target) 
        import("core.project.project")
        local toolchain_env = project.target("toolchain-env")
        target:set("toolchain.config.url", "https://git.savannah.gnu.org/git/config.git")
        target:set("toolchain.config.branch", "master")
        target:set("toolchain.config.source_dir", path.join(toolchain_env:get("toolchain.source_dir"), "config-master"))
        target:set("toolchain.config.sub", path.join(target:get("toolchain.config.source_dir"), "config.sub"))
        target:set("toolchain.config.guess", path.join(target:get("toolchain.config.source_dir"), "config.guess"))

        import("core.base.option")
        if option.get("verbose") then
            print("toolchain.config.url: ", target:get("toolchain.config.url"))
            print("toolchain.config.branch: ", target:get("toolchain.config.branch"))
            print("toolchain.config.source_dir: ", target:get("toolchain.config.source_dir"))
            print("toolchain.config.sub: ", target:get("toolchain.config.sub"))
            print("toolchain.config.guess: ", target:get("toolchain.config.guess"))
        end
    end)

target("config-download")
    set_default(false)
    set_kind("phony")
    add_deps("config-env")
    on_build(function (target)
        import("devel.git")
        import("core.project.project")
        local config_env = project.target("config-env")
        if os.exists(config_env:get("toolchain.config.source_dir")) then
            print("config source code has already existed: ", config_env:get("toolchain.config.source_dir"))
            return
        end
        git.clone(config_env:get("toolchain.config.url"), {
            depth = 1, 
            branch = config_env:get("toolchain.config.branch"),
            outputdir = config_env:get("toolchain.config.source_dir")
        })
    end)
