local config = require("neocoderunner").config
local sep = vim.o.shell:lower():find("powershell") and " ; " or " && "


---@param run_cmd string
---@param cwd string
local function build_display_cmd(run_cmd, cwd)
    if vim.fn.has("win32") == 1 then
        local shell = vim.o.shell:lower()

        if shell:find("powershell") or shell:find("pwsh") then
            -- PowerShell
            return string.format(
                "Write-Output '> cd %s'; Write-Output '> %s'; Write-Output ''; %s",
                cwd:gsub("'", "''"), run_cmd:gsub("'", "''"), run_cmd
            )
        else
            -- cmd.exe
            return string.format(
                "echo > cd %s & echo > %s & echo '' & %s",
                cwd, run_cmd, run_cmd
            )
        end
    else
        -- POSIX shell (Linux, macOS)
        local escaped_cwd = cwd:gsub("'", "'\\''")
        local escaped_cmd = run_cmd:gsub("'", "'\\''")
        return string.format(
            "echo '> cd %s'; echo '> %s'; echo ''; %s",
            escaped_cwd, escaped_cmd, run_cmd
        )
    end
end

--- Determines which shell dialect we're dealing with, based on
--- Neovim's 'shell' option and the OS.
---@return "cmd" | "powershell" | "posix"
local function get_shell_type()
    if vim.fn.has("win32") == 1 then
        local shell = (vim.o.shell or ""):lower()
        if shell:find("powershell") or shell:find("pwsh") then
            return "powershell"
        end
        return "cmd"
    end
    return "posix"
end

--- Builds a single "export"/"set" statement for one variable,
--- using the correct syntax for the detected shell.
---@param key string
---@param value string
---@return string
local function build_export_stmt(key, value)
    local shell_type = get_shell_type()
    if shell_type == "cmd" then
        -- cmd.exe: set "VAR=value"
        return string.format('set "%s=%s"', key, value)
    elseif shell_type == "powershell" then
        -- PowerShell: $env:VAR="value"
        return string.format('$env:%s="%s"', key, value)
    else
        -- POSIX shells: export VAR=value
        return string.format("export %s=%s", key, vim.fn.shellescape(tostring(value)))
    end
end

--- Builds the final command string by prepending exported variables
--- and script invocations before the actual run command.
---@param run_cmd string Command to run
---@param export table<string,string>|nil Variables to export, e.g. { PATH = "/usr/bin", DEBUG = "1" }
---@param scripts string[]|nil List of script commands to run first,
---        e.g. { "source ./relative/path/to/script", "/path/to/script" }
---@return string
local function build_prefixed_cmd(run_cmd, export, scripts)
    local parts = {}

    -- Export variables first
    if export and not vim.tbl_isempty(export) then
        for key, value in pairs(export) do
            table.insert(parts, build_export_stmt(key, value))
        end
    end

    -- Run/source any scripts, in the order provided
    if scripts and #scripts > 0 then
        for _, script in ipairs(scripts) do
            table.insert(parts, script)
        end
    end

    table.insert(parts, run_cmd)

    return table.concat(parts, sep)
end


local M = {}

M.get_visual_selection = function()
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_line, start_col = start_pos[2], start_pos[3]
    local end_line, end_col = end_pos[2], end_pos[3]

    local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
    if #lines == 0 then
        return ""
    end

    -- Trim to the exact column range
    lines[#lines] = lines[#lines]:sub(1, end_col)
    lines[1] = lines[1]:sub(start_col)

    return table.concat(lines, "\n")
end

--- Returns a table with properties of the current file:
---		.fullpath: Absolute path to file
---		.filename: File name (eg. file.cpp)
---		.basename: File name without extension (ex. file)
---		.relative: Filepath relative to cwd
---		.type:     File type (e.g. cpp, python, etc...)
---@return table<string>
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
---@param cwd string | nil Path to the directory to run from
---@param on_exit function A function to call upon exit
---@param export table<string,string>|nil Variables to export before running, e.g. { VAR = "value" }
---@param scripts string[]|nil Scripts to run/source before run_cmd, e.g. { "source ./relative/path/to/script", "script/name" }
M.run = function(run_cmd, cwd, on_exit, export, scripts)
    on_exit = on_exit or function() end
    -- Default directory is the directory of the file being run
    cwd = cwd or vim.fn.expand("%:p:h")

    -- Make sure the path is valid and create it if it doesn't exist
    if cwd and cwd ~= "" then
        local stat = vim.loop.fs_stat(cwd)
        if not stat then
            vim.fn.mkdir(cwd, "p")
        elseif stat.type ~= "directory" then
            vim.notify("Path exists but is not a directory: " .. cwd, vim.log.levels.ERROR)
            return
        end
    end

    local pos = config.terminal_position or "bottom"
    local footprint = config.terminal_footprint or 0.33

    if not run_cmd then
        vim.notify("No run command found for this filetype", vim.log.levels.WARN)
        return
    end

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

    local prefixed_cmd = build_prefixed_cmd(run_cmd, export, scripts)
    local display_cmd = build_display_cmd(prefixed_cmd, cwd)

    vim.fn.termopen(display_cmd, {
        cwd = cwd,
        on_exit = function(_, exit_code, _)
            vim.notify("Process exited with code: " .. exit_code, vim.log.levels.INFO)
            on_exit()
        end,
    })
    vim.cmd("startinsert")
end

--- Returns true if the runners.json file exists in the cwd
---@return boolean
M.runners_file_exists = function()
    local cwd = vim.fn.getcwd()
    local runners_path = cwd .. "/.ncrunner/runners.json"
    if vim.uv.fs_stat(runners_path) then
        return true
    end
    return false
end

--- Resolves the placeholders and returns the actual command to be run
--- The replacements should be passed in as a table e.g. { name = "name", date = "Sunday" }
--- This replaces anything of the form ${placeholder} with the assigned replacement
---@param command string|table<string>
---@param replacements table<string, string>
---@return string|table<string>
M.resolve_placeholders = function(command, replacements)
    local function resolve_single(cmd)
        return (cmd:gsub("%${([%w_]+)}", replacements))
    end

    if type(command) == "table" then
        local results = {}
        for _, cmd in ipairs(command) do
            table.insert(results, resolve_single(cmd))
        end
        return results
    end

    return resolve_single(command)
end

--- Normalises a raw runner entry (string or table) into a Runner
---@param raw table|string
---@return Runner
M.normalise_runner = function(raw)
    local fileinfo = require("neocoderunner.utils").get_current_file_info()
    local replacements = { fileName = fileinfo.basename, filePath = fileinfo.relative }

    if type(raw) == "string" then
        return { build = nil, run = M.resolve_placeholders(raw, replacements) }
    end
    return { build = M.resolve_placeholders(raw.build, replacements), run = M.resolve_placeholders(raw.run, replacements) }
end

return M
