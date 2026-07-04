require("neocoderunner.types.Runner")
require("neocoderunner.types.Language")

local utils = require("neocoderunner.utils")
local default = require("neocoderunner.default.commands")
local parse = require("neocoderunner.custom.parse_commands")

--- Returns the runner for the current filetype from the runners.json
--- returns nil if no runner is defined
---@return Runner | nil
local function get_runner()
    local f_info = utils.get_current_file_info()
    return parse.get_runners()[f_info.type]
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
