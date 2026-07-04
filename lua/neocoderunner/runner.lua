--- The functions in this module are the ones that are directly used by user-commands.lua

local custom = require("neocoderunner.custom.commands")
local default = require("neocoderunner.default.commands")
local get_cwd = require("neocoderunner.custom.parse_commands").get_cwd
local run = require("neocoderunner.utils").run

local M = {}

M.run_partial_build = function()
    local cwd = get_cwd()

    local run_cmd = custom.get_build_command()
    if run_cmd then
        run(run_cmd, cwd, function() end)
    end
end

M.run_partial_run = function()
    local cwd = get_cwd()

    local run_cmd = custom.get_run_command()
    if run_cmd then
        run(run_cmd, cwd, function() end)
    end
end

M.run_current_file = function()
    local cwd = get_cwd()

    local run_cmd = custom.get_current_file_command()
    if run_cmd then
        run(run_cmd, cwd, function() end)
    end
end

M.run_code_snippet = function()
    local run_cmd = default.get_code_snippet_run_command()
    if run_cmd then
        run(run_cmd, nil, function()
            default.delete_temp_files()
        end)
    end
end

return M

