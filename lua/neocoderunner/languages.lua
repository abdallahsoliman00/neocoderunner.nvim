local sep = vim.o.shell:lower():find("powershell") and " ; " or " && "
local exe_ext = jit.os == "Windows" and ".exe" or ""

return {
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
            return "python -u " .. fullpath
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
}
