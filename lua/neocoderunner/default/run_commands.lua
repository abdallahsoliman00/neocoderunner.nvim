--- The functions in this module are the ones that are diectly used by the autocmds

local custom = require("neocoderunner.custom.commands")
local default = require("neocoderunner.default.commands")
local run = require("neocoderunner.utils").run

local M = {}

M.run_partial_build = function ()
    local run_cmd = custom.get_build_command()
    if run_cmd then
        run(run_cmd, function() end)
    end
end

M.run_partial_run = function ()
    local run_cmd = custom.get_run_command()
    if run_cmd then
        run(run_cmd, function() end)
    end
end

M.run_current_file = function()
    local run_cmd = custom.get_current_file_command()
    if run_cmd then
        run(run_cmd, function() end)
    end
end

M.run_code_snippet = function()
    local run_cmd = default.get_code_snippet_run_command()
    if run_cmd then
        run(run_cmd, function()
            default.delete_temp_files()
        end)
    end
end

return M

