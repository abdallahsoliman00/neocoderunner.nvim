local languages = require("neocoderunner.default.languages")

local runners_dir = vim.fn.getcwd() .. "/.ncrunner"
local runners_file = runners_dir .. "/runners.json"

local function get_file_contents()
    local parts = {}
    for _, name in ipairs(languages.order) do
        local lang = languages[name]
        table.insert(parts, string.format('    "%s": "%s"', name, lang.runner("${filePath}", "${fileName}")))
    end
    return "{\n" .. table.concat(parts, ",\n") .. "\n}"
end

local M = {}

--- Creates a runners.json file where the different run commands can be edited.
M.init_ncrunner_file = function()
    if vim.uv.fs_stat(runners_file) then
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

