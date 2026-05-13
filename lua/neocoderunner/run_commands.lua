local utils = require("neocoderunner.utils")
local languages = require("neocoderunner.languages")
local config = require("neocoderunner").config

local tempfile_name = "neocoderunner_tempfile"

--- Gets the run command for the current file
---@return string | nil
local function get_run_command()
    local fi = utils.get_current_file_info()
    local lang = languages[fi.type]

    if not lang or not lang.runner then
        vim.notify(
            ("No runner configured for filetype: %s"):format(fi.type or "unknown"),
            vim.log.levels.WARN
        )
        return nil
    end

    return lang.runner(fi.fullpath, fi.basename)
end

--- Adds the code snippet to a temp file and returns the command needed to run this temp file
---@return string | nil
local function get_code_snippet_run_command()
    local ft = vim.bo.filetype
    local runner = languages[ft].runner
    local tempfile_path = vim.fn.getcwd()
        .. "/"
        .. tempfile_name
        .. "."
        .. languages[ft].extensions[1]

    -- Get highlighted selection
    local selection = utils.get_visual_selection()
    if not selection or selection == "" then
        vim.notify("No text selected.", vim.log.levels.WARN)
        return nil
    end
    -- Write selection to file
    local file, err = io.open(tempfile_path, "w")
    if not file then
        vim.notify("Failed to create temp file: " .. err, vim.log.levels.ERROR)
        return nil
    end

    -- Verify that the language has headers defined
    if languages[ft].headers then
        for _, header in pairs(languages[ft].headers) do
            -- If the header is not already in the selection, add it to the top of the file
            if not selection:find(header, 1, true) then
                file:write(header .. "\n")
            end
        end
    end

    file:write(selection)
    file:close()
    -- Get command to run temp file
    return runner and runner(tempfile_path, tempfile_name)
end

--- Deletes any temp files generated to run the code snippets
local function delete_temp_files()
    local cwd = vim.fn.getcwd()

    for name, type in vim.fs.dir(cwd) do
        -- only delete regular files
        if type == "file" and name:find(tempfile_name, 1, true) then
            local path = cwd .. "/" .. name
            local ok, err = os.remove(path)
            if not ok then
                vim.notify(
                    "Failed to delete file: " .. path .. " (" .. tostring(err) .. ")",
                    vim.log.levels.WARN
                )
            end
        end
    end
end

--- Takes a command string and runs the command in a terminal in a spilt
---@param run_cmd string Command to run
---@param on_exit function A function to call upon exit
local function run(run_cmd, on_exit)
    local pos = config.terminal_position or "bottom"
    local footprint = config.terminal_footprint or 0.33

    if not run_cmd then
        vim.notify("No run command found for this filetype", vim.log.levels.WARN)
        return
    end

    local file_dir = vim.fn.expand("%:p:h")

    if pos == "floating" then
        local curr_win = vim.api.nvim_get_current_win()
        local win_width = vim.api.nvim_win_get_width(curr_win)
        local win_height = vim.api.nvim_win_get_height(curr_win)

        local width = math.ceil(win_width * 0.8)
        local height = math.ceil(win_height * 0.7)
        local row = math.ceil((win_height - height) / 2)
        local col = math.ceil((win_width - width) / 2)

        local buf = vim.api.nvim_create_buf(false, true)
        local win = vim.api.nvim_open_win(buf, true, {
            relative = "win",
            win = curr_win,
            width = width,
            height = height,
            row = row,
            col = col,
            style = "minimal",
            border = "rounded",
        })
        vim.api.nvim_set_option_value("winhl", "Normal:Normal,FloatBorder:Normal", { win = win })
    else
        local parent_width = vim.api.nvim_win_get_width(0)
        local parent_height = vim.api.nvim_win_get_height(0)

        local commands = {
            bottom = "split",
            top = "leftabove split",
            left = "leftabove vsplit",
            right = "vsplit",
        }

        vim.cmd(commands[pos] or "split")

        if pos == "left" or pos == "right" then
            local target_width = math.ceil(parent_width * footprint)
            vim.cmd("vertical resize " .. target_width)
        else
            local target_height = math.ceil(parent_height * footprint)
            vim.cmd("resize " .. target_height)
        end
        vim.cmd("enew")
    end

    vim.fn.termopen(run_cmd, {
        cwd = file_dir,
        on_exit = function(_, exit_code, _)
            vim.notify("Process exited with code: " .. exit_code, vim.log.levels.INFO)
            if on_exit then
                on_exit()
            end
        end,
    })
    vim.cmd("startinsert")
end

local M = {}

M.run_current_file = function()
    local run_cmd = get_run_command()
    if run_cmd then
        run(run_cmd, function() end)
    end
end

M.run_code_snippet = function()
    local run_cmd = get_code_snippet_run_command()
    if run_cmd then
        run(run_cmd, function()
            delete_temp_files()
        end)
    end
end

return M
