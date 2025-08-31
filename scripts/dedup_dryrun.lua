-- Dry-run version: only prints actions, does not modify anything
-- Requires LuaFileSystem and md5
-- Install via luarocks: luarocks install luafilesystem md5

local lfs = require("lfs")
local md5 = require("md5")

local root = "wallpapers"
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
                process_dir(path)
            elseif attr.mode == "file" and is_image_file(entry) then
                local hash = file_hash(path)
                if hash and not seen[hash] then
                    -- Unique wallpaper -> would move it to root
                    local dest = root .. "/" .. entry
                    local base, ext = entry:match("(.+)%.([^%.]+)$")
                    local counter = 1
                    while lfs.attributes(dest) do
                        dest = root .. "/" .. base .. "_" .. counter .. "." .. ext
                        counter = counter + 1
                    end
                    print("[MOVE] " .. path .. " -> " .. dest)
                    seen[hash] = true
                else
                    -- Duplicate -> would remove
                    print("[DELETE DUPLICATE] " .. path)
                end
            end
        end
    end
end

-- Cleanup pass for empty folders
local function remove_empty_dirs(dir)
    for entry in lfs.dir(dir) do
        if entry ~= "." and entry ~= ".." then
            local path = dir .. "/" .. entry
            local attr = lfs.attributes(path)
            if attr.mode == "directory" then
                remove_empty_dirs(path)
                print("[REMOVE EMPTY DIR] " .. path)
            end
        end
    end
end

-- Run dry-run
process_dir(root)
remove_empty_dirs(root)

print("Dry run complete. No changes made.")

