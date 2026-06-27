local run_commands = require("neocoderunner.default.run_commands")
local init_commands = require("neocoderunner.custom.init_runners")

local M = {}

M.setup = function()

    vim.api.nvim_create_user_command("InitRunnerConfig", function()
        init_commands.init_ncrunner_file()
    end, {
        nargs = 0,
        desc = "Initialises the .ncrunner directory with a runners.json containing the default run command for each filetype.",
    })

    vim.api.nvim_create_user_command("NCRunnerBuild", function()
        run_commands.run_partial_build()
    end, {
        nargs = 0,
        desc = "Runs the compile/build command defined in the runners.json file.",
    })

    vim.api.nvim_create_user_command("NCRunnerRun", function()
        run_commands.run_partial_run()
    end, {
        nargs = 0,
        desc = "Runs the run command defined in the runners.json file.",
    })

    vim.api.nvim_create_user_command("RunCurrentFile", function()
        run_commands.run_current_file()
    end, {
        nargs = 0,
        desc = "Runs the file in the active buffer in a split. This will either run both compile and run commands if they exist, or will run the full runner line.",
    })

    vim.api.nvim_create_user_command("RunCodeSnippet", function(opts)
        if opts.range > 0 then
            local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
            local snippet = table.concat(lines, "\n")

            if snippet == "" then
                vim.notify("No code selected to run.", vim.log.levels.WARN)
                return
            end

            run_commands.run_code_snippet()
            return
        end

        run_commands.run_code_snippet()
    end, { nargs = 0, range = true, desc = "Runs the highlighted code in a split." })

end

return M
