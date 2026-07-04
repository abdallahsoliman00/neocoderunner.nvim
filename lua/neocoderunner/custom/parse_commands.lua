require("neocoderunner.types.Runner")
local utils = require("neocoderunner.utils")

local function get_runners_dir()
    return vim.fn.getcwd() .. "/.ncrunner"
end

local function get_runners_file()
    return get_runners_dir() .. "/runners.json"
end


--- Reads the runners.json file and returns the content
---@return table | nil
local function read_runners_file()
    local runners_file = get_runners_file()
    local file = io.open(runners_file, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()

    -- Parse the JSON string into a usable Lua table
    local data = vim.json.decode(content)
    return data
end

--- Normalizes a raw runner entry (string or table) into a Runner
---@param raw table|string
---@return Runner
local function normalise_runner(raw)
    local fileinfo = require("neocoderunner.utils").get_current_file_info()
    local replacements = { fileName = fileinfo.basename, filePath = fileinfo.relative }

    if type(raw) == "string" then
        return { build = nil, run = utils.resolve_placeholders(raw, replacements) }
    end
    return { build = utils.resolve_placeholders(raw.build, replacements), run = utils.resolve_placeholders(raw.run, replacements) }
end


local M = {}

--- Returns a table of runners by parsing the runners.json command
---@return table<Runner>
M.get_runners = function()
    local data = read_runners_file()
    if data == nil then return {} end

    -- This line makes it possible for the user to either put the runners in a "runners" entry,
    -- or just put the runners as the entire content of the json
    local runners = data.runners ~= nil and data.runners or data
    local out = {}
    for lang, runner in pairs(runners) do
        out[lang] = normalise_runner(runner)
    end

    return out
end

-- Returns the directory to run from, defined in the runners.json file
-- If a runners.json file is defined, but without an env section, then the cwd is returned
-- If it is not defined, the directory where the current file is located is returned
---@return string
M.get_cwd = function()
    local runners_file = get_runners_file()
    if vim.uv.fs_stat(runners_file) then
        local runners_content = read_runners_file()
        if runners_content and runners_content["env"] and runners_content["env"].cd then
            return utils.resolve_placeholders(runners_content["env"].cd, { cwd = vim.fn.getcwd() })
        else
            return vim.fn.getcwd()
        end
    else
        return vim.fn.expand("%:p:h")
    end
end
return M
