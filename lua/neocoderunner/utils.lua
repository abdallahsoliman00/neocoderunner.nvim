local config = require("neocoderunner").config

local M = {}

M.get_visual_selection = function()
    local start_pos = vim.fn.getpos("'<")
    local end_pos   = vim.fn.getpos("'>")

    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line,   end_col   = end_pos[2],   end_pos[3]

    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    if #lines == 0 then return "" end

    -- Trim to the exact column range
    lines[#lines] = lines[#lines]:sub(1, end_col)
    lines[1]      = lines[1]:sub(start_col)

    return table.concat(lines, "\n")
end

--- Returns a table with properties of the current file:
---		.fullpath: Path to file
---		.filename: File name (eg. file.cpp)
---		.basename: File name without extension (ex. file)
---		.relative: Filepath relative to cwd
---		.type:     File type (e.g. cpp, py, etc...)
M.get_current_file_info = function()
    return {
        fullpath = vim.fn.expand("%:p"),
        filename = vim.fn.expand("%:t"),
        basename = vim.fn.expand("%:t:r"),
        relative = vim.fn.expand("%:."),
        type = vim.bo.filetype,
    }
end

--- Takes a command string and runs the command in a terminal in a spilt
---@param run_cmd string Command to run
---@param on_exit function A function to call upon exit
M.run = function(run_cmd, on_exit)
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
            bottom = "rightbelow split",
            top = "leftabove split",
            left = "leftabove vsplit",
            right = "rightbelow vsplit",
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

--- Returns true if the runners.json file exists in the cwd
---@return boolean
M.runners_file_exists = function()
    local cwd = vim.cmd("pwd")
    local runners_path = cwd .. "/.ncrunner/runners.json"
    if vim.uv.fs_stat(runners_path) then
        return true
    end
    return false
end

return M
