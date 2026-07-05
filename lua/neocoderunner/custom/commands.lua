require("neocoderunner.types.Runner")
require("neocoderunner.types.Language")

local utils = require("neocoderunner.utils")
local default = require("neocoderunner.default.commands")
local parse = require("neocoderunner.custom.parse_commands")

---@param str string | nil
---@return string | nil
local function trim(str)
    if str == nil then return nil end
    return (str:match("^%s*(.-)%s*$"))
end

---@param runner string | Runner | nil
---@return string | Runner | nil
local function strip(runner)
    if runner == nil then return nil end
    if type(runner) == "string" then
        return trim(runner)
    end
    return { build = trim(runner.build), run = trim(runner.run) }
end

--- Checks if the runner object contains a runnable command
---@param runner Runner | string | nil
---@return boolean
local function runner_empty(runner)
    if runner == nil then return true end
    if type(runner) == "string" then
        return runner == ""
    else
        return (runner.build or "") == "" and (runner.run or "") == ""
    end
end

--- Returns the runner for the current filetype from the runners.json
--- returns nil if no runner is defined
---@return Runner | nil
local function get_runner()
    local f_info = utils.get_current_file_info()
    local runners = parse.get_runners()

    -- Check if global exists and return it
    if not runner_empty(strip(runners["global"])) then
        return runners["global"]
    end

    -- Otherwise return the runner or the default if that also isn't defined
    if runners[f_info.type] ~= nil and strip(runners[f_info.type]) ~= "" then
        return runners[f_info.type]
    else
        return default.get_run_command()
    end
end

local M = {}

--- This gets called by the partial build/compile user command
---@return string | nil
M.get_build_command = function()
    local runner = get_runner()
    if runner ~= nil and runner.build ~= nil then
        return runner.build
    else
        vim.notify(
            "No build command defined for filetype " .. utils.get_current_file_info().type,
            vim.log.levels.WARN
        )
        return
    end
end

--- This gets called by the partial run user command
---@return string | nil
M.get_run_command = function()
    local runner = get_runner()
    if runner ~= nil then
        return runner.run
    else
        vim.notify(
            "No runner defined for filetype " .. utils.get_current_file_info().type,
            vim.log.levels.WARN
        )
        return
    end
end

---@return string | nil
M.get_full_command = function()
    local runner = get_runner()
    local sep = vim.o.shell:lower():find("powershell") and " ; " or " && "

    if runner ~= nil then
        if runner.build ~= nil then
            return runner.build .. sep .. runner.run
        else
            return runner.run
        end
    else
        vim.notify(
            "No runner defined for filetype " .. utils.get_current_file_info().type,
            vim.log.levels.WARN
        )
        return
    end
end

--- This gets called by the main user command
---@return string | nil
M.get_current_file_command = function ()
    local custom_defined = utils.runners_file_exists() and get_runner() ~= nil

    -- If no commands are defined, use the default runners
    if not custom_defined then
        return default.get_run_command()
    end

    return M.get_full_command()
end

return M
