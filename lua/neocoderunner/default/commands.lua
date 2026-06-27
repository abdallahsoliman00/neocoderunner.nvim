local languages = require("neocoderunner.default.languages")
local utils = require("neocoderunner.utils")

local tempfile_name = "neocoderunner_tempfile"

local M = {}

--- Gets the run command for the current file
---@return string | nil
M.get_run_command = function()
    local fi = M.get_current_file_info()
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
M.get_code_snippet_run_command = function()
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
M.delete_temp_files = function()
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

return M
