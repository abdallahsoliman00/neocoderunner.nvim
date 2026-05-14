local run_commands = require("neocoderunner.run_commands")

local M = {}

M.setup = function()
    vim.api.nvim_create_user_command("RunCurrentFile", function()
        run_commands.run_current_file()
    end, { nargs = 0, desc = "Runs the file in the active buffer in a split." })

    vim.api.nvim_create_user_command("RunCodeSnippet", function(opts)
        if opts.range > 0 then
            local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
            local snippet = table.concat(lines, "\n")

            if snippet == "" then
                vim.notify("No code selected to run.", vim.log.levels.WARN)
                return
            end

            run_commands.run_code_snippet(snippet)
            return
        end

        run_commands.run_code_snippet()
    end, { nargs = 0, range = true, desc = "Runs the highlighted code in a split." })
end

return M
