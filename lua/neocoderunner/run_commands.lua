local utils = require("neocoderunner.utils")
local languages = require("neocoderunner.languages")

local tempfile_name = "neocoderunner_tempfile"


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
local function get_code_snippet_run_command()
	local ft = vim.bo.filetype
	local runner = languages[ft].runner
	local tempfile_path = vim.fn.getcwd() .. "/" .. tempfile_name .. "." .. languages[ft].extensions[1]

	-- Get highlighted selection
	local selection = utils.get_visual_selection()
	if not selection or selection == "" then
		vim.notify("No text selected.", vim.log.levels.WARN)
		return
	end
	-- Write selection to file
	local file, err = io.open(tempfile_path, "w")
	if not file then
		vim.notify("Failed to create temp file: " .. err, vim.log.levels.ERROR)
		return
	end
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
				vim.notify("Failed to delete file: " .. path .. " (" .. tostring(err) .. ")", vim.log.levels.WARN)
			end
		end
	end
end


local function run(run_cmd)

    if not run_cmd then
        vim.notify("No run command found for this filetype", vim.log.levels.WARN)
        return
    end

    -- Open a horizontal split with a new empty buffer
    vim.cmd("split | enew")

    -- Optional: set the terminal window height
    vim.cmd("resize 15")

    -- Open terminal and run the command
    vim.fn.termopen(run_cmd, {
        on_exit = function(_, exit_code, _)
            vim.notify("Process exited with code: " .. exit_code, vim.log.levels.INFO)
        end,
    })

    -- Immediately enter insert mode so the terminal is interactive
    vim.cmd("startinsert")
end


local M = {}

M.run_current_file = function()
	local run_cmd = get_run_command()
	run(run_cmd)
end

M.run_code_snippet = function()
	local run_cmd = get_code_snippet_run_command()
	run(run_cmd)
	delete_temp_files()
end

return M
