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


local M = {}

--- Returns a table of runners by parsing the runners.json command
---@return Runners
M.get_runners = function()
    local data = read_runners_file()
    if data == nil then return {} end

    -- This line makes it possible for the user to either put the runners in a "runners" entry,
    -- or just put the runners as the entire content of the json
    local runners = data.runners ~= nil and data.runners or data
    local out = {}
    for lang, runner in pairs(runners) do
        out[lang] = utils.normalise_runner(runner)
    end

    return out
end

---@class env
---@field export table<string,string> | nil
---@field scripts table<string> | nil
---@field cwd string | nil

--- Returns the environment state in which teh commands ar to be run
---@return env
M.get_env = function()
    local runners_file = get_runners_file()
    local out = {}
    if vim.uv.fs_stat(runners_file) then
        local runners_content = read_runners_file()
        if runners_content and runners_content["env"] and runners_content["env"].export then
            out.export = runners_content["env"].export
        else
            out.export = nil
        end

        if runners_content and runners_content["env"] and runners_content["env"].scripts then
            out.scripts = runners_content["env"].scripts
            out.scripts = utils.resolve_placeholders(runners_content["env"].scripts, { cwd = vim.fn.getcwd() })
        else
            out.scripts = nil
        end

        if runners_content and runners_content["env"] and runners_content["env"].cd then
            out.cwd = utils.resolve_placeholders(runners_content["env"].cd, { cwd = vim.fn.getcwd() })
        else
            out.cwd = vim.fn.getcwd()
        end
    else
        out.cwd = vim.fn.expand("%:p:h")
    end
    return out
end

return M
