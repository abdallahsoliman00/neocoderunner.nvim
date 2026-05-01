local M = {}

M.get_visual_selection = function()
	-- Save the current register content
	local saved_reg = vim.fn.getreg("v")
	-- Yank the visual selection into register 'v'
	vim.cmd('noau normal! "vy"')
	-- Retrieve the yanked text
	local selection = vim.fn.getreg("v")
	-- Restore the register
	vim.fn.setreg("v", saved_reg)
	return selection
end

--- Returns a table with properties of the current file:
---		Path to file
---		File name (ex. file.cpp)
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
