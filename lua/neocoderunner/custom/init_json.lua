local languages = require("neocoderunner.default.languages")
local utils = require("neocoderunner.utils")

require("neocoderunner.types.Runner")

local function get_runners_dir()
    return vim.fn.getcwd() .. "/.ncrunner"
end

local function get_runners_file()
    return get_runners_dir() .. "/runners.json"
end

--- Escapes a string so it can be safely embedded in a json string
---@param str string
---@return string
local function escape_json_string(str)
    local escapes = {
        ['"'] = '\\"',
        ["\\"] = "\\\\",
        ["\b"] = "\\b",
        ["\f"] = "\\f",
        ["\n"] = "\\n",
        ["\r"] = "\\r",
        ["\t"] = "\\t",
    }
    return (str:gsub('[%c"\\]', function(c)
        return escapes[c] or string.format("\\u%04x", c:byte())
    end))
end

--- Takes in a lang and its @Runner type and returns the corresponding json entry
---@param lang string
---@param runner Runner|nil
---@return string
local function write_runner_as_json(lang, runner)
    if runner == nil then
        return string.format('        "%s": ""',
        escape_json_string(lang)
    )
    end
    if runner.build ~= nil and runner.build ~= "" then
        return string.format(
            '        "%s": {\n            "build": "%s",\n            "run": "%s"\n        }',
            escape_json_string(lang),
            escape_json_string(runner.build),
            escape_json_string(runner.run)
        )
    end
    return string.format('        "%s": "%s"', escape_json_string(lang), escape_json_string(runner.run))
end

local function get_file_contents()
    local env_section = [[
    "env": {
        "cd": "${cwd}",
        "export": {},
        "scripts": []
    },
]]
    local parts = {}
    local default_runners = require("neocoderunner").config.default_runners
    for _, name in ipairs(languages.order) do
        local runner = nil
        if default_runners ~= nil and default_runners[name] ~= nil then
            runner = utils.to_runner(default_runners[name])
        end
        if runner == nil then
            runner = utils.to_runner(languages[name].runner("${filePath}", "${fileName}"))
        end
        table.insert(parts, write_runner_as_json(name, runner))
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
        print("File already exists. To override the current file, please provide 'override' or 'o' as an argument to the :InitRunnerConfig command.")
        vim.cmd("edit " .. vim.fn.fnameescape(runners_file))
    else
        vim.fn.mkdir(runners_dir, "p")
        local file, err = io.open(runners_file, "w")
        if file then
            local file_contents = get_file_contents()
            file:write(file_contents)
            file:close()
            vim.notify("Success: File created at " .. runners_file, vim.log.levels.INFO)
            -- Open in new buffer
            vim.cmd("edit " .. vim.fn.fnameescape(runners_file))
        else
            vim.notify("Error creating file: " .. tostring(err), vim.log.levels.ERROR)
        end
    end
end

return M
