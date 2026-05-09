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
---		Path to file
---		File name (ex. file.cpp)
---		File name without extension (ex. file)
---		File language
M.get_current_file_info = function()
    return {
        fullpath = vim.fn.expand("%:p"),
        filename = vim.fn.expand("%:t"),
        basename = vim.fn.expand("%:t:r"),
        type = vim.bo.filetype,
    }
end

return M
