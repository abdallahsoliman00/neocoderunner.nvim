require("neocoderunner.types.Runner")

local languages = require("neocoderunner.default.languages")
local utils = require("neocoderunner.utils")

local tempfile_name = "neocoderunner_tempfile"
local temp_root = vim.fn.stdpath("cache") .. "/neocoderunner"

---@type table<string, boolean>
local pending_tempdirs = {}

local tempdir_counter = 0

--- Recursively deletes a temp directory
---@param dir string
---@return boolean success
local function remove_dir(dir)
    return vim.fn.delete(dir, "rf") == 0
end

--- Creates a unique temp directory for a snippet run and tracks it for cleanup
---@return string
local function make_tempdir()
    -- Unique across concurrent Neovim instances (pid) and within one session (counter)
    tempdir_counter = tempdir_counter + 1
    local dir = ("%s/%d-%d"):format(temp_root, vim.fn.getpid(), tempdir_counter)
    vim.fn.mkdir(dir, "p")
    pending_tempdirs[dir] = true
    return dir
end

---@param dir string
---@param lang Language
---@return string
local function get_tempfile_path(dir, lang)
    return dir .. "/" .. tempfile_name .. "." .. lang.extensions[1]
end

-- Reclaim orphaned temp directories from previous (crashed) sessions.
-- Very recent directories are skipped since another running instance may be using them.
if vim.uv.fs_stat(temp_root) then
    local now = os.time()
    for name, type in vim.fs.dir(temp_root) do
        local path = temp_root .. "/" .. name
        local stat = type == "directory" and vim.uv.fs_stat(path)
        if stat and now - stat.mtime.sec > 60 then
            remove_dir(path)
        end
    end
end

-- Fallback cleanup for snippet runs whose job never exited
local cleanup_group = vim.api.nvim_create_augroup("NeoCodeRunnerTempCleanup", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", {
    group = cleanup_group,
    callback = function()
        for dir, _ in pairs(pending_tempdirs) do
            remove_dir(dir)
        end
    end,
})

local M = {}

--- Gets the default run command for the current file
---@return Runner | nil
M.get_run_command = function()
    local file_info = utils.get_current_file_info()
    local lang = languages[file_info.type]

    if not lang or not lang.runner then
        vim.notify(
            ("No runner configured for filetype: %s"):format(file_info.type or "unknown"),
            vim.log.levels.WARN
        )
        return nil
    end

    local config = require("neocoderunner").config
    if config.default_runners ~= nil and config.default_runners[file_info.type] ~= nil then
        return utils.normalise_runner(config.default_runners[file_info.type])
    end

    return utils.normalise_runner(lang.runner(file_info.fullpath, file_info.basename))
end

--- Adds the code snippet to a temp file and returns the command needed to run this temp file
---@return string | nil cmd
---@return string | nil tempdir Directory the command must run from, deleted after the run
M.get_code_snippet_run_command = function()
    ---@type string
    local ft = vim.bo.filetype
    local lang = languages[ft]
    if not lang or not lang.runner then
        vim.notify(
            ("No runner configured for filetype: %s"):format(ft or "unknown"),
            vim.log.levels.WARN
        )
        return nil
    end
    local runner = lang.runner

    -- Get highlighted selection
    local selection = utils.get_visual_selection()
    if not selection or selection == "" then
        vim.notify("No text selected.", vim.log.levels.WARN)
        return nil
    end

    local tempdir = make_tempdir()
    local tempfile_path = get_tempfile_path(tempdir, lang)

    -- Write selection to file
    local file, err = io.open(tempfile_path, "w")
    if not file then
        remove_dir(tempdir)
        pending_tempdirs[tempdir] = nil
        vim.notify("Failed to create temp file: " .. err, vim.log.levels.ERROR)
        return nil
    end

    -- Verify that the language has headers defined
    -- TODO: Could similar logic be used to include required modules for a copied snippet?
    if lang.headers then
        for _, header in pairs(lang.headers) do
            -- If the header is not already in the selection, add it to the top of the file
            if not selection:find(header, 1, true) then
                file:write(header .. "\n")
            end
        end
    end

    file:write(selection)
    file:close()
    -- Get command to run temp file
    return runner(tempfile_path, tempfile_name), tempdir
end

--- Deletes the temp directory used by a single snippet run
---@param dir string
M.delete_temp_dir = function(dir)
    if remove_dir(dir) then
        pending_tempdirs[dir] = nil
    else
        vim.notify("Failed to delete temp directory: " .. dir, vim.log.levels.WARN)
    end
end

return M
