local languages = require("neocoderunner.default.languages")

local function get_runners_dir()
    return vim.fn.getcwd() .. "/.ncrunner"
end

local function get_runners_file()
    return get_runners_dir() .. "/runners.json"
end

local function get_file_contents()
    local env_section = [[
    "env": {
        "cd": "${cwd}",
        "export": {}
    },
]]
    local parts = {}
    for _, name in ipairs(languages.order) do
        local lang = languages[name]
        table.insert(parts, string.format('        "%s": "%s"', name, lang.runner("${filePath}", "${fileName}")))
    end
    local runners_section = '    "runners": {\n' .. table.concat(parts, ",\n") .. '\n    }'
    return "{\n" .. env_section .. runners_section .. "\n}"
end

local M = {}

--- Creates a runners.json file where the different run commands can be edited.
---@param override boolean
M.init_ncrunner_file = function(override)
    local runners_dir = get_runners_dir()
    local runners_file = get_runners_file()
    if vim.uv.fs_stat(runners_file) and not override then
        print("File already exists.")
    else
        vim.fn.mkdir(runners_dir, "p")
        local file, err = io.open(runners_file, "w")
        if file then
            local file_contents = get_file_contents()
            file:write(file_contents)
            file:close()
            vim.notify("Success: File created at " .. runners_file, vim.log.levels.INFO)
        else
            vim.notify("Error creating file: " .. tostring(err), vim.log.levels.ERROR)
        end
    end
end

return M

