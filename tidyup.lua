-- Requires LuaFileSystem and md5 libraries
-- Install via luarocks: luarocks install luafilesystem md5

local lfs = require("lfs")
local md5 = require("md5")

local root = "wallpapers"

-- Store seen hashes to detect duplicates
local seen = {}

-- Helper: compute MD5 of a file
local function file_hash(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*all")
    f:close()
    return md5.sumhexa(data)
end

-- Helper: check if file looks like an image
local function is_image_file(filename)
    local ext = filename:match("^.+%.([^%.]+)$")
    if not ext then return false end
    ext = ext:lower()
    return (ext == "jpg" or ext == "jpeg" or ext == "png" or ext == "webp" or ext == "bmp")
end

-- Recursively walk through folders
local function process_dir(dir)
    for entry in lfs.dir(dir) do
        if entry ~= "." and entry ~= ".." then
            local path = dir .. "/" .. entry
            local attr = lfs.attributes(path)
            if attr.mode == "directory" then
                -- Recurse into subfolder
                process_dir(path)
            elseif attr.mode == "file" and is_image_file(entry) then
                local hash = file_hash(path)
                if hash and not seen[hash] then
                    -- Unique wallpaper -> move it to root
                    local dest = root .. "/" .. entry

                    -- Avoid filename clashes
                    local base, ext = entry:match("(.+)%.([^%.]+)$")
                    local counter = 1
                    while lfs.attributes(dest) do
                        dest = root .. "/" .. base .. "_" .. counter .. "." .. ext
                        counter = counter + 1
                    end

                    os.rename(path, dest)
                    seen[hash] = true
                else
                    -- Duplicate -> remove
                    os.remove(path)
                end
            end
        end
    end
end

-- Start
process_dir(root)

-- Cleanup: remove empty folders
local function remove_empty_dirs(dir)
    for entry in lfs.dir(dir) do
        if entry ~= "." and entry ~= ".." then
            local path = dir .. "/" .. entry
            local attr = lfs.attributes(path)
            if attr.mode == "directory" then
                remove_empty_dirs(path)
                -- Try removing (only works if empty)
                os.remove(path)
            end
        end
    end
end

remove_empty_dirs(root)

print("Done! Unique wallpapers are now in '" .. root .. "'")

