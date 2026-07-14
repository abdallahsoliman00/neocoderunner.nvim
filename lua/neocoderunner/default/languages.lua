require("neocoderunner.types.Language")

local sep = vim.o.shell:lower():find("powershell") and " ; " or " && "
local exe_ext = jit.os == "Windows" and ".exe" or ""

---@type Languages
local languages = {
    c = {
        extensions = { "c", "h" },
        runner = function(fullpath, basename)
            return "gcc -o " .. basename .. " " .. fullpath .. sep .. "./" .. basename .. exe_ext
        end,
    },
    cpp = {
        extensions = { "cpp", "cc", "cxx", "hpp" },
        runner = function(fullpath, basename)
            return "g++ -o " .. basename .. " " .. fullpath .. sep .. "./" .. basename .. exe_ext
        end,
    },
    lua = {
        extensions = { "lua" },
        runner = function(fullpath)
            return "lua " .. fullpath
        end,
    },
    python = {
        extensions = { "py" },
        runner = function(fullpath)
            if jit.os == "Windows" then
                return "python -u " .. fullpath
            else
                return "python3 -u " .. fullpath
            end
        end,
    },
    rust = {
        extensions = { "rs" },
        runner = function(fullpath, basename)
            return "rustc " .. fullpath .. sep .. "./" .. basename .. exe_ext
        end,
    },
    javascript = {
        extensions = { "js" },
        runner = function(fullpath)
            return "node " .. fullpath
        end,
    },
    typescript = {
        extensions = { "ts" },
        runner = function(fullpath)
            return "npx tsx " .. fullpath
        end,
    },
    perl = {
        extensions = { "pl" },
        runner = function(fullpath)
            return "perl " .. fullpath
        end,
    },
    go = {
        extensions = { "go" },
        runner = function(fullpath)
            return "go run " .. fullpath
        end,
    },
    php = {
        extensions = { "php" },
        headers = { "<?php" },
        runner = function(fullpath)
            return "php " .. fullpath
        end,
    },
    zig = {
        extensions = { "zig" },
        runner = function(fullpath)
            return "zig run " .. fullpath
        end
    },
    -- This is left empty on purpose for the user to define in the runners.json file
    global = {
        extensions = {},
        runner = function()
            return ""
        end
    },
    -- Don't forget to add new languages to the order table below
    order = {
        "global", "c", "cpp", "lua", "python", "rust",
        "javascript", "typescript", "perl", "go", "php",
        "zig",
    }
}

return languages
