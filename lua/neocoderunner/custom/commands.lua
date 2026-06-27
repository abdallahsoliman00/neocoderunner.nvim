local utils = require("neocoderunner.utils")
local default = require("neocoderunner.default.commands")
local parse = require("neocoderunner.custom.parse_commands")

local M = {}

M.get_build_command = function ()
end

M.get_run_command = function()
end

M.get_full_command = function ()
end

M.get_current_file_command = function ()
    local custom_defined = utils.runners_file_exists()
    -- local f_info = utils.get_current_file_info()

    -- If no commands are defined, use the default runners
    if not custom_defined then
        return default.get_run_command()
    end

    -- If commands are defined, but are one liners, execute them using the run_full_command

    -- If commands are defined and are defined and are defined in build and run sections, run the build command followed by the run command
end

return M
