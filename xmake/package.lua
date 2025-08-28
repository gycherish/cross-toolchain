import("devel.git")
import("utils.archive")
import("net.http")

function download(package, out_dir)
    local package_dir = path.join(out_dir, package.dirname)
    local has_downloaded_flag = path.join(package_dir, "__toolchain_downloaded__")
    if os.exists(has_downloaded_flag) then
        print("package already downloaded: ", package_dir)
        return
    end

    print("downloading package: ", package.url)
    if package.url:match("%.git$") then
        -- remove package directory avoid git clone error
        if os.exists(package_dir) then
            os.rmdir(package_dir)
        end
        git.clone(package.url, {
            depth = 1, 
            branch = package.branch,
            outputdir = package_dir
        })
    else
        local tarball = path.join(out_dir, path.filename(package.url))
        try {
            function ()
                -- perhaps an tarball file already exists, try to extract it
                if os.exists(tarball) then
                    print("tarball already exists, try extract it: ", tarball)
                    archive.extract(tarball, out_dir)
                else
                    raise("tarball not found: " .. tarball)
                end
            end,
            catch {
                function (errors)
                    -- remove package directory if tarball extract failed
                    if os.exists(package_dir) then
                        os.rmdir(package_dir)
                    end
                    http.download(package.url, tarball)
                    archive.extract(tarball, out_dir)
                end
            }
        }
    end

    os.touch(has_downloaded_flag)
    print("package downloaded: ", package_dir)
end

function patch(package, out_dir)
    local package_dir = path.join(out_dir, package.dirname)
    local has_patched_flag = path.join(package_dir, "__toolchain_pactched__")
    if os.exists(has_patched_flag) then
        print("package already patched: ", package_dir)
        return
    end

    local prjdir = vformat("$(projectdir)")
    for _, patch in ipairs(package.patches) do
        local patch_file = path.join(prjdir, "patches", patch)
        if not os.exists(patch_file) then
            raise("patch file not found: ", patch_file)
        end
        print("applying patch: ", patch_file, " to ", package_dir)
        git.apply(patch_file, {repodir = package_dir})
    end

    os.touch(has_patched_flag)
    print("package patched: ", package_dir)
end

function copy(copyfunc, out_dir)
    local has_copy_flags = path.join(out_dir, "__toolchain_copied__")
    if os.exists(has_copy_flags) then
        print("package files already copied: ", out_dir)
        return
    end
    copyfunc();
    os.touch(has_copy_flags)
    print("package files copied: ", out_dir)
end
