local default_config = require("neocoderunner.config")
local commands = require("neocoderunner.commands")


local M = {}

M.config = default_config

M.setup = function(user_config)
	M.config = vim.tbl_deep_extend("force", default_config, user_config or {})

    commands.setup()
end

return M
